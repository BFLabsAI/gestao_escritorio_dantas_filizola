-- Create candidates table
CREATE TABLE candidatos_banco_talentos_execut (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    nome TEXT NOT NULL,
    email TEXT NOT NULL UNIQUE,
    telefone TEXT,
    linkedin_url TEXT,
    cargo_id INTEGER REFERENCES cargos_banco_talentos_execut(id),
    pretensao_salarial NUMERIC(10, 2),
    experiencia TEXT,
    motivacao TEXT,
    melhor_skill TEXT,
    pior_skill TEXT,
    desafio_resolvido TEXT,
    status TEXT DEFAULT 'Novo Currículo',
    alocacao TEXT,
    cliente_alocado TEXT,
    cv_url TEXT,
    tipo_cv TEXT CHECK (tipo_cv IN ('link', 'file')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for performance
CREATE INDEX idx_candidatos_email ON candidatos_banco_talentos_execut(email);
CREATE INDEX idx_candidatos_status ON candidatos_banco_talentos_execut(status);
CREATE INDEX idx_candidatos_cargo_id ON candidatos_banco_talentos_execut(cargo_id);
CREATE INDEX idx_candidatos_created_at ON candidatos_banco_talentos_execut(created_at);

-- Create trigger to automatically update updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_candidatos_updated_at BEFORE UPDATE
    ON candidatos_banco_talentos_execut FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();;
