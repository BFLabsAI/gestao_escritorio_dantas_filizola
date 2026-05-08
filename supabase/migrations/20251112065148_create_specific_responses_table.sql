-- Create specific responses table
CREATE TABLE respostas_especificas_banco_talentos_execut (
    id SERIAL PRIMARY KEY,
    candidato_id UUID REFERENCES candidatos_banco_talentos_execut(id) ON DELETE CASCADE,
    pergunta_texto TEXT NOT NULL,
    resposta_texto TEXT,
    resposta_array TEXT[],
    resposta_arquivo_url TEXT,
    tipo_resposta TEXT CHECK (tipo_resposta IN ('text', 'array', 'file', 'link')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for performance
CREATE INDEX idx_respostas_candidato_id ON respostas_especificas_banco_talentos_execut(candidato_id);
CREATE INDEX idx_respostas_tipo ON respostas_especificas_banco_talentos_execut(tipo_resposta);;
