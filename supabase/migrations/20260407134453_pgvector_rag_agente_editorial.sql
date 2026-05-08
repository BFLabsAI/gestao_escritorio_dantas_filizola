-- Enable pgvector
CREATE EXTENSION IF NOT EXISTS vector;

-- Document chunks for RAG
CREATE TABLE public.document_chunks_agente_editorial (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  document_id  UUID NOT NULL REFERENCES public.documents_agente_editorial(id) ON DELETE CASCADE,
  version_id   UUID REFERENCES public.document_versions_agente_editorial(id) ON DELETE SET NULL,
  user_id      UUID NOT NULL REFERENCES public.users_agente_editorial(id) ON DELETE CASCADE,
  chunk_index  INTEGER NOT NULL,
  heading      TEXT,
  content      TEXT NOT NULL,
  embedding    vector(1536),
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX ON public.document_chunks_agente_editorial
  USING ivfflat (embedding vector_cosine_ops)
  WITH (lists = 100);

CREATE INDEX ON public.document_chunks_agente_editorial (document_id, user_id);

-- Similarity search RPC
CREATE OR REPLACE FUNCTION public.search_chunks_agente_editorial(
  query_embedding vector(1536),
  p_document_id   UUID,
  p_user_id       UUID,
  p_count         INT DEFAULT 3
)
RETURNS TABLE (
  id          UUID,
  chunk_index INT,
  heading     TEXT,
  content     TEXT,
  similarity  FLOAT
)
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT
    c.id,
    c.chunk_index,
    c.heading,
    c.content,
    1 - (c.embedding <=> query_embedding) AS similarity
  FROM public.document_chunks_agente_editorial c
  WHERE c.document_id = p_document_id
    AND c.user_id = p_user_id
    AND c.embedding IS NOT NULL
  ORDER BY c.embedding <=> query_embedding
  LIMIT p_count;
END;
$$;;
