-- Create wrapper functions for PGMQ in the public schema with different names
CREATE OR REPLACE FUNCTION pgmq_read_message(queue_name TEXT, vt_seconds INTEGER, qty INTEGER DEFAULT 1)
RETURNS TABLE (
  msg_id BIGINT,
  read_ct INTEGER,
  enqueued_at TIMESTAMP WITH TIME ZONE,
  vt TIMESTAMP WITH TIME ZONE,
  message JSONB
) AS $$
BEGIN
  RETURN QUERY SELECT * FROM pgmq.read(queue_name, vt_seconds, qty);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION pgmq_send_message(queue_name TEXT, message JSONB, delay_seconds INTEGER DEFAULT 0)
RETURNS BIGINT AS $$
BEGIN
  RETURN pgmq.send(queue_name, message, delay_seconds);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION pgmq_archive_message(queue_name TEXT, msg_id BIGINT)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN pgmq.archive(queue_name, msg_id);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;;
