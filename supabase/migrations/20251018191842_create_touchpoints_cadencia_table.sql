-- Migração: Criar tabela normalizada para touchpoints das cadências
-- Esta tabela armazena cada touchpoint como um registro separado para melhor performance e manutenibilidade

-- 1. Criar nova tabela para touchpoints
CREATE TABLE IF NOT EXISTS touchpoints_cadencia_rastreia_prospect (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    cadencia_id UUID NOT NULL REFERENCES cadencias_rastreia_prospect(id) ON DELETE CASCADE,
    dia INTEGER NOT NULL CHECK (dia > 0 AND dia <= 30),
    tipo VARCHAR(50) NOT NULL CHECK (tipo IN ('whatsapp', 'ligacao', 'linkedin', 'email')),
    descricao TEXT,
    ordem INTEGER DEFAULT 1,
    rede_social VARCHAR(100), -- Para especificar LinkedIn, Instagram, etc.
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Criar índices para performance
CREATE INDEX IF NOT EXISTS idx_touchpoints_cadencia_id ON touchpoints_cadencia_rastreia_prospect(cadencia_id);
CREATE INDEX IF NOT EXISTS idx_touchpoints_dia ON touchpoints_cadencia_rastreia_prospect(cadencia_id, dia);
CREATE INDEX IF NOT EXISTS idx_touchpoints_tipo ON touchpoints_cadencia_rastreia_prospect(tipo);

-- 3. Adicionar coluna duracao_dias na tabela cadencias (se não existir)
ALTER TABLE cadencias_rastreia_prospect
ADD COLUMN IF NOT EXISTS duracao_dias INTEGER NOT NULL DEFAULT 5;

-- 4. Criar políticas RLS para a nova tabela
ALTER TABLE touchpoints_cadencia_rastreia_prospect ENABLE ROW LEVEL SECURITY;

-- Política para usuários autenticados verem todos os touchpoints
CREATE POLICY "Touchpoints visíveis para usuários autenticados" ON touchpoints_cadencia_rastreia_prospect
    FOR SELECT USING (auth.role() = 'authenticated'::text);

-- Política para usuários autenticados gerenciarem touchpoints
CREATE POLICY "Touchpoints podem ser gerenciados por usuários autenticados" ON touchpoints_cadencia_rastreia_prospect
    FOR ALL USING (auth.role() = 'authenticated'::text)
    WITH CHECK (auth.role() = 'authenticated'::text);

-- 5. Função para atualizar updated_at automaticamente
CREATE OR REPLACE FUNCTION update_touchpoints_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger para atualizar updated_at
CREATE TRIGGER trigger_touchpoints_updated_at
    BEFORE UPDATE ON touchpoints_cadencia_rastreia_prospect
    FOR EACH ROW
    EXECUTE FUNCTION update_touchpoints_updated_at();

-- 6. Comentários para documentação
COMMENT ON TABLE touchpoints_cadencia_rastreia_prospect IS 'Touchpoints individuais das cadências - estrutura normalizada';
COMMENT ON COLUMN touchpoints_cadencia_rastreia_prospect.cadencia_id IS 'Referência para a cadência mestre';
COMMENT ON COLUMN touchpoints_cadencia_rastreia_prospect.dia IS 'Dia da cadência em que o touchpoint deve ser executado';
COMMENT ON COLUMN touchpoints_cadencia_rastreia_prospect.tipo IS 'Tipo de touchpoint: whatsapp, ligacao, linkedin, email';
COMMENT ON COLUMN touchpoints_cadencia_rastreia_prospect.ordem IS 'Ordem de execução dentro do mesmo dia';
COMMENT ON COLUMN touchpoints_cadencia_rastreia_prospect.rede_social IS 'Rede social específica para social selling';;
