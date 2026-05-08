-- Create improved candidate applications table
CREATE TABLE candidato_aplicacoes_banco_talentos_execut (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    
    -- Job relationship
    vaga_id UUID REFERENCES vagas_banco_talentos_execut(id),
    
    -- Candidate information
    nome_completo VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL,
    telefone VARCHAR(20),
    linkedin_url VARCHAR(500),
    
    -- Application-specific information
    pretensao_salarial DECIMAL(12,2),
    experiencia_anos INTEGER DEFAULT 0,
    
    -- Qualitative responses
    motivacao TEXT,
    maior_qualidade TEXT,
    habilidade_melhorar TEXT,
    desafio_resolvido TEXT,
    
    -- Portfolio/CV information
    tipo_curriculo VARCHAR(50), -- 'arquivo' or 'link'
    curriculo_url VARCHAR(1000),
    curriculo_arquivo_path VARCHAR(1000),
    
    -- Portfolio information (for specific roles)
    tipo_portfolio VARCHAR(50), -- 'arquivo' or 'link'
    portfolio_url VARCHAR(1000),
    portfolio_arquivo_path VARCHAR(1000),
    
    -- Application status
    status VARCHAR(50) DEFAULT 'Novo Currículo', -- Novo Currículo, Em Análise, Entrevista, Teste, Aprovado, Reprovado
    alocacao VARCHAR(255),
    cliente_alocado VARCHAR(255),
    
    -- Score and evaluation
    pontuacao_total INTEGER DEFAULT 0,
    avaliacao_ia JSONB, -- AI assessment of the candidate
    
    -- Metadata
    ip_address INET,
    user_agent TEXT,
    data_aplicacao TIMESTAMPTZ DEFAULT now(),
    data_atualizacao TIMESTAMPTZ DEFAULT now()
);

-- Create unique constraint for email+job to prevent duplicate applications
CREATE UNIQUE INDEX idx_candidato_unique_vaga_email ON candidato_aplicacoes_banco_talentos_execut(vaga_id, email);

-- Create indexes
CREATE INDEX idx_candidato_vaga ON candidato_aplicacoes_banco_talentos_execut(vaga_id);
CREATE INDEX idx_candidato_email ON candidato_aplicacoes_banco_talentos_execut(email);
CREATE INDEX idx_candidato_status ON candidato_aplicacoes_banco_talentos_execut(status);
CREATE INDEX idx_candidato_data ON candidato_aplicacoes_banco_talentos_execut(data_aplicacao);

-- Add RLS policies
ALTER TABLE candidato_aplicacoes_banco_talentos_execut ENABLE ROW LEVEL SECURITY;;
