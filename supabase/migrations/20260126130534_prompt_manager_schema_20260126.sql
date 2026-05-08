-- Migration: Internal Prompt Manager
-- Date: 2026-01-26

-- 1. Prompts Table
CREATE TABLE IF NOT EXISTS public.prompts_gestao_projetos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    client_id UUID REFERENCES public.clients_gestao_projetos(id) ON DELETE CASCADE,
    manager_id UUID REFERENCES public.users_gestao_projetos(id) ON DELETE SET NULL, -- Creator
    title TEXT NOT NULL,
    description TEXT,
    format TEXT DEFAULT 'markdown', -- markdown, json, text
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Prompt Versions Table
CREATE TABLE IF NOT EXISTS public.prompt_versions_gestao_projetos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    prompt_id UUID REFERENCES public.prompts_gestao_projetos(id) ON DELETE CASCADE,
    version_number INTEGER NOT NULL,
    content TEXT,
    changelog TEXT,
    is_ai_assisted BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Prompt Templates Table
CREATE TABLE IF NOT EXISTS public.prompt_templates_gestao_projetos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    description TEXT,
    content TEXT,
    category TEXT, -- Sales, Support, etc.
    format TEXT DEFAULT 'markdown',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.prompts_gestao_projetos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.prompt_versions_gestao_projetos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.prompt_templates_gestao_projetos ENABLE ROW LEVEL SECURITY;

-- Standard Policies (Allow all authenticated for now)
DO $$ BEGIN
    CREATE POLICY "Allow all for authenticated" ON public.prompts_gestao_projetos FOR ALL TO public USING (auth.role() = 'authenticated');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
    CREATE POLICY "Allow all for authenticated" ON public.prompt_versions_gestao_projetos FOR ALL TO public USING (auth.role() = 'authenticated');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
    CREATE POLICY "Allow all for authenticated" ON public.prompt_templates_gestao_projetos FOR ALL TO public USING (auth.role() = 'authenticated');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- Indexes
CREATE INDEX IF NOT EXISTS idx_prompts_client_id ON prompts_gestao_projetos(client_id);
CREATE INDEX IF NOT EXISTS idx_prompt_versions_prompt_id ON prompt_versions_gestao_projetos(prompt_id);;
