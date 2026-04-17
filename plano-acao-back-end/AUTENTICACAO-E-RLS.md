# Plano de Autenticacao e RLS - Gestao Escritorio Dantas Filizola

> **Status atual (MVP):** RLS desabilitado em TODAS as tabelas e storage buckets. Sem pagina de login. Qualquer pessoa com a URL tem acesso total.
>
> **Objetivo:** Documentar como reabilitar a seguranca apos validacao do MVP.

---

## 1. Tabelas do Banco de Dados

### Tabelas do escritorio (schema: `public`, prefixo `gestao_escritorio_filizola`)

| Tabela | RLS Original | Status Atual | Acesso Futuro |
|--------|-------------|-------------|---------------|
| `perfis_gestao_escritorio_filizola` | ENABLED (scoped: proprio perfil) | **DISABLED** | Usuario so ve/edita o proprio perfil (`auth.uid() = user_id`) |
| `clientes_gestao_escritorio_filizola` | ENABLED (authenticated: true) | **DISABLED** | Authenticated: CRUD total |
| `processos_gestao_escritorio_filizola` | ENABLED (authenticated: true) | **DISABLED** | Authenticated: CRUD total |
| `documentos_gestao_escritorio_filizola` | ENABLED (authenticated: true) | **DISABLED** | Authenticated: CRUD total |
| `historico_inss_gestao_escritorio_filizola` | ENABLED (authenticated: true) | **DISABLED** | Authenticated: CRUD total |
| `exigencias_doc_gestao_escritorio_filizola` | ENABLED (authenticated: true) | **DISABLED** | Authenticated: SELECT. Admin: INSERT/UPDATE/DELETE |
| `notificacoes_gestao_escritorio_filizola` | ENABLED (authenticated: true) | **DISABLED** | Authenticated: SELECT/INSERT. Admin: UPDATE/DELETE |
| `dados_extraidos_gestao_escritorio_filizola` | ENABLED (authenticated: true) | **DISABLED** | Authenticated: CRUD total |
| `peticoes_geradas_gestao_escritorio_filizola` | NUNCA teve RLS (default off) | **DISABLED** | Authenticated: CRUD total |
| `comentarios_clientes_gestao_escritorio_filizola` | ENABLED (migration criou com RLS + policies) | **DISABLED (MVP)** | Authenticated: INSERT/SELECT/DELETE. Usuario so pode deletar proprios comentarios |
| `comentarios_processos_gestao_escritorio_filizola` | ENABLED (migration criou com RLS + policy MVP) | **DISABLED (MVP)** | Authenticated: INSERT/SELECT/DELETE. Usuario so pode deletar proprios comentarios |

### Tabelas de modelos (schema: `public`)

| Tabela | RLS Original | Status Atual | Acesso Futuro |
|--------|-------------|-------------|---------------|
| `modelos_dantas_filizola` | DISABLED (explicito na migration) | DISABLED | Authenticated: SELECT. Admin: INSERT/UPDATE/DELETE |

---

## 2. Colunas Adicionadas (MVP expandido)

| Tabela | Coluna | Tipo | Migration | Descricao |
|--------|--------|------|-----------|-----------|
| `clientes_gestao_escritorio_filizola` | `sexo` | TEXT (CHECK: masculino/feminino/nao_informado) | `20260417000001` | Sexo do cliente para adaptacao de genero em peticoes |
| `modelos_dantas_filizola` | `variaveis_customizadas` | JSONB (default: []) | `20260417000003` | Variaveis customizadas por template (ex: escola, profissao) |

---

## 3. Storage Buckets (Supabase Storage)

| Bucket | Publico | Status Atual | Acesso Futuro |
|--------|---------|-------------|---------------|
| `documentos_processuais` | Nao | **Anon** (sem auth) | Authenticated: INSERT/SELECT/DELETE |
| `peticoes_geradas` | Nao | **Anon** (sem auth) | Authenticated: INSERT/UPDATE/SELECT/DELETE |
| `modelos_dantas_filizola` | Sim | Sem policies (public) | Manter public (leitura) + Authenticated: INSERT/UPDATE/DELETE |

---

## 4. Migration para Reabilitar RLS (pos-MVP)

