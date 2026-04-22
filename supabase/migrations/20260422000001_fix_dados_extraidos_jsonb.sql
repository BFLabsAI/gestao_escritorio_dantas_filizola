-- ============================================
-- Correção: JSONB na tabela dados_extraidos (não em processos)
-- ============================================

-- 1. Adicionar coluna dados JSONB na tabela dados_extraidos
ALTER TABLE public.dados_extraidos_gestao_escritorio_filizola
ADD COLUMN IF NOT EXISTS dados JSONB DEFAULT '{}'::jsonb;

-- 2. Migrar dados existentes: agregar linhas por processo_id no JSONB
CREATE OR REPLACE FUNCTION migrate_rows_to_jsonb()
RETURNS VOID AS $$
DECLARE
    processo_rec RECORD;
    dados_json JSONB;
    row_to_keep_id UUID;
BEGIN
    FOR processo_rec IN
        SELECT DISTINCT processo_id
        FROM dados_extraidos_gestao_escritorio_filizola
    LOOP
        -- Agregar campos em JSONB (melhor confiança ou status corrigido)
        SELECT jsonb_object_agg(
            campo,
            jsonb_build_object(
                'valor', valor,
                'confianca', confianca,
                'status', status,
                'documento_origem_id', documento_origem_id,
                'tipo_documento_origem', tipo_documento_origem,
                'criado_em', criado_em
            )
        ) INTO dados_json
        FROM (
            SELECT DISTINCT ON (campo)
                campo, valor, confianca, status,
                documento_origem_id, tipo_documento_origem, criado_em
            FROM dados_extraidos_gestao_escritorio_filizola
            WHERE processo_id = processo_rec.processo_id
            ORDER BY campo,
                CASE WHEN status = 'corrigido' THEN 2
                     WHEN status = 'confirmado' THEN 1
                     ELSE 0
                END DESC,
                confianca DESC NULLS LAST
        ) sub;

        -- Se já tem dados em processos.dados_extraidos (migration anterior), usar como base
        DECLARE
            processo_dados JSONB;
        BEGIN
            SELECT dados_extraidos INTO processo_dados
            FROM public.processos_gestao_escritorio_filizola
            WHERE id = processo_rec.processo_id;

            IF processo_dados IS NOT NULL AND jsonb_typeof(processo_dados) = 'object' THEN
                -- Merge: dados do processo como base, sobrescreve com dados agregados
                dados_json = COALESCE(processo_dados, '{}'::jsonb) || COALESCE(dados_json, '{}'::jsonb);
            END IF;
        END;

        -- Pegar ID de uma linha existente para manter (a primeira)
        SELECT id INTO row_to_keep_id
        FROM dados_extraidos_gestao_escritorio_filizola
        WHERE processo_id = processo_rec.processo_id
        LIMIT 1;

        -- Atualizar essa linha com o JSONB agregado
        IF row_to_keep_id IS NOT NULL THEN
            UPDATE dados_extraidos_gestao_escritorio_filizola
            SET dados = COALESCE(dados_json, '{}'::jsonb)
            WHERE id = row_to_keep_id;

            -- Deletar as demais linhas desse processo
            DELETE FROM dados_extraidos_gestao_escritorio_filizola
            WHERE processo_id = processo_rec.processo_id
              AND id != row_to_keep_id;
        END IF;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

SELECT migrate_rows_to_jsonb();
DROP FUNCTION IF EXISTS migrate_rows_to_jsonb();

-- 3. Garantir que processo_id tenha uma linha para processos sem dados extraidos
-- (não necessário - será criado via upsert quando a IA extrair dados)

-- 4. Remover colunas antigas (agora redundantes pois estão dentro do JSONB)
ALTER TABLE public.dados_extraidos_gestao_escritorio_filizola
DROP COLUMN IF EXISTS campo,
DROP COLUMN IF EXISTS valor,
DROP COLUMN IF EXISTS confianca,
DROP COLUMN IF EXISTS status,
DROP COLUMN IF EXISTS documento_origem_id,
DROP COLUMN IF EXISTS tipo_documento_origem;

-- 5. Adicionar UNIQUE constraint em processo_id (1 linha por processo)
ALTER TABLE public.dados_extraidos_gestao_escritorio_filizola
ADD CONSTRAINT uq_dados_extraidos_processo_id UNIQUE (processo_id);

-- 6. Índice GIN para consultas JSONB
CREATE INDEX IF NOT EXISTS idx_dados_extraidos_dados_gin
ON public.dados_extraidos_gestao_escritorio_filizola USING GIN (dados);

-- 7. Remover coluna dados_extraidos da tabela processos (era o erro)
ALTER TABLE public.processos_gestao_escritorio_filizola
DROP COLUMN IF EXISTS dados_extraidos;

DROP INDEX IF EXISTS idx_processos_dados_extraidos_gin;

-- 8. Atualizar RPC para usar a tabela dados_extraidos_gestao_escritorio_filizola
CREATE OR REPLACE FUNCTION upsert_dados_extraidos_jsonb(
    p_processo_id UUID,
    p_cliente_id UUID,
    p_documento_origem_id UUID,
    p_tipo_documento_origem TEXT,
    p_dados JSONB
) RETURNS JSON AS $$
DECLARE
    existing_dados JSONB;
    merged_dados JSONB;
    campo TEXT;
BEGIN
    -- Buscar dados existentes na tabela dados_extraidos
    SELECT dados INTO existing_dados
    FROM public.dados_extraidos_gestao_escritorio_filizola
    WHERE processo_id = p_processo_id;

    -- Merge: novos dados sobrescrevem existentes
    merged_dados = COALESCE(existing_dados, '{}'::jsonb);

    -- Adicionar metadados a cada campo novo
    FOR campo IN SELECT jsonb_object_keys(p_dados)
    LOOP
        merged_dados = jsonb_set(
            merged_dados,
            ARRAY[campo],
            jsonb_build_object(
                'valor', p_dados->campo->>'valor',
                'confianca', (p_dados->campo->>'confianca')::NUMERIC(3,2),
                'status', COALESCE(p_dados->campo->>'status', 'extraido'),
                'documento_origem_id', p_documento_origem_id::TEXT,
                'tipo_documento_origem', p_tipo_documento_origem,
                'criado_em', NOW()::TEXT
            )
        );
    END LOOP;

    -- Upsert: inserir ou atualizar
    INSERT INTO public.dados_extraidos_gestao_escritorio_filizola
        (processo_id, cliente_id, dados)
    VALUES (p_processo_id, p_cliente_id, merged_dados)
    ON CONFLICT (processo_id)
    DO UPDATE SET
        dados = EXCLUDED.dados,
        atualizado_em = NOW();

    RETURN json_build_object('success', true);
EXCEPTION WHEN OTHERS THEN
    RETURN json_build_object('success', false, 'error', SQLERRM);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
