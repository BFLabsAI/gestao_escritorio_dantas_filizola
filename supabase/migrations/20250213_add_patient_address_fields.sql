-- Migration: Add address fields to patients_evoluxhub table
-- Created: 2025-02-13

-- Add address fields to patients_evoluxhub
ALTER TABLE patients_evoluxhub
ADD COLUMN IF NOT EXISTS street TEXT,
ADD COLUMN IF NOT EXISTS number TEXT,
ADD COLUMN IF NOT EXISTS complement TEXT,
ADD COLUMN IF NOT EXISTS neighborhood TEXT,
ADD COLUMN IF NOT EXISTS city TEXT,
ADD COLUMN IF NOT EXISTS state TEXT(2),
ADD COLUMN IF NOT EXISTS zip_code TEXT(9),
ADD COLUMN IF NOT EXISTS country TEXT DEFAULT 'Brasil';
-- Create index for faster city/state searches
CREATE INDEX IF NOT EXISTS idx_patients_city ON patients_evoluxhub(city);
CREATE INDEX IF NOT EXISTS idx_patients_state ON patients_evoluxhub(state);
-- Add comment explaining the fields
COMMENT ON COLUMN patients_evoluxhub.street IS 'Rua/avenida do endereço';
COMMENT ON COLUMN patients_evoluxhub.number IS 'Número do imóvel';
COMMENT ON COLUMN patients_evoluxhub.complement IS 'Complemento (apto, bloco, etc)';
COMMENT ON COLUMN patients_evoluxhub.neighborhood IS 'Bairro';
COMMENT ON COLUMN patients_evoluxhub.city IS 'Cidade';
COMMENT ON COLUMN patients_evoluxhub.state IS 'Estado (UF)';
COMMENT ON COLUMN patients_evoluxhub.zip_code IS 'CEP';
COMMENT ON COLUMN patients_evoluxhub.country IS 'País (padrão: Brasil)';
