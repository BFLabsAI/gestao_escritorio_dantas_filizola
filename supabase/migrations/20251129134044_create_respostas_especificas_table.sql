-- Create table for specific question responses
CREATE TABLE respostas_especificas_vagas_banco_talentos_execut (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    
    -- Relationships
    aplicacao_id UUID REFERENCES candidato_aplicacoes_banco_talentos_execut(id) ON DELETE CASCADE,
    pergunta_id UUID REFERENCES perguntas_vagas_banco_talentos_execut(id) ON DELETE CASCADE,
    
    -- Response content
    resposta_texto TEXT,
    resposta_array TEXT[], -- For checkbox responses
    resposta_arquivo_url VARCHAR(1000), -- For file uploads
    resposta_valor DECIMAL(12,2), -- For monetary responses
    
    -- Metadata
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- Create indexes
CREATE INDEX idx_respostas_aplicacao ON respostas_especificas_vagas_banco_talentos_execut(aplicacao_id);
CREATE INDEX idx_respostas_pergunta ON respostas_especificas_vagas_banco_talentos_execut(pergunta_id);
CREATE UNIQUE INDEX idx_respostas_unique ON respostas_especificas_vagas_banco_talentos_execut(aplicacao_id, pergunta_id);

-- Add RLS policies
ALTER TABLE respostas_especificas_vagas_banco_talentos_execut ENABLE ROW LEVEL SECURITY;;