A migration `20260414140000_disable_all_rls.sql` desabilitou RLS nas 7 tabelas originais.
A migration `20260417000002` criou `comentarios_clientes_gestao_escritorio_filizola` com RLS, que foi desabilitado manualmente para o MVP.
A migration `20260417000004` criou `comentarios_processos_gestao_escritorio_filizola` com RLS + policy MVP.

Para reabilitar, criar migration com:

```sql
-- Reabilitar RLS nas tabelas do gestao_escritorio
ALTER TABLE public.perfis_gestao_escritorio_filizola ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.clientes_gestao_escritorio_filizola ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.processos_gestao_escritorio_filizola ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.documentos_gestao_escritorio_filizola ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.historico_inss_gestao_escritorio_filizola ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.exigencias_doc_gestao_escritorio_filizola ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notificacoes_gestao_escritorio_filizola ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.dados_extraidos_gestao_escritorio_filizola ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.peticoes_geradas_gestao_escritorio_filizola ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.modelos_dantas_filizola ENABLE ROW LEVEL SECURITY;

-- Reabilitar RLS nas tabelas de comentarios
ALTER TABLE public.comentarios_clientes_gestao_escritorio_filizola ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.comentarios_processos_gestao_escritorio_filizola ENABLE ROW LEVEL SECURITY;

-- Recriar policies (as originais estao em 20260408194102_initial_schema.sql)
-- Verificar se as policies originais ainda existem com:
-- SELECT policyname, tablename FROM pg_policies WHERE schemaname = 'public';
-- Se existirem, so reabilitar RLS. Se nao, recriar.

-- Remover politicas temporarias do MVP
DROP POLICY "Permitir tudo comentarios_clientes MVP" ON comentarios_clientes_gestao_escritorio_filizola;
DROP POLICY "Permitir tudo comentarios_processos MVP" ON comentarios_processos_gestao_escritorio_filizola;

-- Remover politica temporaria do MVP (adicionada para a edge function de IA funcionar sem login)
DROP POLICY "Anon pode ver dados extraidos" ON dados_extraidos_gestao_escritorio_filizola;
```

### Tabelas de comentarios:

| Tabela | Colunas | Descricao |
|--------|---------|-----------|
| `comentarios_clientes_gestao_escritorio_filizola` | `cliente_id`, `usuario_id` (TEXT), `conteudo`, `criado_em`, `atualizado_em` | Chat geral sobre o cliente |
| `comentarios_processos_gestao_escritorio_filizola` | `processo_id`, `usuario_id` (TEXT), `conteudo`, `criado_em`, `atualizado_em` | Chat da equipe sobre um processo especifico |

> **Nota:** Ambas as tabelas usam `usuario_id TEXT` no MVP (sem FK para auth.users). No pos-MVP, mudar para `UUID REFERENCES auth.users(id)` e migrar os IDs temporarios.

> **Nota:** No pos-MVP, considerar adicionar `USING (auth.uid() = usuario_id)` na policy de DELETE para que cada usuario so apague proprios comentarios.

### Storage policies para reabilitar:

```sql
-- documentos_processuais
DROP POLICY "Upload de documentos processuais" ON storage.objects;
DROP POLICY "Download de documentos processuais" ON storage.objects;
DROP POLICY "Delete de documentos processuais" ON storage.objects;

CREATE POLICY "Auth upload documentos" ON storage.objects FOR INSERT
    TO authenticated WITH CHECK (bucket_id = 'documentos_processuais');
CREATE POLICY "Auth download documentos" ON storage.objects FOR SELECT
    TO authenticated USING (bucket_id = 'documentos_processuais');
CREATE POLICY "Auth delete documentos" ON storage.objects FOR DELETE
    TO authenticated USING (bucket_id = 'documentos_processuais');

-- peticoes_geradas (mesmo padrao)
DROP POLICY "Upload de peticoes geradas" ON storage.objects;
DROP POLICY "Update de peticoes geradas" ON storage.objects;
DROP POLICY "Download de peticoes geradas" ON storage.objects;
DROP POLICY "Delete de peticoes geradas" ON storage.objects;

CREATE POLICY "Auth upload peticoes" ON storage.objects FOR INSERT
    TO authenticated WITH CHECK (bucket_id = 'peticoes_geradas');
CREATE POLICY "Auth update peticoes" ON storage.objects FOR UPDATE
    TO authenticated USING (bucket_id = 'peticoes_geradas') WITH CHECK (bucket_id = 'peticoes_geradas');
CREATE POLICY "Auth download peticoes" ON storage.objects FOR SELECT
    TO authenticated USING (bucket_id = 'peticoes_geradas');
CREATE POLICY "Auth delete peticoes" ON storage.objects FOR DELETE
    TO authenticated USING (bucket_id = 'peticoes_geradas');
```

