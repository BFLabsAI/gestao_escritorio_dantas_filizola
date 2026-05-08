-- Remove duplicate foreign key constraints
ALTER TABLE cargos_banco_talentos_execut 
DROP CONSTRAINT IF EXISTS fk_cargos_setor;

ALTER TABLE candidatos_banco_talentos_execut 
DROP CONSTRAINT IF EXISTS fk_candidatos_cargo;

ALTER TABLE respostas_especificas_banco_talentos_execut 
DROP CONSTRAINT IF EXISTS fk_respostas_candidato;

ALTER TABLE notas_internas_banco_talentos_execut 
DROP CONSTRAINT IF EXISTS fk_notas_candidato;;
