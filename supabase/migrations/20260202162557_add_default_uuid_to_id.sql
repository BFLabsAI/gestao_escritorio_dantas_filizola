-- Adicionar valor padrão para gerar UUID automaticamente
ALTER TABLE users_itarget_api ALTER COLUMN id SET DEFAULT gen_random_uuid();;