---

## 5. Implementacao de Autenticacao no Frontend

### O que precisa ser feito:

1. **Pagina de login** (`/login`)
   - Email + senha via Supabase Auth
   - `supabase.auth.signInWithPassword()`

2. **Middleware** (`src/middleware.ts`)
   - Verificar sessao em todas as rotas exceto `/login`
   - Redirecionar para `/login` se nao autenticado

3. **DashboardLayout** (`src/components/layout/dashboard-layout.tsx`)
   - Substituir dados hardcoded ("Dr. Ricardo") por dados do usuario logado
   - Botao de logout funcional: `supabase.auth.signOut()`

4. **Pagina de registro** (opcional)
   - `supabase.auth.signUp()` com email/senha
   - Criar perfil na tabela `perfis_gestao_escritorio_filizola` via trigger

### Arquivos que precisam ser criados/modificados:

| Arquivo | Acao |
|---------|------|
| `src/app/login/page.tsx` | **Criar** - pagina de login |
| `src/middleware.ts` | **Criar** - protecao de rotas |
| `src/components/layout/dashboard-layout.tsx` | **Modificar** - dados do usuario logado + logout funcional |
| `src/app/page.tsx` | **Modificar** - redirecionar para login se nao autenticado |
| `src/lib/supabase/client.ts` | Manter como esta (ja tem `persistSession: true`) |
| `src/components/comentarios-cliente.tsx` | **Modificar** - ao implementar auth, buscar nome do autor via `perfis` em vez de mostrar ID truncado |
| `src/components/comentarios-processo.tsx` | **Modificar** - ao implementar auth, buscar nome do autor via `perfis` em vez de mostrar ID truncado |

---

## 6. Variaveis de Ambiente

Nenhuma variavel nova necessaria. O Supabase client ja usa:
- `NEXT_PUBLIC_SUPABASE_URL`
- `NEXT_PUBLIC_SUPABASE_ANON_KEY`

---

## 7. Migrations Aplicadas no MVP (para referencia)

| Migration | O que fez |
|-----------|-----------|
| `20260408194102_initial_schema.sql` | Schema principal + RLS com policies `authenticated` |
| `20260410120000_peticoes_system.sql` | Tabela `peticoes_geradas` (sem RLS) |
| `20260410130000_dados_extraidos_system.sql` | Tabela `dados_extraidos` + RLS |
| `20260414120000_peticoes_geradas_rls.sql` | Desabilita RLS peticoes_geradas + bucket + policies |
| `20260414130000_peticoes_geradas_update_policy.sql` | Adiciona UPDATE policy no storage |
| `20260414140000_disable_all_rls.sql` | **Desabilita RLS nas 7 tabelas** (MVP) |
| `20260414150000_storage_anon_policies.sql` | **Remove auth do bucket documentos_processuais** (MVP) |
| `20260414160000_peticoes_geradas_anon.sql` | **Remove auth do bucket peticoes_geradas** (MVP) |
| `20260415000000_fix_rls_dados_extraidos_service_role.sql` | Fix RLS para service_role |
| `20260415000004_rpc_insert_dados_extraidos.sql` | RPC function para insert de dados extraidos |
| `20260415000005_add_anon_read_dados_extraidos.sql` | Anon read para dados extraidos |
| `20260417000001_add_sexo_cliente.sql` | **Coluna `sexo` em clientes** (masculino/feminino/nao_informado) |
| `20260417000002_comentarios_clientes.sql` | **Tabela `comentarios_clientes`** com RLS (desabilitado para MVP) |
| `20260417000003_variaveis_customizadas.sql` | **Coluna `variaveis_customizadas` (JSONB) em modelos_dantas_filizola** |
| `20260417000004_comentarios_processos.sql` | **Tabela `comentarios_processos`** com RLS + policy MVP (anon + authenticated) |
| `20260417000005_add_processo_id_comentarios.sql` | ~~Coluna `processo_id` em comentarios_clientes~~ (removida pelo usuario) |
| `20260417000006_fix_comentarios_usuario_id.sql` | **Muda `usuario_id` para TEXT** nas tabelas de comentarios (remove FK auth.users para MVP) |
| `20260417000007_fix_comentarios_rls_anon.sql` | **Corrige RLS comentarios_clientes**: troca policies `authenticated` por policy `anon + authenticated` |

