-- Function to calculate conversation metrics for Audita Lead
-- Implements: Connected, Ghosted (No Vácuo), Pending calculations
-- Excludes contacts in exceptions_audita_lead table

CREATE OR REPLACE FUNCTION calculate_metrics_audita_lead(
    p_tenant_id UUID,
    p_start_date TIMESTAMPTZ,
    p_end_date TIMESTAMPTZ,
    p_user_id UUID DEFAULT NULL
)
RETURNS TABLE (
    total_conversations BIGINT,
    connected_conversations BIGINT,
    connection_percentage NUMERIC,
    ghosted_conversations BIGINT,
    pending_conversations BIGINT
) AS $$
BEGIN
    RETURN QUERY
    WITH conversation_stats AS (
        SELECT 
            c.id as contact_id,
            COUNT(*) as total_messages,
            COUNT(*) FILTER (WHERE m.direction = 'inbound') as inbound_count,
            COUNT(*) FILTER (WHERE m.direction = 'outbound') as outbound_count,
            MAX(m.sent_at) FILTER (WHERE m.direction = 'inbound') as last_inbound,
            MAX(m.sent_at) FILTER (WHERE m.direction = 'outbound') as last_outbound
        FROM contacts_audita_lead c
        JOIN messages_audita_lead m ON m.contact_id = c.id
        LEFT JOIN exceptions_audita_lead e ON e.phone = c.phone AND e.tenant_id = c.tenant_id
        WHERE c.tenant_id = p_tenant_id
          AND m.sent_at BETWEEN p_start_date AND p_end_date
          AND e.id IS NULL -- Exclude exceptions
          AND (p_user_id IS NULL OR m.user_id = p_user_id)
        GROUP BY c.id
    )
    SELECT 
        COUNT(*)::BIGINT as total_conversations,
        COUNT(*) FILTER (WHERE inbound_count > 0)::BIGINT as connected_conversations,
        COALESCE(
            ROUND(
                (COUNT(*) FILTER (WHERE inbound_count > 0)::NUMERIC / NULLIF(COUNT(*), 0)) * 100, 
                2
            ),
            0
        ) as connection_percentage,
        COUNT(*) FILTER (WHERE last_outbound > COALESCE(last_inbound, '1970-01-01'::TIMESTAMPTZ))::BIGINT as ghosted_conversations,
        COUNT(*) FILTER (WHERE last_inbound > COALESCE(last_outbound, '1970-01-01'::TIMESTAMPTZ))::BIGINT as pending_conversations
    FROM conversation_stats;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get metrics grouped by shift (turno)
-- Morning: 06:00-11:59, Afternoon: 12:00-17:59, Night: 18:00-05:59
CREATE OR REPLACE FUNCTION calculate_shift_metrics_audita_lead(
    p_tenant_id UUID,
    p_start_date TIMESTAMPTZ,
    p_end_date TIMESTAMPTZ
)
RETURNS TABLE (
    shift_name TEXT,
    total_messages BIGINT,
    inbound_messages BIGINT,
    outbound_messages BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        CASE 
            WHEN EXTRACT(HOUR FROM m.sent_at) >= 6 AND EXTRACT(HOUR FROM m.sent_at) < 12 THEN 'Manhã'
            WHEN EXTRACT(HOUR FROM m.sent_at) >= 12 AND EXTRACT(HOUR FROM m.sent_at) < 18 THEN 'Tarde'
            ELSE 'Noite'
        END as shift_name,
        COUNT(*)::BIGINT as total_messages,
        COUNT(*) FILTER (WHERE m.direction = 'inbound')::BIGINT as inbound_messages,
        COUNT(*) FILTER (WHERE m.direction = 'outbound')::BIGINT as outbound_messages
    FROM messages_audita_lead m
    JOIN contacts_audita_lead c ON c.id = m.contact_id
    LEFT JOIN exceptions_audita_lead e ON e.phone = c.phone AND e.tenant_id = c.tenant_id
    WHERE m.tenant_id = p_tenant_id
      AND m.sent_at BETWEEN p_start_date AND p_end_date
      AND e.id IS NULL
    GROUP BY 
        CASE 
            WHEN EXTRACT(HOUR FROM m.sent_at) >= 6 AND EXTRACT(HOUR FROM m.sent_at) < 12 THEN 'Manhã'
            WHEN EXTRACT(HOUR FROM m.sent_at) >= 12 AND EXTRACT(HOUR FROM m.sent_at) < 18 THEN 'Tarde'
            ELSE 'Noite'
        END
    ORDER BY 
        CASE shift_name
            WHEN 'Manhã' THEN 1
            WHEN 'Tarde' THEN 2
            ELSE 3
        END;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get metrics grouped by consultant (user)
CREATE OR REPLACE FUNCTION calculate_consultant_metrics_audita_lead(
    p_tenant_id UUID,
    p_start_date TIMESTAMPTZ,
    p_end_date TIMESTAMPTZ
)
RETURNS TABLE (
    user_id UUID,
    user_name TEXT,
    total_conversations BIGINT,
    connected_conversations BIGINT,
    ghosted_conversations BIGINT,
    pending_conversations BIGINT
) AS $$
BEGIN
    RETURN QUERY
    WITH conversation_stats AS (
        SELECT 
            u.id as uid,
            u.name as uname,
            c.id as contact_id,
            COUNT(*) FILTER (WHERE m.direction = 'inbound') as inbound_count,
            MAX(m.sent_at) FILTER (WHERE m.direction = 'inbound') as last_inbound,
            MAX(m.sent_at) FILTER (WHERE m.direction = 'outbound') as last_outbound
        FROM users_audita_lead u
        JOIN messages_audita_lead m ON m.user_id = u.id
        JOIN contacts_audita_lead c ON c.id = m.contact_id
        LEFT JOIN exceptions_audita_lead e ON e.phone = c.phone AND e.tenant_id = c.tenant_id
        WHERE u.tenant_id = p_tenant_id
          AND m.sent_at BETWEEN p_start_date AND p_end_date
          AND e.id IS NULL
        GROUP BY u.id, u.name, c.id
    )
    SELECT 
        uid as user_id,
        uname as user_name,
        COUNT(DISTINCT contact_id)::BIGINT as total_conversations,
        COUNT(DISTINCT contact_id) FILTER (WHERE inbound_count > 0)::BIGINT as connected_conversations,
        COUNT(DISTINCT contact_id) FILTER (WHERE last_outbound > COALESCE(last_inbound, '1970-01-01'::TIMESTAMPTZ))::BIGINT as ghosted_conversations,
        COUNT(DISTINCT contact_id) FILTER (WHERE last_inbound > COALESCE(last_outbound, '1970-01-01'::TIMESTAMPTZ))::BIGINT as pending_conversations
    FROM conversation_stats
    GROUP BY uid, uname
    ORDER BY total_conversations DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;;
