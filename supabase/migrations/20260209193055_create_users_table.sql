CREATE TABLE IF NOT EXISTS userleadsinfinite (
    id BIGSERIAL PRIMARY KEY,
    email TEXT NOT NULL UNIQUE,
    senha TEXT NOT NULL,
    nome TEXT,
    status TEXT DEFAULT 'ativo',
    plano TEXT DEFAULT 'básico',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create index on email for faster lookups
CREATE INDEX IF NOT EXISTS idx_userleadsinfinite_email ON userleadsinfinite(email);

-- Create index on status for filtering active users
CREATE INDEX IF NOT EXISTS idx_userleadsinfinite_status ON userleadsinfinite(status);;
