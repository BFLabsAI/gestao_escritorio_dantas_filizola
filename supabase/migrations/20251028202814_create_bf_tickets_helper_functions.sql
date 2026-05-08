-- BF Tickets Helper Functions and Triggers
-- These functions implement critical business logic for the WhatsApp filtering system

-- Function to check if a group is tagged and active (CRITICAL for filtering logic)
CREATE OR REPLACE FUNCTION is_group_tagged_and_active(p_group_jid text)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    is_active_tagged boolean := false;
BEGIN
    SELECT EXISTS(
        SELECT 1 
        FROM tagged_groups_bf_tickets tg
        JOIN groups_bf_tickets g ON tg.group_id = g.id
        WHERE g.group_jid = p_group_jid 
        AND tg.is_active = true
        LIMIT 1
    ) INTO is_active_tagged;
    
    RETURN is_active_tagged;
END;
$$;

-- Function to get or create conversation
CREATE OR REPLACE FUNCTION get_or_create_conversation(
    p_remote_jid text,
    p_contact_name text DEFAULT NULL,
    p_contact_phone text DEFAULT NULL,
    p_is_group boolean DEFAULT false,
    p_group_tag text DEFAULT NULL
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    conversation_id uuid;
BEGIN
    -- Try to get existing conversation
    SELECT id INTO conversation_id
    FROM conversations_bf_tickets
    WHERE remote_jid = p_remote_jid
    LIMIT 1;
    
    -- If not found, create new conversation
    IF conversation_id IS NULL THEN
        INSERT INTO conversations_bf_tickets (
            remote_jid,
            contact_name,
            contact_phone,
            is_group,
            group_tag
        ) VALUES (
            p_remote_jid,
            p_contact_name,
            p_contact_phone,
            p_is_group,
            p_group_tag
        ) RETURNING id INTO conversation_id;
    END IF;
    
    RETURN conversation_id;
END;
$$;

-- Function to update conversation last_message_at
CREATE OR REPLACE FUNCTION update_conversation_last_message(p_conversation_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    UPDATE conversations_bf_tickets
    SET last_message_at = now()
    WHERE id = p_conversation_id;
END;
$$;

-- Function to get tagged groups for filtering
CREATE OR REPLACE FUNCTION get_tagged_groups_jids()
RETURNS text[]
LANGUAGE sql
SECURITY DEFINER
AS $$
    SELECT ARRAY_AGG(DISTINCT g.group_jid)
    FROM tagged_groups_bf_tickets tg
    JOIN groups_bf_tickets g ON tg.group_id = g.id
    WHERE tg.is_active = true;
$$;

-- Function to process message filtering logic
CREATE OR REPLACE FUNCTION should_process_message(p_remote_jid text)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    is_group_message boolean;
    should_process boolean := false;
BEGIN
    -- Check if this is a group message
    is_group_message := p_remote_jid LIKE '%@g.us';
    
    -- Apply filtering logic
    IF NOT is_group_message THEN
        -- Individual messages: ALWAYS PROCESS
        should_process := true;
    ELSE
        -- Group messages: PROCESS ONLY if tagged and active
        should_process := is_group_tagged_and_active(p_remote_jid);
    END IF;
    
    RETURN should_process;
END;
$$;

-- Function to get conversation statistics
CREATE OR REPLACE FUNCTION get_conversation_statistics()
RETURNS jsonb
LANGUAGE sql
SECURITY DEFINER
AS $$
    WITH stats AS (
        SELECT 
            COUNT(*) as total_conversations,
            COUNT(CASE WHEN status = 'open' THEN 1 END) as open_conversations,
            COUNT(CASE WHEN status = 'pending' THEN 1 END) as pending_conversations,
            COUNT(CASE WHEN status = 'closed' THEN 1 END) as closed_conversations,
            COUNT(CASE WHEN is_group = true THEN 1 END) as group_conversations,
            COUNT(CASE WHEN is_group = false THEN 1 END) as individual_conversations,
            COUNT(CASE WHEN last_message_at > now() - interval '24 hours' THEN 1 END) as active_today,
            COUNT(CASE WHEN last_message_at > now() - interval '7 days' THEN 1 END) as active_this_week
        FROM conversations_bf_tickets
    )
    SELECT to_jsonb(stats.*) FROM stats;
$$;

-- Function to cleanup old messages (optional for maintenance)
CREATE OR REPLACE FUNCTION cleanup_old_messages(p_days_old integer DEFAULT 90)
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    deleted_count integer;
BEGIN
    -- Delete messages older than specified days, but keep conversation records
    DELETE FROM media_files_bf_tickets 
    WHERE message_id IN (
        SELECT m.id 
        FROM messages_bf_tickets m 
        WHERE m.timestamp < now() - (p_days_old || ' days')::interval
    );
    
    DELETE FROM messages_bf_tickets 
    WHERE timestamp < now() - (p_days_old || ' days')::interval;
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    
    -- Update conversations that no longer have messages
    UPDATE conversations_bf_tickets c
    SET last_message_at = NULL
    WHERE NOT EXISTS (
        SELECT 1 FROM messages_bf_tickets m 
        WHERE m.conversation_id = c.id
    );
    
    RETURN deleted_count;
END;
$$;

-- Trigger to automatically update conversation when message is added
CREATE OR REPLACE FUNCTION auto_update_conversation_on_message()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Update conversation's last_message_at and status
    UPDATE conversations_bf_tickets
    SET 
        last_message_at = NEW.timestamp,
        status = CASE 
            WHEN status = 'closed' THEN 'open'  -- Reopen closed conversation on new message
            ELSE status 
        END,
        updated_at = now()
    WHERE id = NEW.conversation_id;
    
    RETURN NEW;
END;
$$;

-- Create the trigger
CREATE TRIGGER on_message_insert_update_conversation
    AFTER INSERT ON messages_bf_tickets
    FOR EACH ROW
    EXECUTE FUNCTION auto_update_conversation_on_message();

-- View for message filtering logic verification
CREATE OR REPLACE VIEW message_filtering_debug AS
SELECT 
    c.remote_jid,
    c.is_group,
    c.group_tag,
    g.group_name,
    tg.tag_name as tagged_group_name,
    tg.is_active as is_tagged_active,
    should_process_message(c.remote_jid) as should_process,
    CASE 
        WHEN c.is_group = false THEN 'Individual message - ALWAYS PROCESS'
        WHEN tg.is_active = true THEN 'Tagged group - PROCESS'
        ELSE 'Untagged group - IGNORE'
    END as processing_rule
FROM conversations_bf_tickets c
LEFT JOIN groups_bf_tickets g ON c.remote_jid = g.group_jid
LEFT JOIN tagged_groups_bf_tickets tg ON g.id = tg.group_id
ORDER BY c.is_group, c.remote_jid;;
