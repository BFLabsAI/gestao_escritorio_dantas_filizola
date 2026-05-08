-- Add additional indexes for performance optimization
-- Sectors table indexes
CREATE INDEX idx_setores_nome_setor ON setores_banco_talentos_execut(nome_setor);

-- Positions table indexes
CREATE INDEX idx_cargos_setor_id ON cargos_banco_talentos_execut(setor_id);
CREATE INDEX idx_cargos_nome_cargo ON cargos_banco_talentos_execut(nome_cargo);

-- Candidates table additional indexes
CREATE INDEX idx_candidatos_nome ON candidatos_banco_talentos_execut(nome);
CREATE INDEX idx_candidatos_telefone ON candidatos_banco_talentos_execut(telefone);
CREATE INDEX idx_candidatos_pretensao_salarial ON candidatos_banco_talentos_execut(pretensao_salarial);
CREATE INDEX idx_candidatos_status_cargo ON candidatos_banco_talentos_execut(status, cargo_id);
CREATE INDEX idx_candidatos_alocacao ON candidatos_banco_talentos_execut(alocacao) WHERE alocacao IS NOT NULL;

-- Specific responses table additional indexes
CREATE INDEX idx_respostas_pergunta_texto ON respostas_especificas_banco_talentos_execut(pergunta_texto);
CREATE INDEX idx_respostas_candidato_tipo ON respostas_especificas_banco_talentos_execut(candidato_id, tipo_resposta);

-- Internal notes table additional indexes
CREATE INDEX idx_notas_candidato_created ON notas_internas_banco_talentos_execut(candidato_id, created_at);

-- Add constraints for data integrity
-- Ensure email format is valid for candidates
ALTER TABLE candidatos_banco_talentos_execut 
ADD CONSTRAINT valid_email CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$');

-- Ensure status has valid values
ALTER TABLE candidatos_banco_talentos_execut 
ADD CONSTRAINT valid_status CHECK (status IN (
    'Novo Currículo', 
    'Em Análise', 
    'Entrevista Agendada', 
    'Aprovado', 
    'Reprovado', 
    'Alocado'
));

-- Ensure pretensao_salarial is positive
ALTER TABLE candidatos_banco_talentos_execut 
ADD CONSTRAINT positive_salary CHECK (pretensao_salarial IS NULL OR pretensao_salarial >= 0);

-- Create view for candidate summaries
CREATE OR REPLACE VIEW candidate_summaries_vw AS
SELECT 
    c.id,
    c.nome,
    c.email,
    c.telefone,
    c.status,
    c.pretensao_salarial,
    cg.nome_cargo,
    s.nome_setor,
    c.created_at,
    c.updated_at,
    -- Count of internal notes
    (SELECT COUNT(*) FROM notas_internas_banco_talentos_execut n WHERE n.candidato_id = c.id) as notes_count,
    -- Count of specific responses
    (SELECT COUNT(*) FROM respostas_especificas_banco_talentos_execut r WHERE r.candidato_id = c.id) as responses_count,
    -- Has CV indicator
    CASE WHEN c.cv_url IS NOT NULL THEN true ELSE false END as has_cv
FROM candidatos_banco_talentos_execut c
JOIN cargos_banco_talentos_execut cg ON c.cargo_id = cg.id
JOIN setores_banco_talentos_execut s ON cg.setor_id = s.id;

-- Create view for sector statistics
CREATE OR REPLACE VIEW sector_statistics_vw AS
SELECT 
    s.id,
    s.nome_setor,
    COUNT(c.id) as total_positions,
    COUNT(cand.id) as total_candidates,
    AVG(cand.pretensao_salarial) as avg_salary_expectation
FROM setores_banco_talentos_execut s
LEFT JOIN cargos_banco_talentos_execut c ON s.id = c.setor_id
LEFT JOIN candidatos_banco_talentos_execut cand ON c.id = cand.cargo_id
GROUP BY s.id, s.nome_setor
ORDER BY s.nome_setor;;
