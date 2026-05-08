-- Criar tabela para armazenar imagens geradas pelo módulo de gerador
CREATE TABLE IF NOT EXISTS generated_images_banco_talentos_execut (
    id SERIAL PRIMARY KEY,
    job_id INTEGER NOT NULL,
    template_id VARCHAR(50) NOT NULL,
    image_url TEXT NOT NULL,
    extra_text TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Criar índices para melhor performance
CREATE INDEX IF NOT EXISTS idx_generated_images_job_id ON generated_images_banco_talentos_execut(job_id);
CREATE INDEX IF NOT EXISTS idx_generated_images_template_id ON generated_images_banco_talentos_execut(template_id);
CREATE INDEX IF NOT EXISTS idx_generated_images_created_at ON generated_images_banco_talentos_execut(created_at);

-- Trigger para updated_at
CREATE OR REPLACE FUNCTION trigger_set_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS set_generated_images_timestamp ON generated_images_banco_talentos_execut;
CREATE TRIGGER set_generated_images_timestamp
BEFORE UPDATE ON generated_images_banco_talentos_execut
FOR EACH ROW EXECUTE FUNCTION trigger_set_timestamp();;
