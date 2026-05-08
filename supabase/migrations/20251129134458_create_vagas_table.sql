-- Create the new vagas table to replace the old cargos table
DROP TABLE IF EXISTS vagas_banco_talentos_execut CASCADE;

CREATE TABLE vagas_banco_talentos_execut (
    id SERIAL PRIMARY KEY,
    setor_id INTEGER REFERENCES setores_banco_talentos_execut(id) ON DELETE SET NULL,
    nome_cargo VARCHAR(200) NOT NULL,
    tipo_contrato VARCHAR(50) NOT NULL, -- 'CLT', 'PJ', 'Estágio', 'Trainee'
    modalidade VARCHAR(50) NOT NULL, -- 'Presencial', 'Remoto', 'Híbrido'
    localizacao VARCHAR(200),
    salario_min NUMERIC(12,2),
    salario_max NUMERIC(12,2),
    beneficios TEXT, -- JSON array of benefits
    descricao TEXT, -- Descrição detalhada da vaga
    requisitos TEXT, -- Requisitos obrigatórios
    diferenciais TEXT, -- Diferenciais candidatos
    status VARCHAR(20) DEFAULT 'aberta', -- 'aberta', 'pausada', 'encerrada'
    experiencia_minima VARCHAR(50), -- '0', '1', '3', '5+'
    education_level VARCHAR(100), -- 'Ensino Médio', 'Superior', etc.
    
    -- Campos para específicas por área (JSON)
    perguntas_especificas JSONB, -- Perguntas específicas do cargo baseado no cargos.md
    ferramentas_requeridas JSONB, -- Lista de ferramentas/tecnologias
    
    -- Campos de controle
    data_publicacao TIMESTAMPTZ DEFAULT NOW(),
    data_encerramento TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX idx_vagas_setor_id ON vagas_banco_talentos_execut(setor_id);
CREATE INDEX idx_vagas_status ON vagas_banco_talentos_execut(status);
CREATE INDEX idx_vagas_cargo ON vagas_banco_talentos_execut(nome_cargo);
CREATE INDEX idx_vagas_contrato ON vagas_banco_talentos_execut(tipo_contrato);
CREATE INDEX idx_vagas_salario ON vagas_banco_talentos_execut(salario_min, salario_max);;
