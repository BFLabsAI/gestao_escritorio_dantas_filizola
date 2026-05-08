-- Clean up duplicate channels (keep only the first one per project)
DELETE FROM channels_gestao_projetos 
WHERE id NOT IN (
  SELECT DISTINCT ON (project_id, type) id 
  FROM channels_gestao_projetos 
  ORDER BY project_id, type, created_at ASC
);

-- Add unique constraint to prevent future duplicates
ALTER TABLE channels_gestao_projetos 
ADD CONSTRAINT unique_project_channel UNIQUE (project_id, type);

-- Create documents table for docs/wiki feature
CREATE TABLE IF NOT EXISTS documents_gestao_projetos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id UUID REFERENCES projects_gestao_projetos(id) ON DELETE CASCADE,
  parent_id UUID REFERENCES documents_gestao_projetos(id) ON DELETE SET NULL,
  title TEXT NOT NULL DEFAULT 'Sem título',
  content JSONB DEFAULT '{}',
  doc_type TEXT NOT NULL DEFAULT 'page' CHECK (doc_type IN ('page', 'board')),
  order_index INTEGER DEFAULT 0,
  created_by UUID REFERENCES users_gestao_projetos(id),
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Create whiteboard_nodes table
CREATE TABLE IF NOT EXISTS whiteboard_nodes_gestao_projetos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id UUID REFERENCES projects_gestao_projetos(id) ON DELETE CASCADE,
  document_id UUID REFERENCES documents_gestao_projetos(id) ON DELETE CASCADE,
  node_id TEXT NOT NULL,
  type TEXT NOT NULL DEFAULT 'default',
  position_x DOUBLE PRECISION NOT NULL DEFAULT 0,
  position_y DOUBLE PRECISION NOT NULL DEFAULT 0,
  width DOUBLE PRECISION,
  height DOUBLE PRECISION,
  data JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Create whiteboard_edges table
CREATE TABLE IF NOT EXISTS whiteboard_edges_gestao_projetos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id UUID REFERENCES projects_gestao_projetos(id) ON DELETE CASCADE,
  document_id UUID REFERENCES documents_gestao_projetos(id) ON DELETE CASCADE,
  edge_id TEXT NOT NULL,
  source_node_id TEXT NOT NULL,
  target_node_id TEXT NOT NULL,
  type TEXT DEFAULT 'smoothstep',
  data JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_documents_project ON documents_gestao_projetos(project_id);
CREATE INDEX IF NOT EXISTS idx_documents_parent ON documents_gestao_projetos(parent_id);
CREATE INDEX IF NOT EXISTS idx_whiteboard_nodes_project ON whiteboard_nodes_gestao_projetos(project_id);
CREATE INDEX IF NOT EXISTS idx_whiteboard_nodes_document ON whiteboard_nodes_gestao_projetos(document_id);
CREATE INDEX IF NOT EXISTS idx_whiteboard_edges_project ON whiteboard_edges_gestao_projetos(project_id);
CREATE INDEX IF NOT EXISTS idx_whiteboard_edges_document ON whiteboard_edges_gestao_projetos(document_id);;
