-- Migration: Create Arsenal Content Platform Schema
-- Description: Sets up tables for Leads, Categories, Contents, Attachments and Storage Bucket.

-- 1. Create ENUM for Content Types
CREATE TYPE content_type_enum AS ENUM ('video', 'pdf', 'link');

-- 2. Create Categories Table
CREATE TABLE categories_arsenal_allblacks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL UNIQUE,
    slug TEXT NOT NULL UNIQUE,
    order_index INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Seed Categories
INSERT INTO categories_arsenal_allblacks (name, slug, order_index) VALUES
('Marketing', 'marketing', 10),
('Vendas', 'vendas', 20),
('Gestão', 'gestao', 30),
('Branding', 'branding', 40),
('Tecnologia', 'tecnologia', 50),
('Outros', 'outros', 100)
ON CONFLICT (slug) DO NOTHING;

-- 3. Create Contents Table
CREATE TABLE contents_arsenal_allblacks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    description TEXT,
    type content_type_enum NOT NULL,
    category_id UUID REFERENCES categories_arsenal_allblacks(id) ON DELETE SET NULL,
    url TEXT NOT NULL,
    thumbnail_url TEXT,
    is_featured BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. Create Attachments Table
CREATE TABLE attachments_arsenal_allblacks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    content_id UUID REFERENCES contents_arsenal_allblacks(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    url TEXT NOT NULL,
    file_type TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5. Create Leads Table
CREATE TABLE leads_arsenal_allblacks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    email TEXT NOT NULL,
    whatsapp TEXT NOT NULL,
    company TEXT,
    url_parameters JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 6. Storage Bucket Setup
INSERT INTO storage.buckets (id, name, public) 
VALUES ('materials_arsenal_allblacks', 'materials_arsenal_allblacks', true)
ON CONFLICT (id) DO NOTHING;

-- Policies for Storage
CREATE POLICY "Public Read Access"
ON storage.objects FOR SELECT
USING ( bucket_id = 'materials_arsenal_allblacks' );

-- 7. Enable RLS
ALTER TABLE leads_arsenal_allblacks ENABLE ROW LEVEL SECURITY;
ALTER TABLE contents_arsenal_allblacks ENABLE ROW LEVEL SECURITY;
ALTER TABLE attachments_arsenal_allblacks ENABLE ROW LEVEL SECURITY;

-- Policies
CREATE POLICY "Public Insert Leads" 
ON leads_arsenal_allblacks FOR INSERT 
WITH CHECK (true);

CREATE POLICY "Public View Contents" 
ON contents_arsenal_allblacks FOR SELECT 
USING (true);

CREATE POLICY "Public View Attachments" 
ON attachments_arsenal_allblacks FOR SELECT 
USING (true);;
