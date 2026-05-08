ALTER TABLE inbox_whatsapp_conversations_inbox_manager
  ADD COLUMN IF NOT EXISTS instance_key TEXT;

ALTER TABLE inbox_whatsapp_log_inbox_manager
  ADD COLUMN IF NOT EXISTS instance_key TEXT;

CREATE INDEX IF NOT EXISTS inbox_whatsapp_conversations_instance_key_idx
  ON inbox_whatsapp_conversations_inbox_manager (instance_key, last_message_at DESC);

CREATE INDEX IF NOT EXISTS inbox_whatsapp_log_instance_key_idx
  ON inbox_whatsapp_log_inbox_manager (instance_key, created_at DESC);

WITH latest_messages AS (
  SELECT DISTINCT ON (contact_phone)
    contact_phone,
    instance_key
  FROM inbox_messages_inbox_manager
  WHERE contact_phone IS NOT NULL
    AND contact_phone <> ''
  ORDER BY contact_phone, created_at DESC
)
UPDATE inbox_whatsapp_conversations_inbox_manager c
SET instance_key = latest_messages.instance_key
FROM latest_messages
WHERE c.contact_phone = latest_messages.contact_phone
  AND (c.instance_key IS NULL OR c.instance_key = '');

UPDATE inbox_whatsapp_log_inbox_manager l
SET instance_key = COALESCE(l.instance_key, l.raw_payload->>'instanceName', l.raw_payload->>'instance_name')
WHERE l.instance_key IS NULL OR l.instance_key = '';;
