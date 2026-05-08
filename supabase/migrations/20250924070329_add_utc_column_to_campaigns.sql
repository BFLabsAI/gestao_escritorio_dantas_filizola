-- Add UTC scheduled_at column to campaigns table for proper timezone handling
ALTER TABLE campaigns_disparalead 
ADD COLUMN IF NOT EXISTS scheduled_at_utc timestamp with time zone;;
