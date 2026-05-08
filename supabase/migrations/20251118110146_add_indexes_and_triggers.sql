-- Add indexes for better performance
CREATE INDEX IF NOT EXISTS idx_cargos_setor_id ON cargos_banco_talentos_execut(setor_id);
CREATE INDEX IF NOT EXISTS idx_candidatos_cargo_id ON candidatos_banco_talentos_execut(cargo_id);
CREATE INDEX IF NOT EXISTS idx_candidatos_status ON candidatos_banco_talentos_execut(status);
CREATE INDEX IF NOT EXISTS idx_candidatos_pretensao_salarial ON candidatos_banco_talentos_execut(pretensao_salarial);
CREATE INDEX IF NOT EXISTS idx_candidatos_email ON candidatos_banco_talentos_execut(email);
CREATE INDEX IF NOT EXISTS idx_respostas_candidato_id ON respostas_especificas_banco_talentos_execut(candidato_id);
CREATE INDEX IF NOT EXISTS idx_notas_candidato_id ON notas_internas_banco_talentos_execut(candidato_id);
CREATE INDEX IF NOT EXISTS idx_notas_admin_id ON notas_internas_banco_talentos_execut(admin_id);

-- Create or replace updated_at function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Drop existing triggers if they exist
DROP TRIGGER IF EXISTS update_setores_updated_at ON setores_banco_talentos_execut;
DROP TRIGGER IF EXISTS update_cargos_updated_at ON cargos_banco_talentos_execut;
DROP TRIGGER IF EXISTS update_candidatos_updated_at ON candidatos_banco_talentos_execut;

-- Add updated_at triggers
CREATE TRIGGER update_setores_updated_at BEFORE UPDATE ON setores_banco_talentos_execut FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_cargos_updated_at BEFORE UPDATE ON cargos_banco_talentos_execut FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_candidatos_updated_at BEFORE UPDATE ON candidatos_banco_talentos_execut FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();;
