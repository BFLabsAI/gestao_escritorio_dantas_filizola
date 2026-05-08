-- Function to get positions by sector
CREATE OR REPLACE FUNCTION get_positions_by_sector(sector_id_param INTEGER)
RETURNS TABLE (
    id INTEGER,
    nome_cargo TEXT,
    nome_setor TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        c.id,
        c.nome_cargo,
        s.nome_setor
    FROM cargos_banco_talentos_execut c
    JOIN setores_banco_talentos_execut s ON c.setor_id = s.id
    WHERE c.setor_id = sector_id_param
    ORDER BY c.nome_cargo;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to search candidates with advanced filtering
CREATE OR REPLACE FUNCTION search_candidates(
    search_term TEXT DEFAULT NULL,
    sector_id_param INTEGER DEFAULT NULL,
    cargo_id_param INTEGER DEFAULT NULL,
    status_param TEXT DEFAULT NULL,
    min_salary NUMERIC DEFAULT NULL,
    max_salary NUMERIC DEFAULT NULL
)
RETURNS TABLE (
    id UUID,
    nome TEXT,
    email TEXT,
    telefone TEXT,
    linkedin_url TEXT,
    nome_cargo TEXT,
    nome_setor TEXT,
    pretensao_salarial NUMERIC,
    status TEXT,
    created_at TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        c.id,
        c.nome,
        c.email,
        c.telefone,
        c.linkedin_url,
        cg.nome_cargo,
        s.nome_setor,
        c.pretensao_salarial,
        c.status,
        c.created_at
    FROM candidatos_banco_talentos_execut c
    JOIN cargos_banco_talentos_execut cg ON c.cargo_id = cg.id
    JOIN setores_banco_talentos_execut s ON cg.setor_id = s.id
    WHERE
        (search_term IS NULL OR
         c.nome ILIKE '%' || search_term || '%' OR
         c.email ILIKE '%' || search_term || '%' OR
         c.telefone ILIKE '%' || search_term || '%')
        AND (sector_id_param IS NULL OR cg.setor_id = sector_id_param)
        AND (cargo_id_param IS NULL OR c.cargo_id = cargo_id_param)
        AND (status_param IS NULL OR c.status = status_param)
        AND (min_salary IS NULL OR c.pretensao_salarial >= min_salary)
        AND (max_salary IS NULL OR c.pretensao_salarial <= max_salary)
    ORDER BY c.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get all sectors with positions count
CREATE OR REPLACE FUNCTION get_sectors_with_position_count()
RETURNS TABLE (
    id INTEGER,
    nome_setor TEXT,
    position_count BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        s.id,
        s.nome_setor,
        COUNT(c.id) as position_count
    FROM setores_banco_talentos_execut s
    LEFT JOIN cargos_banco_talentos_execut c ON s.id = c.setor_id
    GROUP BY s.id, s.nome_setor
    ORDER BY s.nome_setor;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get candidate statistics
CREATE OR REPLACE FUNCTION get_candidate_statistics()
RETURNS TABLE (
    total_candidates BIGINT,
    new_candidates BIGINT,
    in_review_candidates BIGINT,
    interviewed_candidates BIGINT,
    approved_candidates BIGINT,
    rejected_candidates BIGINT,
    allocated_candidates BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        COUNT(*) as total_candidates,
        COUNT(*) FILTER (WHERE status = 'Novo Currículo') as new_candidates,
        COUNT(*) FILTER (WHERE status = 'Em Análise') as in_review_candidates,
        COUNT(*) FILTER (WHERE status = 'Entrevista Agendada') as interviewed_candidates,
        COUNT(*) FILTER (WHERE status = 'Aprovado') as approved_candidates,
        COUNT(*) FILTER (WHERE status = 'Reprovado') as rejected_candidates,
        COUNT(*) FILTER (WHERE status = 'Alocado') as allocated_candidates
    FROM candidatos_banco_talentos_execut;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;;
