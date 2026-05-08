
-- Enable RLS on the new fact table
ALTER TABLE relatorio_google_fact_search_term_performance ENABLE ROW LEVEL SECURITY;

-- Allow anon users to read (for dashboard)
CREATE POLICY "Allow anon read on fact_search_term_performance"
ON relatorio_google_fact_search_term_performance
FOR SELECT
TO anon
USING (true);

-- Allow anon users to insert (for Edge Function)
CREATE POLICY "Allow anon insert on fact_search_term_performance"
ON relatorio_google_fact_search_term_performance
FOR INSERT
TO anon
WITH CHECK (true);

-- Allow service_role full access
CREATE POLICY "Allow service_role all on fact_search_term_performance"
ON relatorio_google_fact_search_term_performance
FOR ALL
TO service_role
USING (true)
WITH CHECK (true);
;
