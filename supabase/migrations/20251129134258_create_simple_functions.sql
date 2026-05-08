-- Create function to get job questions for application form
CREATE OR REPLACE FUNCTION get_job_questions(p_vaga_id UUID)
RETURNS TABLE (
    id UUID,
    titulo VARCHAR(255),
    descricao TEXT,
    tipo_pergunta VARCHAR(50),
    obrigatorio BOOLEAN,
    ordem INTEGER,
    opcoes JSONB,
    placeholder VARCHAR(500),
    mascara VARCHAR(100)
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        pq.id,
        pq.titulo,
        pq.descricao,
        pq.tipo_pergunta,
        pq.obrigatorio,
        pq.ordem,
        pq.opcoes,
        pq.placeholder,
        pq.mascara
    FROM perguntas_vagas_banco_talentos_execut pq
    WHERE pq.vaga_id = p_vaga_id 
      AND pq.ativo = true
    ORDER BY pq.ordem;
END;
$$ LANGUAGE plpgsql;

-- Create simple function to check duplicate applications
CREATE OR REPLACE FUNCTION check_duplicate_application(p_vaga_id UUID, p_email VARCHAR(255))
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS(
        SELECT 1 FROM candidato_aplicacoes_banco_talentos_execut 
        WHERE vaga_id = p_vaga_id AND email = p_email
    );
END;
$$ LANGUAGE plpgsql;

-- Create view for job listings with application count
CREATE OR REPLACE VIEW vw_vagas_com_candidatos AS
SELECT 
    v.*,
    s.nome_setor,
    COUNT(ca.id) as total_candidatos,
    COUNT(CASE WHEN ca.status = 'Novo Currículo' THEN 1 END) as candidatos_novos,
    COUNT(CASE WHEN ca.status = 'Em Análise' THEN 1 END) as candidatos_analise,
    COUNT(CASE WHEN ca.status = 'Entrevista' THEN 1 END) as candidatos_entrevista
FROM vagas_banco_talentos_execut v
LEFT JOIN setores_banco_talentos_execut s ON v.setor_id = s.id
LEFT JOIN candidato_aplicacoes_banco_talentos_execut ca ON v.id = ca.vaga_id
GROUP BY v.id, s.nome_setor
ORDER BY v.created_at DESC;;
