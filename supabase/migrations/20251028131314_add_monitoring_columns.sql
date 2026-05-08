-- Add queue-related columns to disparador_r7_treinamentos table
ALTER TABLE disparador_r7_treinamentos
ADD COLUMN IF NOT EXISTS retry_count INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS next_retry_at TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS queue_msg_id BIGINT,
ADD COLUMN IF NOT EXISTS processed_at TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS queue_status VARCHAR(20) DEFAULT 'pending' CHECK (queue_status IN ('pending', 'processing', 'completed', 'failed', 'retrying'));

-- Add queue-related columns to agendamentos_disparador_r7_treinamentos table
ALTER TABLE agendamentos_disparador_r7_treinamentos
ADD COLUMN IF NOT EXISTS queue_msg_id BIGINT,
ADD COLUMN IF NOT EXISTS total_messages INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS processed_messages INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS failed_messages INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS queue_status VARCHAR(20) DEFAULT 'pending' CHECK (queue_status IN ('pending', 'processing', 'completed', 'failed', 'retrying')),
ADD COLUMN IF NOT EXISTS last_processed_at TIMESTAMP WITH TIME ZONE;;
