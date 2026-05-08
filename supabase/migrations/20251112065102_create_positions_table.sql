-- Create positions table
CREATE TABLE cargos_banco_talentos_execut (
    id SERIAL PRIMARY KEY,
    setor_id INTEGER REFERENCES setores_banco_talentos_execut(id) ON DELETE CASCADE,
    nome_cargo TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(setor_id, nome_cargo)
);

-- Insert initial positions data for each sector
-- Vendas positions (sector_id = 1)
INSERT INTO cargos_banco_talentos_execut (setor_id, nome_cargo) VALUES
(1, 'SDR/BDR'),
(1, 'Closer');

-- Marketing positions (sector_id = 2)
INSERT INTO cargos_banco_talentos_execut (setor_id, nome_cargo) VALUES
(2, 'Social Media'),
(2, 'Filmmaker'),
(2, 'Designer'),
(2, 'Copywriter'),
(2, 'Gestor de Tráfego');

-- CS positions (sector_id = 3)
INSERT INTO cargos_banco_talentos_execut (setor_id, nome_cargo) VALUES
(3, 'Atendimento/Suporte'),
(3, 'Sucesso do Cliente (CSM)');

-- Negócios positions (sector_id = 4)
INSERT INTO cargos_banco_talentos_execut (setor_id, nome_cargo) VALUES
(4, 'Consultor Comercial/Especialista em CRM'),
(4, 'Analista de Growth'),
(4, 'Analista de Dados');

-- Tecnologia positions (sector_id = 5)
INSERT INTO cargos_banco_talentos_execut (setor_id, nome_cargo) VALUES
(5, 'Desenvolvedor Front-end'),
(5, 'Desenvolvedor Back-end'),
(5, 'Desenvolvedor Fullstack'),
(5, 'Engenheiro de Dados');;
