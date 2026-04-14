-- ============================================
-- Dados Extraídos + Template Texto para Petições
-- ============================================

-- Tabela de dados extraídos por IA dos documentos
CREATE TABLE dados_extraidos_gestao_escritorio_filizola (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    processo_id UUID NOT NULL REFERENCES processos_gestao_escritorio_filizola(id) ON DELETE CASCADE,
    cliente_id UUID NOT NULL REFERENCES clientes_gestao_escritorio_filizola(id) ON DELETE CASCADE,
    documento_origem_id UUID REFERENCES documentos_gestao_escritorio_filizola(id) ON DELETE SET NULL,
    tipo_documento_origem TEXT NOT NULL,
    campo TEXT NOT NULL,
    valor TEXT NOT NULL,
    confianca NUMERIC(3,2),
    status TEXT DEFAULT 'extraido' CHECK (status IN ('extraido', 'confirmado', 'corrigido')),
    criado_em TIMESTAMPTZ DEFAULT NOW(),
    atualizado_em TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_dados_extraidos_processo ON dados_extraidos_gestao_escritorio_filizola(processo_id);
CREATE INDEX idx_dados_extraidos_cliente ON dados_extraidos_gestao_escritorio_filizola(cliente_id);
CREATE INDEX idx_dados_extraidos_campo ON dados_extraidos_gestao_escritorio_filizola(campo);
CREATE INDEX idx_dados_extraidos_documento_origem ON dados_extraidos_gestao_escritorio_filizola(documento_origem_id);

-- Trigger para atualizar atualizado_em
CREATE OR REPLACE FUNCTION update_dados_extraidos_atualizado_em()
RETURNS TRIGGER AS $$
BEGIN
    NEW.atualizado_em = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_dados_extraidos_atualizado_em
    BEFORE UPDATE ON dados_extraidos_gestao_escritorio_filizola
    FOR EACH ROW EXECUTE FUNCTION update_dados_extraidos_atualizado_em();

-- Coluna conteudo_template na tabela de modelos (texto direto em vez de arquivo)
ALTER TABLE modelos_dantas_filizola
ADD COLUMN IF NOT EXISTS conteudo_template TEXT;

-- RLS
ALTER TABLE dados_extraidos_gestao_escritorio_filizola ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Usuários autenticados podem ver dados extraídos"
    ON dados_extraidos_gestao_escritorio_filizola
    FOR SELECT TO authenticated
    USING (true);

CREATE POLICY "Usuários autenticados podem inserir dados extraídos"
    ON dados_extraidos_gestao_escritorio_filizola
    FOR INSERT TO authenticated
    WITH CHECK (true);

CREATE POLICY "Usuários autenticados podem atualizar dados extraídos"
    ON dados_extraidos_gestao_escritorio_filizola
    FOR UPDATE TO authenticated
    USING (true)
    WITH CHECK (true);

CREATE POLICY "Usuários autenticados podem deletar dados extraídos"
    ON dados_extraidos_gestao_escritorio_filizola
    FOR DELETE TO authenticated
    USING (true);
