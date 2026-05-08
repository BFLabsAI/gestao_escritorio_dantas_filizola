-- Create the setores table first to avoid dependency issues
DROP TABLE IF EXISTS setores_banco_talentos_execut CASCADE;

CREATE TABLE setores_banco_talentos_execut (
    id SERIAL PRIMARY KEY,
    nome_setor VARCHAR(100) NOT NULL UNIQUE,
    descricao TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Insert basic sectors from cargos.md
INSERT INTO setores_banco_talentos_execut (nome_setor, descricao) VALUES
('Vendas', 'Equipe responsável por prospecção, negociação e fechamento de novos negócios'),
('Marketing', 'Equipe responsável por marketing digital, criação de conteúdo e geração de demanda'),
('CS', 'Equipe de Customer Success e Suporte ao Cliente'),
('Negócios', 'Equipe responsável por estratégias de crescimento e análise de dados'),
('Tecnologia', 'Equipe de desenvolvimento e engenharia de sistemas');;
