-- Drop existing constraints if they exist and recreate them
DO $$
BEGIN
    -- Drop foreign key constraints if they exist
    IF EXISTS (SELECT 1 FROM information_schema.table_constraints WHERE constraint_name = 'fk_cargos_setor') THEN
        ALTER TABLE cargos_banco_talentos_execut DROP CONSTRAINT fk_cargos_setor;
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.table_constraints WHERE constraint_name = 'fk_candidatos_cargo') THEN
        ALTER TABLE candidatos_banco_talentos_execut DROP CONSTRAINT fk_candidatos_cargo;
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.table_constraints WHERE constraint_name = 'fk_respostas_candidato') THEN
        ALTER TABLE respostas_especificas_banco_talentos_execut DROP CONSTRAINT fk_respostas_candidato;
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.table_constraints WHERE constraint_name = 'fk_notas_candidato') THEN
        ALTER TABLE notas_internas_banco_talentos_execut DROP CONSTRAINT fk_notas_candidato;
    END IF;
END $$;

-- Add foreign key constraints for data integrity
ALTER TABLE cargos_banco_talentos_execut 
ADD CONSTRAINT fk_cargos_setor 
FOREIGN KEY (setor_id) REFERENCES setores_banco_talentos_execut(id) ON DELETE CASCADE;

ALTER TABLE candidatos_banco_talentos_execut 
ADD CONSTRAINT fk_candidatos_cargo 
FOREIGN KEY (cargo_id) REFERENCES cargos_banco_talentos_execut(id) ON DELETE SET NULL;

ALTER TABLE respostas_especificas_banco_talentos_execut 
ADD CONSTRAINT fk_respostas_candidato 
FOREIGN KEY (candidato_id) REFERENCES candidatos_banco_talentos_execut(id) ON DELETE CASCADE;

ALTER TABLE notas_internas_banco_talentos_execut 
ADD CONSTRAINT fk_notas_candidato 
FOREIGN KEY (candidato_id) REFERENCES candidatos_banco_talentos_execut(id) ON DELETE CASCADE;;
