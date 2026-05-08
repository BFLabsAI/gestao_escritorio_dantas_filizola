
-- Add a 'date' column to match Google Ads schema pattern
-- This is an alias/copy of data_referencia for consistency
ALTER TABLE relatorio_metricas_meta ADD COLUMN IF NOT EXISTS date DATE;

-- Populate from existing data_referencia
UPDATE relatorio_metricas_meta SET date = data_referencia WHERE date IS NULL;
;
