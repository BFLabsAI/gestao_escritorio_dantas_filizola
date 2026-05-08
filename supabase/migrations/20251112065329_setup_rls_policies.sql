-- Enable RLS on sectors table
ALTER TABLE setores_banco_talentos_execut ENABLE ROW LEVEL SECURITY;

-- Sectors table policies
-- Authenticated users can read sectors
CREATE POLICY "Authenticated users can read sectors" ON setores_banco_talentos_execut
    FOR SELECT USING (auth.role() = 'authenticated');

-- Enable RLS on positions table
ALTER TABLE cargos_banco_talentos_execut ENABLE ROW LEVEL SECURITY;

-- Positions table policies
-- Authenticated users can read positions
CREATE POLICY "Authenticated users can read positions" ON cargos_banco_talentos_execut
    FOR SELECT USING (auth.role() = 'authenticated');

-- Enable RLS on candidates table
ALTER TABLE candidatos_banco_talentos_execut ENABLE ROW LEVEL SECURITY;

-- Candidates table policies
-- Public can insert candidates (form submissions)
CREATE POLICY "Public insert candidates" ON candidatos_banco_talentos_execut
    FOR INSERT WITH CHECK (true);

-- Authenticated users can read candidates
CREATE POLICY "Admins can read candidates" ON candidatos_banco_talentos_execut
    FOR SELECT USING (auth.role() = 'authenticated');

-- Authenticated users can update candidates
CREATE POLICY "Admins can update candidates" ON candidatos_banco_talentos_execut
    FOR UPDATE USING (auth.role() = 'authenticated');

-- Authenticated users can delete candidates
CREATE POLICY "Admins can delete candidates" ON candidatos_banco_talentos_execut
    FOR DELETE USING (auth.role() = 'authenticated');

-- Enable RLS on specific responses table
ALTER TABLE respostas_especificas_banco_talentos_execut ENABLE ROW LEVEL SECURITY;

-- Specific responses table policies
-- Public can insert responses
CREATE POLICY "Public insert responses" ON respostas_especificas_banco_talentos_execut
    FOR INSERT WITH CHECK (true);

-- Authenticated users can read responses
CREATE POLICY "Admins can read responses" ON respostas_especificas_banco_talentos_execut
    FOR SELECT USING (auth.role() = 'authenticated');

-- Authenticated users can update responses
CREATE POLICY "Admins can update responses" ON respostas_especificas_banco_talentos_execut
    FOR UPDATE USING (auth.role() = 'authenticated');

-- Enable RLS on internal notes table
ALTER TABLE notas_internas_banco_talentos_execut ENABLE ROW LEVEL SECURITY;

-- Internal notes table policies
-- Only authenticated users can manage notes
CREATE POLICY "Admins can manage notes" ON notas_internas_banco_talentos_execut
    FOR ALL USING (auth.role() = 'authenticated');;
