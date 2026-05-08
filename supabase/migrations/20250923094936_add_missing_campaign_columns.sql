-- Add missing columns to campaigns_disparalead table
ALTER TABLE campaigns_disparalead 
ADD COLUMN IF NOT EXISTS config jsonb,
ADD COLUMN IF NOT EXISTS total_contacts integer DEFAULT 0,
ADD COLUMN IF NOT EXISTS completed_at timestamp with time zone,
ADD COLUMN IF NOT EXISTS metrics jsonb,
ADD COLUMN IF NOT EXISTS created_by uuid REFERENCES auth.users(id),
ADD COLUMN IF NOT EXISTS updated_at timestamp with time zone DEFAULT NOW();

-- Update existing records to have empty config if null
UPDATE campaigns_disparalead SET config = '{}' WHERE config IS NULL;;
