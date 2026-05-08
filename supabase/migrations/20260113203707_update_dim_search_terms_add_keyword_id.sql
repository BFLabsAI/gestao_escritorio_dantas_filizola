
-- Add keyword_id column to dim_search_terms for drill-down link
ALTER TABLE relatorio_google_dim_search_terms 
ADD COLUMN IF NOT EXISTS keyword_id BIGINT REFERENCES relatorio_google_dim_keywords(id);

-- Add comment explaining the column
COMMENT ON COLUMN relatorio_google_dim_search_terms.keyword_id IS 'Foreign key to the keyword that triggered this search term';

-- Create index for faster lookups
CREATE INDEX IF NOT EXISTS idx_dim_search_terms_keyword_id 
ON relatorio_google_dim_search_terms(keyword_id);
;
