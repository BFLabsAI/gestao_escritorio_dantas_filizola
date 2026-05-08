-- Create sectors table
CREATE TABLE setores_banco_talentos_execut (
    id SERIAL PRIMARY KEY,
    nome_setor TEXT NOT NULL UNIQUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Insert initial sectors data
INSERT INTO setores_banco_talentos_execut (nome_setor) VALUES
('Vendas'),
('Marketing'),
('CS'),
('Negócios'),
('Tecnologia');;
