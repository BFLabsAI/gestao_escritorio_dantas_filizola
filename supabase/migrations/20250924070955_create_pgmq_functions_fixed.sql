-- Create PGMQ helper functions if they don't exist

-- Function to send message to queue
CREATE OR REPLACE FUNCTION pgmq_send(
  queue_name text,
  message jsonb,
  delay integer DEFAULT 0
) RETURNS BIGINT AS $$
BEGIN
  RETURN pgmq.send(queue_name, message, delay);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to read messages from queue
CREATE OR REPLACE FUNCTION pgmq_read(
  queue_name text,
  visibility_timeout integer DEFAULT 30,
  qty integer DEFAULT 1
) RETURNS TABLE(
  msg_id bigint,
  read_ct integer,
  enqueued_at timestamp with time zone,
  vt timestamp with time zone,
  message jsonb
) AS $$
BEGIN
  RETURN QUERY SELECT * FROM pgmq.read(queue_name, visibility_timeout, qty);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to delete message from queue
CREATE OR REPLACE FUNCTION pgmq_delete(
  queue_name text,
  msg_id bigint
) RETURNS BOOLEAN AS $$
BEGIN
  RETURN pgmq.delete(queue_name, msg_id);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;;
