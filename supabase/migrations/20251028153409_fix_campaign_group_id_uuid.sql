-- Fix campaign_group_id column - generate UUID for existing records

-- Add column if it doesn't exist
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'agendamentos_disparador_r7_treinamentos' 
    AND column_name = 'campaign_group_id'
  ) THEN
    ALTER TABLE agendamentos_disparador_r7_treinamentos 
    ADD COLUMN campaign_group_id UUID DEFAULT gen_random_uuid();
  END IF;
END $$;

-- Update any existing NULL records with generated UUIDs
UPDATE agendamentos_disparador_r7_treinamentos 
SET campaign_group_id = gen_random_uuid() 
WHERE campaign_group_id IS NULL;

-- Set column to be NOT NULL
ALTER TABLE agendamentos_disparador_r7_treinamentos 
ALTER COLUMN campaign_group_id SET NOT NULL;;
