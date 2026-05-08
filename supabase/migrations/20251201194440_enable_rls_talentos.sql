ALTER TABLE vagas_banco_talentos_execut ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public Access Vagas" ON vagas_banco_talentos_execut FOR ALL USING (true) WITH CHECK (true);

ALTER TABLE candidatos_banco_talentos_execut ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public Access Candidatos" ON candidatos_banco_talentos_execut FOR ALL USING (true) WITH CHECK (true);

ALTER TABLE inscricoes_banco_talentos_execut ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public Access Inscricoes" ON inscricoes_banco_talentos_execut FOR ALL USING (true) WITH CHECK (true);

ALTER TABLE setores_banco_talentos_execut ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public Access Setores" ON setores_banco_talentos_execut FOR ALL USING (true) WITH CHECK (true);

ALTER TABLE generated_images_banco_talentos_execut ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public Access Images" ON generated_images_banco_talentos_execut FOR ALL USING (true) WITH CHECK (true);;
