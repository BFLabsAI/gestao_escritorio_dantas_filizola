-- ============================================================
-- Agente Editorial - Initial Schema
-- Multi-user MVP (no Supabase Auth — simple users table)
-- Documents/files are shared; edits are personal per user
-- NOTE: Password stored as plain text — NOT safe for production
-- ============================================================

CREATE TABLE public.users_agente_editorial (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email       TEXT NOT NULL UNIQUE,
    password    TEXT NOT NULL,
    display_name TEXT,
    avatar_url  TEXT,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE public.documents_agente_editorial (
    id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title                 TEXT NOT NULL,
    current_version_index INTEGER NOT NULL DEFAULT 0,
    is_reference          BOOLEAN NOT NULL DEFAULT FALSE,
    created_by            UUID REFERENCES public.users_agente_editorial(id) ON DELETE SET NULL,
    created_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at            TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE public.document_versions_agente_editorial (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    document_id UUID NOT NULL REFERENCES public.documents_agente_editorial(id) ON DELETE CASCADE,
    user_id     UUID NOT NULL REFERENCES public.users_agente_editorial(id) ON DELETE CASCADE,
    content     TEXT NOT NULL,
    author      TEXT CHECK (author IN ('user', 'ai')),
    summary     TEXT,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE public.document_suggestions_agente_editorial (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    document_id UUID NOT NULL REFERENCES public.documents_agente_editorial(id) ON DELETE CASCADE,
    user_id     UUID NOT NULL REFERENCES public.users_agente_editorial(id) ON DELETE CASCADE,
    original    TEXT NOT NULL,
    proposed    TEXT NOT NULL,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE public.chats_agente_editorial (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id    UUID NOT NULL REFERENCES public.users_agente_editorial(id) ON DELETE CASCADE,
    title      TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE public.chat_messages_agente_editorial (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    chat_id    UUID NOT NULL REFERENCES public.chats_agente_editorial(id) ON DELETE CASCADE,
    role       TEXT NOT NULL CHECK (role IN ('user', 'assistant')),
    content    TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE public.chat_message_suggestions_agente_editorial (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    message_id UUID NOT NULL REFERENCES public.chat_messages_agente_editorial(id) ON DELETE CASCADE,
    original   TEXT NOT NULL,
    proposed   TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

INSERT INTO storage.buckets (id, name, public)
VALUES ('documents_agente_editorial', 'documents_agente_editorial', false)
ON CONFLICT (id) DO NOTHING;

CREATE OR REPLACE FUNCTION public.update_updated_at_column_agente_editorial()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_users_updated_at_agente_editorial
    BEFORE UPDATE ON public.users_agente_editorial
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at_column_agente_editorial();

CREATE TRIGGER update_documents_updated_at_agente_editorial
    BEFORE UPDATE ON public.documents_agente_editorial
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at_column_agente_editorial();

CREATE TRIGGER update_chats_updated_at_agente_editorial
    BEFORE UPDATE ON public.chats_agente_editorial
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at_column_agente_editorial();;
