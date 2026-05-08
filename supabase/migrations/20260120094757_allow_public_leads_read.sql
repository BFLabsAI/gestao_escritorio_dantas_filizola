-- Allow public read access to leads (TEMPORARY: FOR DEV DASHBOARD WITHOUT AUTH)
CREATE POLICY "Public Read Leads"
ON leads_arsenal_allblacks
FOR SELECT
TO public
USING (true);;
