ALTER TABLE empreendimentos_imobiliaria_rogaciano 
ADD COLUMN IF NOT EXISTS opcoes_extra jsonb DEFAULT '[]'::jsonb;;
