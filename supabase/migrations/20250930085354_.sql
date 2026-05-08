-- Add cadencia_id to leads_rastreialead
ALTER TABLE leads_rastreialead 
ADD COLUMN cadencia_id uuid REFERENCES cadencias_rastreialead(id);

-- Set default cadencia for existing leads (use the first active cadence)
UPDATE leads_rastreialead 
SET cadencia_id = (
  SELECT id 
  FROM cadencias_rastreialead 
  WHERE ativa = true 
  ORDER BY created_at ASC 
  LIMIT 1
)
WHERE cadencia_id IS NULL;;
