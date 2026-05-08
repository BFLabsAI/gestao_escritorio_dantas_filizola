-- Create internal notes table
CREATE TABLE notas_internas_banco_talentos_execut (
    id SERIAL PRIMARY KEY,
    candidato_id UUID REFERENCES candidatos_banco_talentos_execut(id) ON DELETE CASCADE,
    admin_id UUID REFERENCES auth.users(id),
    nota TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for performance
CREATE INDEX idx_notas_candidato_id ON notas_internas_banco_talentos_execut(candidato_id);
CREATE INDEX idx_notas_admin_id ON notas_internas_banco_talentos_execut(admin_id);
CREATE INDEX idx_notas_created_at ON notas_internas_banco_talentos_execut(created_at);;
