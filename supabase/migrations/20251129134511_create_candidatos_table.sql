-- Create candidatos table
DROP TABLE IF EXISTS candidatos_banco_talentos_execut CASCADE;

CREATE TABLE candidatos_banco_talentos_execut (
    id SERIAL PRIMARY KEY,
    nome_completo VARCHAR(200) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    telefone VARCHAR(20),
    linkedin_url VARCHAR(500),
    
    -- Informações profissionais
    pretensao_salarial NUMERIC(12,2),
    experiencia_anos INTEGER,
    setor_interesse_id INTEGER REFERENCES setores_banco_talentos_execut(id) ON DELETE SET NULL,
    
    -- Respostas às perguntas gerais
    motivacao_trabalho TEXT,
    maior_qualidade TEXT,
    habilidade_melhorar TEXT,
    desafio_resolvido TEXT,
    
    -- Currículo
    curriculo_tipo VARCHAR(20), -- 'arquivo' ou 'link'
    curriculo_url VARCHAR(500),
    curriculo_arquivo_path VARCHAR(500), -- Path no Supabase Storage
    
    -- Informações adicionais
    github_url VARCHAR(500),
    portfolio_url VARCHAR(500),
    nivel_educacao VARCHAR(100),
    
    -- Controle
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes
CREATE INDEX idx_candidatos_email ON candidatos_banco_talentos_execut(email);
CREATE INDEX idx_candidatos_setor ON candidatos_banco_talentos_execut(setor_interesse_id);
CREATE INDEX idx_candidatos_experiencia ON candidatos_banco_talentos_execut(experiencia_anos);
CREATE INDEX idx_candidatos_salario ON candidatos_banco_talentos_execut(pretensao_salarial);;
