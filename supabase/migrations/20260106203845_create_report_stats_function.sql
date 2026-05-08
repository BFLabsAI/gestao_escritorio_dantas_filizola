-- Function to get report statistics with proper timezone handling
-- created_at is timestamptz (UTC), data_ultima_interacao is timestamp without timezone (Fortaleza local)

CREATE OR REPLACE FUNCTION get_report_stats(
    p_start_date DATE,
    p_end_date DATE
)
RETURNS TABLE (
    new_leads BIGINT,
    contacted BIGINT,
    repassado BIGINT,
    cadence_breakdown JSONB
) 
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    WITH stats AS (
        SELECT
            -- New leads: convert created_at to Fortaleza timezone for comparison
            COUNT(*) FILTER (
                WHERE (created_at AT TIME ZONE 'America/Fortaleza')::date >= p_start_date 
                AND (created_at AT TIME ZONE 'America/Fortaleza')::date <= p_end_date
            ) as new_leads_count,
            
            -- Contacted: data_ultima_interacao is already in Fortaleza local time
            COUNT(*) FILTER (
                WHERE data_ultima_interacao::date >= p_start_date 
                AND data_ultima_interacao::date <= p_end_date
            ) as contacted_count,
            
            -- Repassado: filter by status and date
            COUNT(*) FILTER (
                WHERE status_lead = 'repassado' 
                AND data_ultima_interacao::date >= p_start_date 
                AND data_ultima_interacao::date <= p_end_date
            ) as repassado_count
        FROM leads_odonto_solluti
    ),
    cadence AS (
        SELECT 
            COALESCE(dia_cadencia, 'Desconhecido') as dia,
            COUNT(*) as count
        FROM leads_odonto_solluti
        WHERE data_ultima_interacao::date >= p_start_date 
        AND data_ultima_interacao::date <= p_end_date
        GROUP BY dia_cadencia
        ORDER BY dia_cadencia
    )
    SELECT 
        s.new_leads_count,
        s.contacted_count,
        s.repassado_count,
        COALESCE(
            (SELECT jsonb_object_agg(c.dia, c.count) FROM cadence c),
            '{}'::jsonb
        )
    FROM stats s;
END;
$$;;
