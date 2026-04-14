-- =============================================
-- Migration: Sistema de Petições
-- =============================================

-- 1. Criar tabela de petições geradas
CREATE TABLE IF NOT EXISTS public.peticoes_geradas_gestao_escritorio_filizola (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    processo_id UUID REFERENCES public.processos_gestao_escritorio_filizola(id) ON DELETE CASCADE,
    cliente_id UUID REFERENCES public.clientes_gestao_escritorio_filizola(id) ON DELETE CASCADE,
    modelo_id UUID REFERENCES public.modelos_dantas_filizola(id),
    tipo_beneficio TEXT NOT NULL,
    conteudo_gerado TEXT,
    variaveis_usadas JSONB DEFAULT '{}',
    storage_path TEXT UNIQUE,
    status_geracao TEXT DEFAULT 'pendente' CHECK (status_geracao IN ('pendente', 'concluido', 'erro')),
    criado_em TIMESTAMPTZ DEFAULT NOW(),
    criado_por UUID REFERENCES public.perfis_gestao_escritorio_filizola(id)
);

CREATE INDEX IF NOT EXISTS idx_peticoes_geradas_processo
    ON public.peticoes_geradas_gestao_escritorio_filizola(processo_id);

CREATE INDEX IF NOT EXISTS idx_peticoes_geradas_cliente
    ON public.peticoes_geradas_gestao_escritorio_filizola(cliente_id);

-- 2. Adicionar colunas na tabela de modelos existente
ALTER TABLE public.modelos_dantas_filizola
    ADD COLUMN IF NOT EXISTS tipo_beneficio TEXT,
    ADD COLUMN IF NOT EXISTS ativo BOOLEAN DEFAULT true,
    ADD COLUMN IF NOT EXISTS ordem_exibicao INTEGER DEFAULT 0;

-- 3. Garantir que só exista um template ativo por tipo de benefício na categoria peticoes
DO $$
BEGIN
    ALTER TABLE public.modelos_dantas_filizola
        ADD CONSTRAINT modelos_peticoes_tipo_beneficio_unique
        EXCLUDE (tipo_beneficio WITH =) WHERE (categoria = 'peticoes'::public.categoria_modelo_dantas_filizola AND ativo = true);
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;
