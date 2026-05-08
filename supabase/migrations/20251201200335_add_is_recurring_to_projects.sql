ALTER TABLE projects_gestao_projetos 
ADD COLUMN IF NOT EXISTS is_recurring boolean DEFAULT false;;