---

## 8. Tipos de Usuario e Permissoes

### Perfis definidos:

| Role | Descricao |
|------|-----------|
| `super_admin` | Acesso total. Pode criar, editar, apagar clientes, processos, documentos, fotos e peticoes. Pode convidar novos usuarios e gerenciar permissoes. |
| `admin` | Acesso quase total. Pode criar e editar clientes, processos, documentos, fotos e peticoes. **NAO** pode apagar nem convidar pessoas. |
| `usuario` | Somente leitura. Pode visualizar clientes, processos, documentos e peticoes. **NAO** pode criar, editar ou apagar nada. |

### Matriz de permissoes por acao:

| Acao | super_admin | admin | usuario |
|------|:-----------:|:-----:|:-------:|
| Ver clientes/processos/documentos | SIM | SIM | SIM |
| Comentar em clientes | SIM | SIM | SIM |
| Comentar em processos (chat) | SIM | SIM | SIM |
| Criar clientes/processos | SIM | SIM | NAO |
| Editar clientes/processos/dados extraidos | SIM | SIM | NAO |
| Enviar documentos | SIM | SIM | NAO |
| Analisar documentos (IA) | SIM | SIM | NAO |
| Gerar/editar peticoes | SIM | SIM | NAO |
| Mover fase no kanban | SIM | SIM | NAO |
| Configurar templates de peticao | SIM | SIM | NAO |
| Criar tipos de peticao customizados | SIM | SIM | NAO |
| **Apagar clientes** | SIM | **NAO** | NAO |
| **Apagar processos** | SIM | **NAO** | NAO |
| **Apagar documentos/fotos** | SIM | **NAO** | NAO |
| **Apagar peticoes** | SIM | **NAO** | NAO |
| **Apagar comentarios proprios** | SIM | SIM | SIM |
| **Apagar comentarios de outros** | SIM | **NAO** | NAO |
| **Convidar usuarios** | SIM | **NAO** | NAO |
| **Gerenciar permissoes** | SIM | NAO | NAO |

### Implementacao sugerida:

1. **Coluna `role` na tabela `perfis_gestao_escritorio_filizola`:**
   ```sql
   ALTER TABLE public.perfis_gestao_escritorio_filizola
   ADD COLUMN IF NOT EXISTS role TEXT NOT NULL DEFAULT 'usuario'
   CHECK (role IN ('super_admin', 'admin', 'usuario'));
   ```

2. **Hook no frontend** para verificar permissao:
   ```typescript
   // src/lib/auth/permissions.ts
   type Role = 'super_admin' | 'admin' | 'usuario'

   function pode(role: Role, acao: 'criar' | 'editar' | 'apagar' | 'comentar' | 'convidar'): boolean {
       const permissoes: Record<Role, string[]> = {
           super_admin: ['criar', 'editar', 'apagar', 'comentar', 'convidar'],
           admin: ['criar', 'editar', 'comentar'],
           usuario: ['comentar'],
       }
       return permissoes[role]?.includes(acao) ?? false
   }
   ```

3. **Componentes condicionais** baseados na role:
   - Esconder botoes de "Apagar", "Enviar", "Gerar" para `usuario`
   - Esconder botoes de "Apagar" para `admin`
   - Mostrar botao "Convidar" e "Gerenciar" somente para `super_admin`
   - Comentarios: todos podem ver e criar, mas `admin` so pode deletar proprios, `super_admin` pode deletar qualquer um

4. **Pagina de gerenciamento de usuarios** (`/settings/usuarios`) - somente `super_admin`:
   - Listar usuarios
   - Alterar role (admin <-> usuario)
   - Criar novos usuarios (via Supabase Admin API)
   - Primeiro super_admin precisa ser criado manualmente no Supabase Dashboard

---

## 9. Edge Functions

As Edge Functions usam `SUPABASE_SERVICE_ROLE_KEY` (bypass RLS), entao nao sao afetadas pela autenticacao:
- `analisar-documentos` - usa service_role para acessar dados e storage
- `notificar-processos-criticos` - usa service_role para consultar processos

Nenhuma mudanca necessaria nas Edge Functions quando autenticacao for implementada.
