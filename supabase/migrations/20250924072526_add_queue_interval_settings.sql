-- Add queue interval settings to campaigns
ALTER TABLE campaigns_disparalead 
ADD COLUMN IF NOT EXISTS queue_interval_preset TEXT DEFAULT '30s',
ADD COLUMN IF NOT EXISTS queue_interval_min INTEGER DEFAULT 20,
ADD COLUMN IF NOT EXISTS queue_interval_max INTEGER DEFAULT 40;

-- Create index for efficient querying
CREATE INDEX IF NOT EXISTS idx_campaigns_queue_settings 
ON campaigns_disparalead(queue_interval_preset);;
