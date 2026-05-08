-- Remover foreign key constraint para permitir uso com vendedores_rastreia_prospect
ALTER TABLE mensagens_rastreia_prospect DROP CONSTRAINT IF EXISTS mensagens_rastreia_prospect_instancia_id_fkey;;
