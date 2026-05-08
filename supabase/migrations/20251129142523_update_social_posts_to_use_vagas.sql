-- Atualizar social_posts para usar vagas em vez de cargos antigos

-- 1. Adicionar nova coluna vaga_id
ALTER TABLE social_posts_banco_talentos_execut ADD COLUMN IF NOT EXISTS vaga_id INTEGER;

-- 2. Atualizar os registros para mapear cargo_id -> vaga_id (mapeamento baseado nos dados que migramos)
UPDATE social_posts_banco_talentos_execut SET vaga_id = CASE 
    WHEN cargo_id = 1 THEN 1  -- SDR/BDR -> SDR/BDR
    WHEN cargo_id = 2 THEN 2  -- Closer -> Closer  
    WHEN cargo_id = 3 THEN 3  -- Social Media -> Social Media
    WHEN cargo_id = 4 THEN 4  -- Filmmaker -> Filmmaker
    WHEN cargo_id = 5 THEN 5  -- Designer -> Designer
    WHEN cargo_id = 12 THEN 12 -- Desenvolvedor Front-end -> Desenvolvedor Front-end
    ELSE NULL
END WHERE vaga_id IS NULL;

-- 3. Criar nova foreign key constraint
ALTER TABLE social_posts_banco_talentos_execut 
ADD CONSTRAINT social_posts_vaga_id_fkey 
FOREIGN KEY (vaga_id) REFERENCES vagas_banco_talentos_execut(id) ON DELETE SET NULL;

-- 4. Remover a foreign key antiga
ALTER TABLE social_posts_banco_talentos_execut DROP CONSTRAINT IF EXISTS social_posts_banco_talentos_execut_cargo_id_fkey;

-- 5. Remover coluna antiga
ALTER TABLE social_posts_banco_talentos_execut DROP COLUMN IF EXISTS cargo_id;;
