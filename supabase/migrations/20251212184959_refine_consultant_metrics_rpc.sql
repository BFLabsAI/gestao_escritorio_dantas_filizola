DROP FUNCTION IF EXISTS calculate_consultant_metrics_audita_lead(uuid, timestamp with time zone, timestamp with time zone);

CREATE OR REPLACE FUNCTION public.calculate_consultant_metrics_audita_lead(
    p_tenant_id uuid,
    p_start_date timestamp with time zone,
    p_end_date timestamp with time zone,
    p_consultant_id uuid DEFAULT NULL::uuid,
    p_shift text DEFAULT 'all'
)
RETURNS TABLE(
    consultant_id uuid,
    consultant_name text,
    consultant_phone text,
    total_conversations bigint,
    connected_conversations bigint,
    connection_percentage numeric,
    ghosted_conversations bigint,
    pending_conversations bigint,
    total_messages bigint,
    outbound_messages bigint,
    inbound_messages bigint,
    image_count bigint,
    audio_count bigint,
    document_count bigint
)
LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    WITH consultant_instances AS (
        SELECT 
            c.id as c_id,
            c.name as c_name,
            c.phone as c_phone,
            i.id as instance_id
        FROM public.consultants_audita_lead c
        LEFT JOIN public.instances_audita_lead i ON i.consultant_id = c.id
        WHERE c.tenant_id = p_tenant_id
        AND (p_consultant_id IS NULL OR c.id = p_consultant_id)
    ),
    filtered_messages AS (
        SELECT m.*
        FROM public.messages_audita_lead m
        WHERE m.tenant_id = p_tenant_id
        AND m.sent_at BETWEEN p_start_date AND p_end_date
        AND (
            p_shift = 'all' OR
            CASE 
                WHEN EXTRACT(HOUR FROM m.sent_at AT TIME ZONE 'America/Fortaleza') >= 6 AND EXTRACT(HOUR FROM m.sent_at AT TIME ZONE 'America/Fortaleza') < 12 THEN 'morning'
                WHEN EXTRACT(HOUR FROM m.sent_at AT TIME ZONE 'America/Fortaleza') >= 12 AND EXTRACT(HOUR FROM m.sent_at AT TIME ZONE 'America/Fortaleza') < 18 THEN 'afternoon'
                ELSE 'night'
            END = p_shift
        )
    ),
    message_stats AS (
        SELECT 
            m.instance_id,
            COUNT(*) as total_msgs,
            COUNT(*) FILTER (WHERE m.direction = 'outbound') as outbound,
            COUNT(*) FILTER (WHERE m.direction = 'inbound') as inbound,
            COUNT(*) FILTER (WHERE m.message_type = 'image') as images,
            COUNT(*) FILTER (WHERE m.message_type = 'audio') as audios,
            COUNT(*) FILTER (WHERE m.message_type = 'document') as docs
        FROM filtered_messages m
        GROUP BY m.instance_id
    ),
    conversation_stats AS (
        SELECT 
            m.instance_id,
            m.contact_id,
            COUNT(*) as total_msgs,
            COUNT(*) FILTER (WHERE m.direction = 'inbound') as inbound_count,
            COUNT(*) FILTER (WHERE m.direction = 'outbound') as outbound_count,
            MAX(m.sent_at) FILTER (WHERE m.direction = 'inbound') as last_inbound,
            MAX(m.sent_at) FILTER (WHERE m.direction = 'outbound') as last_outbound
        FROM filtered_messages m
        LEFT JOIN exceptions_audita_lead e ON e.phone = (SELECT phone FROM contacts_audita_lead WHERE id = m.contact_id) AND e.tenant_id = m.tenant_id
        WHERE e.id IS NULL
        GROUP BY m.instance_id, m.contact_id
    ),
    aggregated_conv_stats AS (
        SELECT
            instance_id,
            COUNT(*) as total_convs,
            COUNT(*) FILTER (WHERE inbound_count > 0) as connected,
            -- No Vácuo: inbound_count = 0 AND outbound_count > 0
            COUNT(*) FILTER (WHERE inbound_count = 0 AND outbound_count > 0) as ghosted,
            -- Pendentes: last_inbound > last_outbound
            COUNT(*) FILTER (WHERE last_inbound > COALESCE(last_outbound, '1970-01-01'::TIMESTAMPTZ)) as pending
        FROM conversation_stats
        GROUP BY instance_id
    )
    SELECT 
        ci.c_id,
        ci.c_name,
        ci.c_phone,
        COALESCE(acs.total_convs, 0)::BIGINT as total_conversations,
        COALESCE(acs.connected, 0)::BIGINT as connected_conversations,
        CASE 
            WHEN COALESCE(acs.total_convs, 0) = 0 THEN 0
            ELSE (COALESCE(acs.connected, 0)::NUMERIC / COALESCE(acs.total_convs, 0)::NUMERIC) * 100
        END as connection_percentage,
        COALESCE(acs.ghosted, 0)::BIGINT as ghosted_conversations,
        COALESCE(acs.pending, 0)::BIGINT as pending_conversations,
        COALESCE(ms.total_msgs, 0)::BIGINT as total_messages,
        COALESCE(ms.outbound, 0)::BIGINT as outbound_messages,
        COALESCE(ms.inbound, 0)::BIGINT as inbound_messages,
        COALESCE(ms.images, 0)::BIGINT as image_count,
        COALESCE(ms.audios, 0)::BIGINT as audio_count,
        COALESCE(ms.docs, 0)::BIGINT as document_count
    FROM consultant_instances ci
    LEFT JOIN aggregated_conv_stats acs ON acs.instance_id = ci.instance_id
    LEFT JOIN message_stats ms ON ms.instance_id = ci.instance_id;
END;
$function$;;
