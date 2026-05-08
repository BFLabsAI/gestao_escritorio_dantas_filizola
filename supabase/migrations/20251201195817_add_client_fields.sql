ALTER TABLE clients_gestao_projetos 
ADD COLUMN IF NOT EXISTS segment text,
ADD COLUMN IF NOT EXISTS revenue numeric,
ADD COLUMN IF NOT EXISTS status text;;
