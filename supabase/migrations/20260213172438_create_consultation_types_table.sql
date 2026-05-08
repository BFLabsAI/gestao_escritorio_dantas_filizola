-- Create consultation types table
CREATE TABLE IF NOT EXISTS consultation_types_evoluxhub (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  icon TEXT NOT NULL DEFAULT 'event',
  color TEXT NOT NULL DEFAULT 'blue',
  duration_minutes INTEGER NOT NULL DEFAULT 30,
  description TEXT,
  is_active BOOLEAN DEFAULT true,
  display_order INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Add index for active types
CREATE INDEX IF NOT EXISTS idx_consultation_types_active ON consultation_types_evoluxhub(is_active, display_order);

-- Enable RLS
ALTER TABLE consultation_types_evoluxhub ENABLE ROW LEVEL SECURITY;

-- Create policy to allow reading consultation types
CREATE POLICY "Allow public read access to consultation types"
  ON consultation_types_evoluxhub
  FOR SELECT
  USING (is_active = true);

-- Create policy to allow authenticated users to manage consultation types
CREATE POLICY "Allow authenticated users to manage consultation types"
  ON consultation_types_evoluxhub
  FOR ALL
  USING (auth.role() = 'authenticated');
;
