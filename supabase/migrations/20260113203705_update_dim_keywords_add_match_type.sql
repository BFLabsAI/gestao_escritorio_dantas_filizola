
-- Add match_type column to dim_keywords
ALTER TABLE relatorio_google_dim_keywords 
ADD COLUMN IF NOT EXISTS match_type TEXT;

-- Add comment explaining the column
COMMENT ON COLUMN relatorio_google_dim_keywords.match_type IS 'Keyword match type: BROAD, PHRASE, or EXACT';
;
