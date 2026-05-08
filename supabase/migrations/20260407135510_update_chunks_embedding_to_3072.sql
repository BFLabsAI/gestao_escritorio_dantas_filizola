-- Drop the existing search function (depends on vector type)
DROP FUNCTION IF EXISTS search_chunks_agente_editorial(vector, uuid, uuid, integer);

-- Drop the IVFFlat index if it exists (incompatible with new dimension)
DROP INDEX IF EXISTS document_chunks_agente_editorial_embedding_idx;

-- Alter the embedding column from vector(1536) to vector(3072)
ALTER TABLE document_chunks_agente_editorial
  ALTER COLUMN embedding TYPE vector(3072)
  USING NULL;  -- existing rows get NULL since old embeddings are incompatible

-- Recreate the search function with the new vector dimension
CREATE OR REPLACE FUNCTION search_chunks_agente_editorial(
  query_embedding vector(3072),
  p_document_id UUID,
  p_user_id UUID,
  p_count INT DEFAULT 3
)
RETURNS TABLE (id UUID, chunk_index INT, heading TEXT, content TEXT, similarity FLOAT)
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
$$;
;
