-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
-- 1. CATEGORIES TABLE
CREATE TABLE IF NOT EXISTS categories_bflabs_ide_powerup (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    slug TEXT NOT NULL UNIQUE, -- ex: 'mcp-server'
    icon_name TEXT, -- ex: 'lucide-server'
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
-- 2. RESOURCES TABLE
CREATE TABLE IF NOT EXISTS resources_bflabs_ide_powerup (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    category_id UUID REFERENCES categories_bflabs_ide_powerup(id),
    name TEXT NOT NULL, -- ex: 'Vibe Kanban'
    slug TEXT NOT NULL UNIQUE, -- ex: 'vibe-kanban'
    short_description TEXT NOT NULL,
    long_description TEXT,
    author_name TEXT,
    repo_url TEXT,
    website_url TEXT,
    doc_url TEXT,
    is_official BOOLEAN DEFAULT FALSE,
    stars_count INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
-- 3. INSTALLATION METHODS TABLE
CREATE TABLE IF NOT EXISTS installation_methods_bflabs_ide_powerup (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    resource_id UUID REFERENCES resources_bflabs_ide_powerup(id) ON DELETE CASCADE,
    method_type TEXT NOT NULL, -- ENUM: 'npm', 'docker', 'git_clone', 'script', 'plugin'
    scope TEXT NOT NULL, -- ENUM: 'global', 'project', 'standalone'
    command_snippet TEXT NOT NULL,
    description TEXT,
    os_compatibility JSONB DEFAULT '["windows", "mac", "linux"]'::jsonb,
    is_recommended BOOLEAN DEFAULT FALSE
);
-- 4. REQUIREMENTS TABLE
CREATE TABLE IF NOT EXISTS requirements_bflabs_ide_powerup (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    resource_id UUID REFERENCES resources_bflabs_ide_powerup(id) ON DELETE CASCADE,
    tool_name TEXT NOT NULL, -- ex: 'Node.js'
    version_requirement TEXT
);
-- 5. USE CASES TABLE
CREATE TABLE IF NOT EXISTS use_cases_bflabs_ide_powerup (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    resource_id UUID REFERENCES resources_bflabs_ide_powerup(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT NOT NULL
);
-- 6. TAGS TABLE
CREATE TABLE IF NOT EXISTS tags_bflabs_ide_powerup (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL UNIQUE,
    slug TEXT NOT NULL UNIQUE
);
-- 7. RESOURCE TAGS PIVOT TABLE
CREATE TABLE IF NOT EXISTS resource_tags_bflabs_ide_powerup (
    resource_id UUID REFERENCES resources_bflabs_ide_powerup(id) ON DELETE CASCADE,
    tag_id UUID REFERENCES tags_bflabs_ide_powerup(id) ON DELETE CASCADE,
    PRIMARY KEY (resource_id, tag_id)
);
