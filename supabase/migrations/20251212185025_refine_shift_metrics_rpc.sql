DROP FUNCTION IF EXISTS calculate_shift_metrics_audita_lead(uuid, timestamp with time zone, timestamp with time zone);

CREATE OR REPLACE FUNCTION public.calculate_shift_metrics_audita_lead(
    p_tenant_id uuid,
    p_start_date timestamp with time zone,
    p_end_date timestamp with time zone,
    p_consultant_id uuid DEFAULT NULL::uuid
)
RETURNS TABLE(
    shift_name text,
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
SECURITY DEFINER
AS $function$
BEGIN
    RETURN QUERY
    WITH filtered_messages AS (
        SELECT 
            m.*,
            CASE 
                WHEN EXTRACT(HOUR FROM m.sent_at AT TIME ZONE 'America/Fortaleza') >= 6 AND EXTRACT(HOUR FROM m.sent_at AT TIME ZONE 'America/Fortaleza') < 12 THEN 'Manhã'
                WHEN EXTRACT(HOUR FROM m.sent_at AT TIME ZONE 'America/Fortaleza') >= 12 AND EXTRACT(HOUR FROM m.sent_at AT TIME ZONE 'America/Fortaleza') < 18 THEN 'Tarde'
                ELSE 'Noite'
            END as shift
        FROM public.messages_audita_lead m
        LEFT JOIN public.instances_audita_lead i ON m.instance_id = i.id
        WHERE m.tenant_id = p_tenant_id
        AND m.sent_at BETWEEN p_start_date AND p_end_date
        AND (p_consultant_id IS NULL OR i.consultant_id = p_consultant_id)
    ),
    global_conversation_stats AS (
        -- We need global stats to determine "Ghosted" (never answered) and "Pending" (last msg is inbound)
        SELECT 
            contact_id,
            COUNT(*) FILTER (WHERE direction = 'inbound') as global_inbound_count,
            MAX(sent_at) FILTER (WHERE direction = 'inbound') as global_last_inbound,
            MAX(sent_at) FILTER (WHERE direction = 'outbound') as global_last_outbound
        FROM public.messages_audita_lead
        WHERE tenant_id = p_tenant_id
        GROUP BY contact_id
    ),
    shift_stats AS (
        SELECT 
            fm.shift,
            COUNT(DISTINCT fm.contact_id) as total_convs,
            -- Connected: Has inbound message IN THIS SHIFT
            COUNT(DISTINCT fm.contact_id) FILTER (WHERE fm.direction = 'inbound') as connected,
            -- Ghosted: Active in shift (outbound) AND Global Inbound == 0
            COUNT(DISTINCT fm.contact_id) FILTER (WHERE fm.direction = 'outbound' AND gcs.global_inbound_count = 0) as ghosted,
            -- Pending: Active in shift AND Global Last Message is Inbound
            COUNT(DISTINCT fm.contact_id) FILTER (WHERE gcs.global_last_inbound > COALESCE(gcs.global_last_outbound, '1970-01-01'::TIMESTAMPTZ)) as pending,
            
            COUNT(*) as total_msgs,
            COUNT(*) FILTER (WHERE fm.direction = 'outbound') as outbound,
            COUNT(*) FILTER (WHERE fm.direction = 'inbound') as inbound,
            COUNT(*) FILTER (WHERE fm.message_type = 'image') as images,
            COUNT(*) FILTER (WHERE fm.message_type = 'audio') as audios,
            COUNT(*) FILTER (WHERE fm.message_type = 'document') as docs
        FROM filtered_messages fm
        JOIN global_conversation_stats gcs ON gcs.contact_id = fm.contact_id
        GROUP BY fm.shift
    )
    SELECT 
        s.shift as shift_name,
        s.total_convs::BIGINT as total_conversations,
        s.connected::BIGINT as connected_conversations,
        CASE 
            WHEN s.total_convs = 0 THEN 0
            ELSE (s.connected::NUMERIC / s.total_convs::NUMERIC) * 100
        END as connection_percentage,
        s.ghosted::BIGINT as ghosted_conversations,
        s.pending::BIGINT as pending_conversations,
        s.total_msgs::BIGINT as total_messages,
        s.outbound::BIGINT as outbound_messages,
        s.inbound::BIGINT as inbound_messages,
        s.images::BIGINT as image_count,
        s.audios::BIGINT as audio_count,
        s.docs::BIGINT as document_count
    FROM shift_stats s
    ORDER BY 
        CASE s.shift
            WHEN 'Manhã' THEN 1
            WHEN 'Tarde' THEN 2
            ELSE 3
        END;
END;
$function$;;
