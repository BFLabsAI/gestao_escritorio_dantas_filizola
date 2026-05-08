DROP FUNCTION IF EXISTS calculate_metrics_audita_lead(uuid, timestamp with time zone, timestamp with time zone, uuid);

CREATE OR REPLACE FUNCTION public.calculate_metrics_audita_lead(
    p_tenant_id uuid,
    p_start_date timestamp with time zone,
    p_end_date timestamp with time zone,
    p_consultant_id uuid DEFAULT NULL::uuid,
    p_shift text DEFAULT 'all'
)
RETURNS TABLE(
    total_conversations bigint,
    connected_conversations bigint,
    connection_percentage numeric,
    ghosted_conversations bigint,
    pending_conversations bigint,
    not_connected_conversations bigint
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $function$
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
        LEFT JOIN instances_audita_lead i ON m.instance_id = i.id
        LEFT JOIN exceptions_audita_lead e ON e.phone = c.phone AND e.tenant_id = c.tenant_id
        WHERE c.tenant_id = p_tenant_id
          AND m.sent_at BETWEEN p_start_date AND p_end_date
          AND e.id IS NULL -- Exclude exceptions
          AND (p_consultant_id IS NULL OR i.consultant_id = p_consultant_id)
          AND (
            p_shift = 'all' OR
            CASE 
                WHEN EXTRACT(HOUR FROM m.sent_at AT TIME ZONE 'America/Fortaleza') >= 6 AND EXTRACT(HOUR FROM m.sent_at AT TIME ZONE 'America/Fortaleza') < 12 THEN 'morning'
                WHEN EXTRACT(HOUR FROM m.sent_at AT TIME ZONE 'America/Fortaleza') >= 12 AND EXTRACT(HOUR FROM m.sent_at AT TIME ZONE 'America/Fortaleza') < 18 THEN 'afternoon'
                ELSE 'night'
            END = p_shift
          )
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
        -- No Vácuo: Customer NEVER answered (inbound_count = 0) AND we sent at least one message
        COUNT(*) FILTER (WHERE inbound_count = 0 AND outbound_count > 0)::BIGINT as ghosted_conversations,
        -- Pendentes: Last message is from customer
        COUNT(*) FILTER (WHERE last_inbound > COALESCE(last_outbound, '1970-01-01'::TIMESTAMPTZ))::BIGINT as pending_conversations,
        -- Not Connected: Total - Connected
        (COUNT(*) - COUNT(*) FILTER (WHERE inbound_count > 0))::BIGINT as not_connected_conversations
    FROM conversation_stats;
END;
$function$;;
