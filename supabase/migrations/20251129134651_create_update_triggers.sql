-- Create update triggers for all tables
CREATE OR REPLACE FUNCTION trigger_set_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply triggers to tables that have updated_at
DROP TRIGGER IF EXISTS set_vagas_timestamp ON vagas_banco_talentos_execut;
CREATE TRIGGER set_vagas_timestamp
BEFORE UPDATE ON vagas_banco_talentos_execut
FOR EACH ROW EXECUTE FUNCTION trigger_set_timestamp();

DROP TRIGGER IF EXISTS set_candidatos_timestamp ON candidatos_banco_talentos_execut;
CREATE TRIGGER set_candidatos_timestamp
BEFORE UPDATE ON candidatos_banco_talentos_execut
FOR EACH ROW EXECUTE FUNCTION trigger_set_timestamp();

DROP TRIGGER IF EXISTS set_inscricoes_timestamp ON inscricoes_banco_talentos_execut;
CREATE TRIGGER set_inscricoes_timestamp
BEFORE UPDATE ON inscricoes_banco_talentos_execut
FOR EACH ROW EXECUTE FUNCTION trigger_set_timestamp();

DROP TRIGGER IF EXISTS set_setores_timestamp ON setores_banco_talentos_execut;
CREATE TRIGGER set_setores_timestamp
BEFORE UPDATE ON setores_banco_talentos_execut
FOR EACH ROW EXECUTE FUNCTION trigger_set_timestamp();;
