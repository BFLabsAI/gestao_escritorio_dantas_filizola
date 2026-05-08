-- Criar tabela catalog_files
CREATE TABLE IF NOT EXISTS catalog_files (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nome_arquivo VARCHAR(255) NOT NULL,
    tipo VARCHAR(50) NOT NULL CHECK (tipo IN ('catalogo', 'prova_social', 'guia_medidas', 'geral')),
    file_url TEXT NOT NULL,
    file_path TEXT NOT NULL,
    file_size BIGINT,
    mime_type VARCHAR(100),
    ativo BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Criar índices
CREATE INDEX IF NOT EXISTS idx_catalog_files_tipo ON catalog_files(tipo);
CREATE INDEX IF NOT EXISTS idx_catalog_files_ativo ON catalog_files(ativo);
CREATE INDEX IF NOT EXISTS idx_catalog_files_created_at ON catalog_files(created_at DESC);

-- Habilitar RLS
ALTER TABLE catalog_files ENABLE ROW LEVEL SECURITY;

-- Policies
DROP POLICY IF EXISTS "Permitir leitura publica para arquivos ativos" ON catalog_files;
CREATE POLICY "Permitir leitura publica para arquivos ativos"
ON catalog_files FOR SELECT
USING (ativo = true);

DROP POLICY IF EXISTS "Permitir todas operacoes admin" ON catalog_files;
CREATE POLICY "Permitir todas operacoes admin"
ON catalog_files FOR ALL
USING (true);;
