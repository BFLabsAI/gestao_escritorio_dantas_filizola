-- Abordagem: Manter person_id nas tabelas relacionadas sem FK (apenas índice)
-- Isso permite criar user sem person_id, mas manter compatibilidade com API

-- Primeiro, remover as FKs que dependem de person_id (vamos usar apenas índices)
ALTER TABLE events_itarget_api DROP CONSTRAINT IF EXISTS fk_events_person_id;

-- Agora podemos mudar a primary key de users_itarget_api
ALTER TABLE users_itarget_api DROP CONSTRAINT users_itarget_api_pkey;

-- Adicionar PK no id
ALTER TABLE users_itarget_api ADD PRIMARY KEY (id);

-- Agora person_id pode ser nullable
ALTER TABLE users_itarget_api ALTER COLUMN person_id DROP NOT NULL;

-- Adicionar índice único em person_id (para performance e unicidade prática)
CREATE UNIQUE INDEX idx_users_itarget_api_person_id ON users_itarget_api(person_id) WHERE person_id IS NOT NULL;

-- Recriar FK para subscriptions que aponta para person_id via índice (não PK)
-- Nota: PostgreSQL não permite FK apontar para coluna sem PK/UNIQUE, então vamos deixar sem FK
-- A aplicação deve garantir a integridade;
