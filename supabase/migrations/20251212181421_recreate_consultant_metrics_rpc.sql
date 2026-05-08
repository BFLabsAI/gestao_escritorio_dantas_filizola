DROP FUNCTION IF EXISTS public.calculate_consultant_metrics_audita_lead(uuid,timestamp with time zone,timestamp with time zone);

CREATE OR REPLACE FUNCTION public.calculate_consultant_metrics_audita_lead(
    p_tenant_id UUID,
    p_start_date TIMESTAMPTZ,
    p_end_date TIMESTAMPTZ
)
RETURNS TABLE (
    consultant_id UUID,
    consultant_name TEXT,
    consultant_phone TEXT,
    total_conversations BIGINT,
    connected_conversations BIGINT,
    connection_percentage NUMERIC,
    ghosted_conversations BIGINT,
    pending_conversations BIGINT,
    total_messages BIGINT,
    outbound_messages BIGINT,
    inbound_messages BIGINT,
    image_count BIGINT,
    audio_count BIGINT,
    document_count BIGINT
) AS $$
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
        FROM public.messages_audita_lead m
        WHERE m.tenant_id = p_tenant_id
        AND m.sent_at >= p_start_date
        AND m.sent_at <= p_end_date
        GROUP BY m.instance_id
    ),
    conversation_stats AS (
        SELECT 
            m.instance_id,
            COUNT(DISTINCT m.contact_id) as total_convs,
            -- Logic for connected: has both inbound and outbound
            COUNT(DISTINCT m.contact_id) FILTER (WHERE 
                EXISTS (SELECT 1 FROM public.messages_audita_lead m2 WHERE m2.contact_id = m.contact_id AND m2.direction = 'inbound' AND m2.sent_at BETWEEN p_start_date AND p_end_date)
                AND 
                EXISTS (SELECT 1 FROM public.messages_audita_lead m3 WHERE m3.contact_id = m.contact_id AND m3.direction = 'outbound' AND m3.sent_at BETWEEN p_start_date AND p_end_date)
            ) as connected,
            -- Logic for ghosted: outbound but no inbound
            COUNT(DISTINCT m.contact_id) FILTER (WHERE 
                EXISTS (SELECT 1 FROM public.messages_audita_lead m3 WHERE m3.contact_id = m.contact_id AND m3.direction = 'outbound' AND m3.sent_at BETWEEN p_start_date AND p_end_date)
                AND 
                NOT EXISTS (SELECT 1 FROM public.messages_audita_lead m2 WHERE m2.contact_id = m.contact_id AND m2.direction = 'inbound' AND m2.sent_at BETWEEN p_start_date AND p_end_date)
            ) as ghosted,
             -- Logic for pending: inbound but no outbound (needs reply)
            COUNT(DISTINCT m.contact_id) FILTER (WHERE 
                EXISTS (SELECT 1 FROM public.messages_audita_lead m2 WHERE m2.contact_id = m.contact_id AND m2.direction = 'inbound' AND m2.sent_at BETWEEN p_start_date AND p_end_date)
                AND 
                NOT EXISTS (SELECT 1 FROM public.messages_audita_lead m3 WHERE m3.contact_id = m.contact_id AND m3.direction = 'outbound' AND m3.sent_at > (
                    SELECT MAX(sent_at) FROM public.messages_audita_lead m4 WHERE m4.contact_id = m.contact_id AND m4.direction = 'inbound'
                ))
            ) as pending
        FROM public.messages_audita_lead m
        WHERE m.tenant_id = p_tenant_id
        AND m.sent_at >= p_start_date
        AND m.sent_at <= p_end_date
        GROUP BY m.instance_id
    )
    SELECT 
        ci.c_id,
        ci.c_name,
        ci.c_phone,
        COALESCE(SUM(cs.total_convs), 0)::BIGINT as total_conversations,
        COALESCE(SUM(cs.connected), 0)::BIGINT as connected_conversations,
        CASE 
            WHEN COALESCE(SUM(cs.total_convs), 0) = 0 THEN 0
            ELSE (COALESCE(SUM(cs.connected), 0)::NUMERIC / COALESCE(SUM(cs.total_convs), 0)::NUMERIC) * 100
        END as connection_percentage,
        COALESCE(SUM(cs.ghosted), 0)::BIGINT as ghosted_conversations,
        COALESCE(SUM(cs.pending), 0)::BIGINT as pending_conversations,
        COALESCE(SUM(ms.total_msgs), 0)::BIGINT as total_messages,
        COALESCE(SUM(ms.outbound), 0)::BIGINT as outbound_messages,
        COALESCE(SUM(ms.inbound), 0)::BIGINT as inbound_messages,
        COALESCE(SUM(ms.images), 0)::BIGINT as image_count,
        COALESCE(SUM(ms.audios), 0)::BIGINT as audio_count,
        COALESCE(SUM(ms.docs), 0)::BIGINT as document_count
    FROM consultant_instances ci
    LEFT JOIN conversation_stats cs ON cs.instance_id = ci.instance_id
    LEFT JOIN message_stats ms ON ms.instance_id = ci.instance_id
    GROUP BY ci.c_id, ci.c_name, ci.c_phone;
END;
$$ LANGUAGE plpgsql;;
