-- ============================================
-- Refatoração: dados_extraidos para JSONB + cliente_id em documentos
-- ============================================

-- 1. Adicionar coluna dados_extraidos JSONB na tabela de processos
ALTER TABLE public.processos_gestao_escritorio_filizola
ADD COLUMN IF NOT EXISTS dados_extraidos JSONB DEFAULT '{}'::jsonb;

-- 2. Índice GIN para consultas JSONB
CREATE INDEX IF NOT EXISTS idx_processos_dados_extraidos_gin
ON public.processos_gestao_escritorio_filizola USING GIN (dados_extraidos);

-- 3. Adicionar coluna cliente_id na tabela de documentos
ALTER TABLE public.documentos_gestao_escritorio_filizola
ADD COLUMN IF NOT EXISTS cliente_id UUID REFERENCES public.clientes_gestao_escritorio_filizola(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_documentos_cliente
ON public.documentos_gestao_escritorio_filizola(cliente_id);

-- 4. Migrar cliente_id existente nos documentos (via processo -> cliente)
UPDATE public.documentos_gestao_escritorio_filizola d
SET cliente_id = p.cliente_id
FROM public.processos_gestao_escritorio_filizola p
WHERE d.processo_id = p.id
  AND d.cliente_id IS NULL;

-- 5. Migrar dados existentes da tabela dados_extraidos para JSONB
CREATE OR REPLACE FUNCTION migrate_dados_extraidos_to_jsonb()
RETURNS VOID AS $$
DECLARE
    processo_rec RECORD;
    dados_json JSONB;
BEGIN
    FOR processo_rec IN
        SELECT DISTINCT processo_id
        FROM dados_extraidos_gestao_escritorio_filizola
    LOOP
        -- Para cada campo, pegar o registro com maior confianca ou status corrigido
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

        UPDATE public.processos_gestao_escritorio_filizola
        SET dados_extraidos = COALESCE(dados_json, '{}'::jsonb)
        WHERE id = processo_rec.processo_id;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

SELECT migrate_dados_extraidos_to_jsonb();

DROP FUNCTION IF EXISTS migrate_dados_extraidos_to_jsonb();

-- 6. Nova RPC para upsert de dados extraidos (merge JSONB)
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
    -- Buscar dados existentes
    SELECT dados_extraidos INTO existing_dados
    FROM public.processos_gestao_escritorio_filizola
    WHERE id = p_processo_id;

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

    UPDATE public.processos_gestao_escritorio_filizola
    SET dados_extraidos = merged_dados
    WHERE id = p_processo_id;

    RETURN json_build_object('success', true);
EXCEPTION WHEN OTHERS THEN
    RETURN json_build_object('success', false, 'error', SQLERRM);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 7. Manter tabela antiga como backup (comentar após validação)
-- A tabela dados_extraidos_gestao_escritorio_filizola NÃO será dropada.
-- Ela serve como backup e pode ser usada para rollback.
