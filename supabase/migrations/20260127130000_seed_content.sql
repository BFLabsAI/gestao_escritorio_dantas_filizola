-- BFLabs Powerups Seed Data
TRUNCATE TABLE resource_tags_bflabs_ide_powerup CASCADE;
TRUNCATE TABLE tags_bflabs_ide_powerup CASCADE;
TRUNCATE TABLE use_cases_bflabs_ide_powerup CASCADE;
TRUNCATE TABLE requirements_bflabs_ide_powerup CASCADE;
TRUNCATE TABLE installation_methods_bflabs_ide_powerup CASCADE;
TRUNCATE TABLE resources_bflabs_ide_powerup CASCADE;
TRUNCATE TABLE categories_bflabs_ide_powerup CASCADE;
INSERT INTO categories_bflabs_ide_powerup (id, name, slug) VALUES ('b9f99d29-ef1f-4416-9f0e-fae44f8f4b48', 'Wrapper', 'wrapper') ON CONFLICT (slug) DO NOTHING;
INSERT INTO categories_bflabs_ide_powerup (id, name, slug) VALUES ('8d586bc7-1169-4857-ab1b-22de4b45743e', 'Agent', 'agent') ON CONFLICT (slug) DO NOTHING;
INSERT INTO categories_bflabs_ide_powerup (id, name, slug) VALUES ('538d2e88-a26f-4c0b-a0c2-58d1965c828e', 'MCP Server', 'mcp-server') ON CONFLICT (slug) DO NOTHING;
INSERT INTO categories_bflabs_ide_powerup (id, name, slug) VALUES ('0057a728-fe56-4a9b-ad82-b28872b5e0f3', 'Skill Pack', 'skill-pack') ON CONFLICT (slug) DO NOTHING;
INSERT INTO categories_bflabs_ide_powerup (id, name, slug) VALUES ('cc50662d-853b-4bac-b2d6-712b7b93d3d7', 'Guide', 'guide') ON CONFLICT (slug) DO NOTHING;
INSERT INTO resources_bflabs_ide_powerup (id, category_id, name, slug, short_description, long_description, repo_url, website_url) VALUES ('980493f9-4447-4813-a524-32ec2a19f6be', 'cc50662d-853b-4bac-b2d6-712b7b93d3d7', 'Vibe Kanban', 'vibe-kanban', '#### Overview...', '#### Overview

AI coding agents are increasingly writing the world''s code and human engineers now spend the majority of their time planning, reviewing, and orchestrating tasks. Vibe Kanban streamlines this process, enabling you to:

- Easily switch between different coding agents
- Orchestrate the execution of multiple coding agents in parallel or in sequence
- Quickly review work and start dev servers
- Track the status of tasks that your coding agents are working on
- Centralise configuration of coding agent MCP configs
- Open projects remotely via SSH when running Vibe Kanban on a remote server

You can watch a video overview [here](https://youtu.be/TFT3KnZOOAk).

#### Installation

Make sure you have authenticated with your favourite coding agent. A full list of supported coding agents can be found in the [docs](https://vibekanban.com/docs). Then in your terminal run:

```shell
npx vibe-kanban
```

## Documentation

Please head to the [website](https://vibekanban.com/docs) for the latest documentation and user guides.

#### Support

We use [GitHub Discussions](https://github.com/BloopAI/vibe-kanban/discussions) for feature requests. Please open a discussion to create a feature request. For bugs please open an issue on this repo.

#### Contributing

We would prefer that ideas and changes are first raised with the core team via [GitHub Discussions](https://github.com/BloopAI/vibe-kanban/discussions) or [Discord](https://discord.gg/AC4nwVtJM3), where we can discuss implementation details and alignment with the existing roadmap. Please do not open PRs without first discussing your proposal with the team.

#### Development

##### Prerequisites

- [Rust](https://rustup.rs/) (latest stable)
- [Node.js](https://nodejs.org/) (>=18)
- [pnpm](https://pnpm.io/) (>=8)

Additional development tools:

```shell
cargo install cargo-watch
cargo install sqlx-cli
```

Install dependencies:

```shell
pnpm i
```

##### Running the Dev Server

```shell
pnpm run dev
```

This will start the backend. A blank DB will be copied from the `dev_assets_seed` folder.

##### Building the Frontend

To build just the frontend:

```shell
cd frontend
pnpm build
```

##### Build from Source (macOS)

1. Run `./local-build.sh`
2. Test with `cd npx-cli && node bin/cli.js`

##### Environment Variables

The following environment variables can be configured at build time or runtime:

|Variable|Type|Default|Description|
|---|---|---|---|
|`POSTHOG_API_KEY`|Build-time|Empty|PostHog analytics API key (disables analytics if empty)|
|`POSTHOG_API_ENDPOINT`|Build-time|Empty|PostHog analytics endpoint (disables analytics if empty)|
|`PORT`|Runtime|Auto-assign|**Production**: Server port. **Dev**: Frontend port (backend uses PORT+1)|
|`BACKEND_PORT`|Runtime|`0` (auto-assign)|Backend server port (dev mode only, overrides PORT+1)|
|`FRONTEND_PORT`|Runtime|`3000`|Frontend dev server port (dev mode only, overrides PORT)|
|`HOST`|Runtime|`127.0.0.1`|Backend server host|
|`MCP_HOST`|Runtime|Value of `HOST`|MCP server connection host (use `127.0.0.1` when `HOST=0.0.0.0` on Windows)|
|`MCP_PORT`|Runtime|Value of `BACKEND_PORT`|MCP server connection port|
|`DISABLE_WORKTREE_ORPHAN_CLEANUP`|Runtime|Not set|Disable git worktree cleanup (for debugging)|
|`VK_ALLOWED_ORIGINS`|Runtime|Not set|Comma-separated list of origins that are allowed to make backend API requests (e.g., `https://my-vibekanban-frontend.com`)|

**Build-time variables** must be set when running `pnpm run build`. **Runtime variables** are read when the application starts.

##### Self-Hosting with a Reverse Proxy or Custom Domain

When running Vibe Kanban behind a reverse proxy (e.g., nginx, Caddy, Traefik) or on a custom domain, you must set the `VK_ALLOWED_ORIGINS` environment variable. Without this, the browser''s Origin header won''t match the backend''s expected host, and API requests will be rejected with a 403 Forbidden error.

Set it to the full origin URL(s) where your frontend is accessible:

```shell
# Single origin
VK_ALLOWED_ORIGINS=https://vk.example.com

# Multiple origins (comma-separated)
VK_ALLOWED_ORIGINS=https://vk.example.com,https://vk-staging.example.com
```

##### Remote Deployment

When running Vibe Kanban on a remote server (e.g., via systemctl, Docker, or cloud hosting), you can configure your editor to open projects via SSH:

1. **Access via tunnel**: Use Cloudflare Tunnel, ngrok, or similar to expose the web UI
2. **Configure remote SSH** in Settings → Editor Integration:
    - Set **Remote SSH Host** to your server hostname or IP
    - Set **Remote SSH User** to your SSH username (optional)
3. **Prerequisites**:
    - SSH access from your local machine to the remote server
    - SSH keys configured (passwordless authentication)
    - VSCode Remote-SSH extension

When configured, the "Open in VSCode" buttons will generate URLs like `vscode://vscode-remote/ssh-remote+user@host/path` that open your local editor and connect to the remote server.

See the [documentation](https://vibekanban.com/docs/configuration-customisation/global-settings#remote-ssh-configuration) for detailed setup instructions.', 'https://github.com/BloopAI/vibe-kanban', 'https://www.vibekanban.com/docs/agents/claude-code');
INSERT INTO installation_methods_bflabs_ide_powerup (resource_id, method_type, scope, command_snippet, description) VALUES ('980493f9-4447-4813-a524-32ec2a19f6be', 'npm', 'project', 'npx vibe-kanban', 'Installation Command');
INSERT INTO installation_methods_bflabs_ide_powerup (resource_id, method_type, scope, command_snippet, description) VALUES ('980493f9-4447-4813-a524-32ec2a19f6be', 'npm', 'project', 'cargo install cargo-watch
cargo install sqlx-cli', 'Additional development tools:');
INSERT INTO installation_methods_bflabs_ide_powerup (resource_id, method_type, scope, command_snippet, description) VALUES ('980493f9-4447-4813-a524-32ec2a19f6be', 'npm', 'project', 'pnpm i', 'Install dependencies:');
INSERT INTO installation_methods_bflabs_ide_powerup (resource_id, method_type, scope, command_snippet, description) VALUES ('980493f9-4447-4813-a524-32ec2a19f6be', 'npm', 'project', 'pnpm run dev', '#### Running the Dev Server');
INSERT INTO installation_methods_bflabs_ide_powerup (resource_id, method_type, scope, command_snippet, description) VALUES ('980493f9-4447-4813-a524-32ec2a19f6be', 'npm', 'project', 'cd frontend
pnpm build', 'To build just the frontend:');
INSERT INTO installation_methods_bflabs_ide_powerup (resource_id, method_type, scope, command_snippet, description) VALUES ('980493f9-4447-4813-a524-32ec2a19f6be', 'npm', 'project', '# Single origin
VK_ALLOWED_ORIGINS=https://vk.example.com

# Multiple origins (comma-separated)
VK_ALLOWED_ORIGINS=https://vk.example.com,https://vk-staging.example.com', 'Set it to the full origin URL(s) where your frontend is accessible:');
INSERT INTO resources_bflabs_ide_powerup (id, category_id, name, slug, short_description, long_description, repo_url, website_url) VALUES ('f0239681-630b-41c7-b757-995da285b79a', 'b9f99d29-ef1f-4416-9f0e-fae44f8f4b48', 'Claude Code', 'claude-code', '...', '', NULL, NULL);
INSERT INTO resources_bflabs_ide_powerup (id, category_id, name, slug, short_description, long_description, repo_url, website_url) VALUES ('12a97489-190a-45d1-a6a3-72a3a0a7d881', '0057a728-fe56-4a9b-ad82-b28872b5e0f3', 'Claude Code Templates (', 'claude-code-templates', '**Ready-to-use configurations for Anthropic''s Claude Code.** A comprehensive collection of AI agents, custom commands, settings, hooks, external integ...', '**Ready-to-use configurations for Anthropic''s Claude Code.** A comprehensive collection of AI agents, custom commands, settings, hooks, external integrations (MCPs), and project templates to enhance your development workflow.
#### 🚀 Quick Installation
```shell
# Install a complete development stack
npx claude-code-templates@latest --agent development-team/frontend-developer --command testing/generate-tests --mcp development/github-integration --yes

# Browse and install interactively
npx claude-code-templates@latest

# Install specific components
npx claude-code-templates@latest --agent development-tools/code-reviewer --yes
npx claude-code-templates@latest --command performance/optimize-bundle --yes
npx claude-code-templates@latest --setting performance/mcp-timeouts --yes
npx claude-code-templates@latest --hook git/pre-commit-validation --yes
npx claude-code-templates@latest --mcp database/postgresql-integration --yes
```
#### What You Get

|Component|Description|Examples|
|---|---|---|
|**🤖 Agents**|AI specialists for specific domains|Security auditor, React performance optimizer, database architect|
|**⚡ Commands**|Custom slash commands|`/generate-tests`, `/optimize-bundle`, `/check-security`|
|**🔌 MCPs**|External service integrations|GitHub, PostgreSQL, Stripe, AWS, OpenAI|
|**⚙️ Settings**|Claude Code configurations|Timeouts, memory settings, output styles|
|**🪝 Hooks**|Automation triggers|Pre-commit validation, post-completion actions|
|**🎨 Skills**|Reusable capabilities with progressive disclosure|PDF processing, Excel automation, custom workflows|
#### 🛠️ Additional Tools
Beyond the template catalog, Claude Code Templates includes powerful development tools:
##### 📊 Claude Code Analytics
Monitor your AI-powered development sessions in real-time with live state detection and performance metrics.
```shell
npx claude-code-templates@latest --analytics
```
##### 💬 Conversation Monitor
Mobile-optimized interface to view Claude responses in real-time with secure remote access.
```shell
# Local access
npx claude-code-templates@latest --chats

# Secure remote access via Cloudflare Tunnel
npx claude-code-templates@latest --chats --tunnel
```
##### 🔍 Health Check
Comprehensive diagnostics to ensure your Claude Code installation is optimized.
```shell
npx claude-code-templates@latest --health-check
```
##### 🔌 Plugin Dashboard
View marketplaces, installed plugins, and manage permissions from a unified interface.
```shell
npx claude-code-templates@latest --plugins
```
##### 📖 Documentation
**[📚 docs.aitmpl.com](https://docs.aitmpl.com/)** - Complete guides, examples, and API reference for all components and tools.
#### Best Templates from Aitmpl
###### Mcp''s
```
`npx claude-code-templates@latest --mcp=devtools/testsprite --yes`
npx claude-code-templates@latest --mcp=marketing/google-ads-mcp-server --yes
npx claude-code-templates@latest --mcp=marketing/facebook-ads-mcp-server --yes


```
###### Settings
```
npx claude-code-templates@latest --setting=statusline/context-monitor --yes
```
###### Comands
```
npx claude-code-templates@latest --command=performance/optimize-database-performance --yes
```
###### Agents (global)
```
npx claude-code-templates@latest --create-agent documentation/changelog-generator
```
###### Template
```
npx claude-code-templates@latest --skill=web-development/upstash-qstash --yes
npx claude-code-templates@latest --skill=sentry/code-review --yes
npx claude-code-templates@latest --skill=sentry/find-bugs --yes
npx claude-code-templates@latest --skill=development/brainstorming --yes
npx claude-code-templates@latest --skill=productivity/commit-work --yes
npx claude-code-templates@latest --skill=database/supabase-postgres-best-practices --yes
npx claude-code-templates@latest --skill=development/artifacts-builder --yes
npx claude-code-templates@latest --skill=creative-design/ui-design-system --yes
npx claude-code-templates@latest --skill=development/code-reviewer --yes
npx claude-code-templates@latest --skill=development/webapp-testing --yes
npx claude-code-templates@latest --skill=development/git-commit-helper --yes
```
###### Aditional Tools
```
npx claude-code-templates@latest --plugins
npx claude-code-templates@latest --health-check
```

----', 'https://github.com/davila7/claude-code-templates#claude-code-templates-aitmplcom', 'https://github.com/davila7/claude-code-templates#claude-code-templates-aitmplcom');
INSERT INTO installation_methods_bflabs_ide_powerup (resource_id, method_type, scope, command_snippet, description) VALUES ('12a97489-190a-45d1-a6a3-72a3a0a7d881', 'npm', 'project', '# Install a complete development stack
npx claude-code-templates@latest --agent development-team/frontend-developer --command testing/generate-tests --mcp development/github-integration --yes

# Browse and install interactively
npx claude-code-templates@latest

# Install specific components
npx claude-code-templates@latest --agent development-tools/code-reviewer --yes
npx claude-code-templates@latest --command performance/optimize-bundle --yes
npx claude-code-templates@latest --setting performance/mcp-timeouts --yes
npx claude-code-templates@latest --hook git/pre-commit-validation --yes
npx claude-code-templates@latest --mcp database/postgresql-integration --yes', '### 🚀 Quick Installation');
INSERT INTO installation_methods_bflabs_ide_powerup (resource_id, method_type, scope, command_snippet, description) VALUES ('12a97489-190a-45d1-a6a3-72a3a0a7d881', 'npm', 'project', 'npx claude-code-templates@latest --analytics', 'Installation Command');
INSERT INTO installation_methods_bflabs_ide_powerup (resource_id, method_type, scope, command_snippet, description) VALUES ('12a97489-190a-45d1-a6a3-72a3a0a7d881', 'npm', 'project', '# Local access
npx claude-code-templates@latest --chats

# Secure remote access via Cloudflare Tunnel
npx claude-code-templates@latest --chats --tunnel', 'Mobile-optimized interface to view Claude responses in real-time with secure remote access.');
INSERT INTO installation_methods_bflabs_ide_powerup (resource_id, method_type, scope, command_snippet, description) VALUES ('12a97489-190a-45d1-a6a3-72a3a0a7d881', 'npm', 'project', 'npx claude-code-templates@latest --health-check', 'Comprehensive diagnostics to ensure your Claude Code installation is optimized.');
INSERT INTO installation_methods_bflabs_ide_powerup (resource_id, method_type, scope, command_snippet, description) VALUES ('12a97489-190a-45d1-a6a3-72a3a0a7d881', 'npm', 'project', 'npx claude-code-templates@latest --plugins', 'View marketplaces, installed plugins, and manage permissions from a unified interface.');
INSERT INTO installation_methods_bflabs_ide_powerup (resource_id, method_type, scope, command_snippet, description) VALUES ('12a97489-190a-45d1-a6a3-72a3a0a7d881', 'npm', 'project', '`npx claude-code-templates@latest --mcp=devtools/testsprite --yes`
npx claude-code-templates@latest --mcp=marketing/google-ads-mcp-server --yes
npx claude-code-templates@latest --mcp=marketing/facebook-ads-mcp-server --yes', '##### Mcp''s');
INSERT INTO installation_methods_bflabs_ide_powerup (resource_id, method_type, scope, command_snippet, description) VALUES ('12a97489-190a-45d1-a6a3-72a3a0a7d881', 'npm', 'project', 'npx claude-code-templates@latest --setting=statusline/context-monitor --yes', '##### Settings');
INSERT INTO installation_methods_bflabs_ide_powerup (resource_id, method_type, scope, command_snippet, description) VALUES ('12a97489-190a-45d1-a6a3-72a3a0a7d881', 'npm', 'project', 'npx claude-code-templates@latest --command=performance/optimize-database-performance --yes', '##### Comands');
INSERT INTO installation_methods_bflabs_ide_powerup (resource_id, method_type, scope, command_snippet, description) VALUES ('12a97489-190a-45d1-a6a3-72a3a0a7d881', 'npm', 'global', 'npx claude-code-templates@latest --create-agent documentation/changelog-generator', '##### Agents (global)');
INSERT INTO installation_methods_bflabs_ide_powerup (resource_id, method_type, scope, command_snippet, description) VALUES ('12a97489-190a-45d1-a6a3-72a3a0a7d881', 'npm', 'project', 'npx claude-code-templates@latest --skill=web-development/upstash-qstash --yes
npx claude-code-templates@latest --skill=sentry/code-review --yes
npx claude-code-templates@latest --skill=sentry/find-bugs --yes
npx claude-code-templates@latest --skill=development/brainstorming --yes
npx claude-code-templates@latest --skill=productivity/commit-work --yes
npx claude-code-templates@latest --skill=database/supabase-postgres-best-practices --yes
npx claude-code-templates@latest --skill=development/artifacts-builder --yes
npx claude-code-templates@latest --skill=creative-design/ui-design-system --yes
npx claude-code-templates@latest --skill=development/code-reviewer --yes
npx claude-code-templates@latest --skill=development/webapp-testing --yes
npx claude-code-templates@latest --skill=development/git-commit-helper --yes', '##### Template');
INSERT INTO installation_methods_bflabs_ide_powerup (resource_id, method_type, scope, command_snippet, description) VALUES ('12a97489-190a-45d1-a6a3-72a3a0a7d881', 'npm', 'project', 'npx claude-code-templates@latest --plugins
npx claude-code-templates@latest --health-check', '##### Aditional Tools');
INSERT INTO resources_bflabs_ide_powerup (id, category_id, name, slug, short_description, long_description, repo_url, website_url) VALUES ('886360a2-97a7-4161-8247-30710e6f2f7c', '8d586bc7-1169-4857-ab1b-22de4b45743e', 'Claude Code Plugins: Orchestration and Automation (Seth robson)', 'claude-code-plugins-orchestration-and-automation-seth-robson', 'https://github.com/wshobson/agents.git...', 'https://github.com/wshobson/agents.git
###### OverView
This unified repository provides everything needed for intelligent automation and multi-agent orchestration across modern software development:
- **72 Focused Plugins** - Granular, single-purpose plugins optimized for minimal token usage and composability
- **108 Specialized Agents** - Domain experts with deep knowledge across architecture, languages, infrastructure, quality, data/AI, documentation, business operations, and SEO
- **129 Agent Skills** - Modular knowledge packages with progressive disclosure for specialized expertise
- **15 Workflow Orchestrators** - Multi-agent coordination systems for complex operations like full-stack development, security hardening, ML pipelines, and incident response
- **72 Development Tools** - Optimized utilities including project scaffolding, security scanning, test automation, and infrastructure setup
 
Key Features
- **Granular Plugin Architecture**: 72 focused plugins optimized for minimal token usage
- **Comprehensive Tooling**: 72 development tools including test generation, scaffolding, and security scanning
- **100% Agent Coverage**: All plugins include specialized agents
- **Agent Skills**: 129 specialized skills following for progressive disclosure and token efficiency
- **Clear Organization**: 23 categories with 1-6 plugins each for easy discovery
- **Efficient Design**: Average 3.4 components per plugin (follows Anthropic''s 2-8 pattern)

 How It Works
Each plugin is completely isolated with its own agents, commands, and skills:
- **Install only what you need** - Each plugin loads only its specific agents, commands, and skills
- **Minimal token usage** - No unnecessary resources loaded into context
- **Mix and match** - Compose multiple plugins for complex workflows
- **Clear boundaries** - Each plugin has a single, focused purpose
- **Progressive disclosure** - Skills load knowledge only when activated

**Example**: Installing `python-development` loads 3 Python agents, 1 scaffolding tool, and makes 5 skills available (~300 tokens), not the entire marketplace.

---', 'https://github.com/wshobson/agents.git', NULL);
INSERT INTO resources_bflabs_ide_powerup (id, category_id, name, slug, short_description, long_description, repo_url, website_url) VALUES ('ebcdd9d2-879a-4a95-91d4-e57ca80583b3', '8d586bc7-1169-4857-ab1b-22de4b45743e', 'Awesome Claude Code Subagents (Volt Agent)', 'awesome-claude-code-subagents-volt-agent', 'https://github.com/VoltAgent/awesome-claude-code-subagents.git...', 'https://github.com/VoltAgent/awesome-claude-code-subagents.git

 What is this?
This repository serves as the definitive collection of Claude Code subagents - specialized AI assitants designed for specific development tasks.

Installation

As Claude Code Plugin (Recommended)
```shell
claude plugin marketplace add VoltAgent/awesome-claude-code-subagents
claude plugin install <plugin-name>
```

Examples:

```shell
claude plugin install voltagent-lang    # Language specialists
claude plugin install voltagent-infra   # Infrastructure & DevOps
```

See [Categories](https://github.com/VoltAgent/awesome-claude-code-subagents#-categories) below for all available plugins.

> **Note**: The `voltagent-meta` orchestration agents work best when other categories installed.

 Option 1: Manual Installation
1. Clone this repository
2. Copy desired agent files to:
    - `~/.claude/agents/` for global access
    - `.claude/agents/` for project-specific use
3. Customize based on your project requirements

 Option 2: Interactive Installer

```shell
git clone https://github.com/VoltAgent/awesome-claude-code-subagents.git
cd awesome-claude-code-subagents
./install-agents.sh
```
This interactive script lets you browse categories, select agents, and install/uninstall them with a single command.
 
 Option 3: Standalone Installer (no clone required)

```shell
curl -sO https://raw.githubusercontent.com/VoltAgent/awesome-claude-code-subagents/main/install-agents.sh
chmod +x install-agents.sh
./install-agents.sh
```
Downloads agents directly from GitHub without cloning the repository. Requires `curl`.

Option 4: Agent Installer (use Claude Code to install agents)

```shell
curl -s https://raw.githubusercontent.com/VoltAgent/awesome-claude-code-subagents/main/categories/09-meta-orchestration/agent-installer.md -o ~/.claude/agents/agent-installer.md
```
Then in Claude Code: "Use the agent-installer to show me available categories" or "Find PHP agents and install php-pro globally".

---', 'https://github.com/VoltAgent/awesome-claude-code-subagents.git', NULL);
INSERT INTO installation_methods_bflabs_ide_powerup (resource_id, method_type, scope, command_snippet, description) VALUES ('ebcdd9d2-879a-4a95-91d4-e57ca80583b3', 'plugin', 'project', 'claude plugin marketplace add VoltAgent/awesome-claude-code-subagents
claude plugin install <plugin-name>', 'As Claude Code Plugin (Recommended)');
INSERT INTO installation_methods_bflabs_ide_powerup (resource_id, method_type, scope, command_snippet, description) VALUES ('ebcdd9d2-879a-4a95-91d4-e57ca80583b3', 'plugin', 'project', 'claude plugin install voltagent-lang    # Language specialists
claude plugin install voltagent-infra   # Infrastructure & DevOps', 'Examples:');
INSERT INTO installation_methods_bflabs_ide_powerup (resource_id, method_type, scope, command_snippet, description) VALUES ('ebcdd9d2-879a-4a95-91d4-e57ca80583b3', 'script', 'project', 'git clone https://github.com/VoltAgent/awesome-claude-code-subagents.git
cd awesome-claude-code-subagents
./install-agents.sh', 'Option 2: Interactive Installer');
INSERT INTO installation_methods_bflabs_ide_powerup (resource_id, method_type, scope, command_snippet, description) VALUES ('ebcdd9d2-879a-4a95-91d4-e57ca80583b3', 'script', 'project', 'curl -sO https://raw.githubusercontent.com/VoltAgent/awesome-claude-code-subagents/main/install-agents.sh
chmod +x install-agents.sh
./install-agents.sh', 'Option 3: Standalone Installer (no clone required)');
INSERT INTO installation_methods_bflabs_ide_powerup (resource_id, method_type, scope, command_snippet, description) VALUES ('ebcdd9d2-879a-4a95-91d4-e57ca80583b3', 'script', 'project', 'curl -s https://raw.githubusercontent.com/VoltAgent/awesome-claude-code-subagents/main/categories/09-meta-orchestration/agent-installer.md -o ~/.claude/agents/agent-installer.md', 'Option 4: Agent Installer (use Claude Code to install agents)');
INSERT INTO resources_bflabs_ide_powerup (id, category_id, name, slug, short_description, long_description, repo_url, website_url) VALUES ('9ff2f5b6-74a6-4966-8d46-e19e61ac1ed8', 'cc50662d-853b-4bac-b2d6-712b7b93d3d7', 'Claude Code Guide', 'claude-code-guide', '|Section|Status|...', '|Section|Status|
|---|---|
|Guides on how to install on Windows, Linux, MacOS|✅|
|Tips and Tricks|✅|
|MCP Overview with what to use|✅|
|Community Guides|✅|
|Troubleshooting|✅|
|How to use Claude code the most optimal way|✅|
Esse repo é um guia completo e opinado para usar o Claude Code (CLI + integração com IDE) no dia a dia de desenvolvimento, desde a instalação até recursos avançados como MCP, subagents, automação e segurança.[](https://github.com/zebbern/claude-code-guide)​

## O Que Tem Dentro

- Passo a passo de instalação em Windows, Mac, Linux, WSL, Docker e verificação se o `claude` está instalado corretamente.[](https://github.com/zebbern/claude-code-guide)​
    
- Guia de setup inicial: como configurar ANTHROPIC_API_KEY, login, tokens, variáveis de ambiente e arquivos de configuração (CLAUDE.md em nível global, de projeto, enterprise etc.).[](https://github.com/zebbern/claude-code-guide)​
    
- Tabela de comandos (`/agents`, `/mcp`, `/plan`, `/review`, `/memory`, `/tasks`, `/chrome`, etc.) e flags de linha de comando para automação (print mode, JSON, max-budget, max-turns, tools permitidos, etc.).[](https://github.com/zebbern/claude-code-guide)​
    
- Cheatsheet de uso diário: padrões de uso no terminal, continuação de sessões, gestão de configuração por projeto/global e gerenciamento de MCP.[](https://github.com/zebbern/claude-code-guide)​
    
- Conteúdo de produtividade: atalhos de teclado, input multiline, modos de edição de texto, sub-agents, background tasks, remote sessions, integração com IDE, e boas práticas de segurança/permissions.[](https://github.com/zebbern/claude-code-guide)​
    
- Seção de troubleshooting (instalação, Node, MCP) e links para changelog diário oficial do Claude Code e skills de segurança via SKILL.md.[](https://github.com/zebbern/claude-code-guide)​
    

## Como Isso Pode Te Ajudar (na Prática, pro Teu contexto)

- Acelerar teu setup padronizado de Claude Code em todas as máquinas (dev, container, WSL), evitando ficar "caçando" config em docs soltas.[](https://github.com/zebbern/claude-code-guide)​
    
- Criar um stack de **IA aplicada** consistente nos teus projetos: CLAUDE.md por empresa/projeto, memórias e políticas de segurança alinhadas com padrões de código e compliance do ecossistema R7/Simplifica/BF Labs.[](https://github.com/zebbern/claude-code-guide)​
    
- Transformar Claude Code em um "dev interno" com subagents e MCP, plugando em ferramentas que você já usa (git, scripts, APIs internas) para automatizar tarefas chatas: PR review, triagem de issues, geração de scripts, refactors grandes, etc.[](https://github.com/zebbern/claude-code-guide)​
    
- Usar o CLI em modo script/automação (print + JSON + max-budget) para orquestrar flows junto com n8n/Make/Zapier, CI/CD e bots que você já constrói (tipo HubZap), mantendo controle de custo e tokens.[](https://github.com/zebbern/claude-code-guide)​
    
- Endurecer segurança: configurar permission modes, desabilitar telemetria, controlar ferramentas permitidas e usar "plan mode"/read-only para rodar o agente em ambientes sensíveis.[](https://github.com/zebbern/claude-code-guide)​', 'https://github.com/zebbern/claude-code-guide#claude-code-guide', NULL);
INSERT INTO resources_bflabs_ide_powerup (id, category_id, name, slug, short_description, long_description, repo_url, website_url) VALUES ('0b99afaa-6658-4126-80a0-3c478a3c733b', 'cc50662d-853b-4bac-b2d6-712b7b93d3d7', 'Everything Claude Code', 'everything-claude-code', '**The complete collection of Claude Code configs from an Anthropic hackathon winner.**...', '**The complete collection of Claude Code configs from an Anthropic hackathon winner.**

Production-ready agents, skills, hooks, commands, rules, and MCP configurations evolved over 10+ months of intensive daily use building real products.
##### The Guides
This repo is the raw code only. The guides explain everything.

|   |   |
|---|---|
|[![The Shorthand Guide to Everything Claude Code](https://private-user-images.githubusercontent.com/124439313/537241459-1a471488-59cc-425b-8345-5245c7efbcef.png?jwt=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJnaXRodWIuY29tIiwiYXVkIjoicmF3LmdpdGh1YnVzZXJjb250ZW50LmNvbSIsImtleSI6ImtleTUiLCJleHAiOjE3Njk1MTA2OTgsIm5iZiI6MTc2OTUxMDM5OCwicGF0aCI6Ii8xMjQ0MzkzMTMvNTM3MjQxNDU5LTFhNDcxNDg4LTU5Y2MtNDI1Yi04MzQ1LTUyNDVjN2VmYmNlZi5wbmc_WC1BbXotQWxnb3JpdGhtPUFXUzQtSE1BQy1TSEEyNTYmWC1BbXotQ3JlZGVudGlhbD1BS0lBVkNPRFlMU0E1M1BRSzRaQSUyRjIwMjYwMTI3JTJGdXMtZWFzdC0xJTJGczMlMkZhd3M0X3JlcXVlc3QmWC1BbXotRGF0ZT0yMDI2MDEyN1QxMDM5NThaJlgtQW16LUV4cGlyZXM9MzAwJlgtQW16LVNpZ25hdHVyZT1iYTE3NjE2M2IyOTZkMzRkOGQwYzJiMGVmYzBmMDZiYTkxYmNiOTYwMTQ4OGUxNzIxMzQ3MDEzNGU3YTExZDk4JlgtQW16LVNpZ25lZEhlYWRlcnM9aG9zdCJ9.iwSZpfXGmZUXi2FSCVtWpeHBnciINtinATuLFFFKNeA)](https://x.com/affaanmustafa/status/2012378465664745795)|[![The Longform Guide to Everything Claude Code](https://private-user-images.githubusercontent.com/124439313/538747339-c9ca43bc-b149-427f-b551-af6840c368f0.png?jwt=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJnaXRodWIuY29tIiwiYXVkIjoicmF3LmdpdGh1YnVzZXJjb250ZW50LmNvbSIsImtleSI6ImtleTUiLCJleHAiOjE3Njk1MTA2OTgsIm5iZiI6MTc2OTUxMDM5OCwicGF0aCI6Ii8xMjQ0MzkzMTMvNTM4NzQ3MzM5LWM5Y2E0M2JjLWIxNDktNDI3Zi1iNTUxLWFmNjg0MGMzNjhmMC5wbmc_WC1BbXotQWxnb3JpdGhtPUFXUzQtSE1BQy1TSEEyNTYmWC1BbXotQ3JlZGVudGlhbD1BS0lBVkNPRFlMU0E1M1BRSzRaQSUyRjIwMjYwMTI3JTJGdXMtZWFzdC0xJTJGczMlMkZhd3M0X3JlcXVlc3QmWC1BbXotRGF0ZT0yMDI2MDEyN1QxMDM5NThaJlgtQW16LUV4cGlyZXM9MzAwJlgtQW16LVNpZ25hdHVyZT0zMjYxNGZjZDAzN2QzMWI0ZTliYjdjZmM1ODY2ZmYyMWZlZGZkODk3NjllMmI4YjE4MmM3ZjEwMjk3M2M5M2Y0JlgtQW16LVNpZ25lZEhlYWRlcnM9aG9zdCJ9.h-hdnCdudGBWot2sBZr7kKTgYUb0KD93PnP-FWhG9x4)](https://x.com/affaanmustafa/status/2014040193557471352)|
|**Shorthand Guide**  <br>Setup, foundations, philosophy. **Read this first.**|**Longform Guide**  <br>Token optimization, memory persistence, evals, parallelization.|

|Topic|What You''ll Learn|
|---|---|
|Token Optimization|Model selection, system prompt slimming, background processes|
|Memory Persistence|Hooks that save/load context across sessions automatically|
|Continuous Learning|Auto-extract patterns from sessions into reusable skills|
|Verification Loops|Checkpoint vs continuous evals, grader types, pass@k metrics|
|Parallelization|Git worktrees, cascade method, when to scale instances|
|Subagent Orchestration|The context problem, iterative retrieval pattern|

---
##### Cross-Platform Support

This plugin now fully supports **Windows, macOS, and Linux**. All hooks and scripts have been rewritten in Node.js for maximum compatibility.
###### Package Manager Detection
The plugin automatically detects your preferred package manager (npm, pnpm, yarn, or bun) with the following priority:
1. **Environment variable**: `CLAUDE_PACKAGE_MANAGER`
2. **Project config**: `.claude/package-manager.json`
3. **package.json**: `packageManager` field
4. **Lock file**: Detection from package-lock.json, yarn.lock, pnpm-lock.yaml, or bun.lockb
5. **Global config**: `~/.claude/package-manager.json`
6. **Fallback**: First available package manager

To set your preferred package manager:
```shell
# Via environment variable
export CLAUDE_PACKAGE_MANAGER=pnpm

# Via global config
node scripts/setup-package-manager.js --global pnpm

# Via project config
node scripts/setup-package-manager.js --project bun

# Detect current setting
node scripts/setup-package-manager.js --detect
```
 Or use the `/setup-pm` command in Claude Code.
---
##### What''s Inside
This repo is a **Claude Code plugin** - install it directly or copy components manually.
```
everything-claude-code/
|-- .claude-plugin/   # Plugin and marketplace manifests
|   |-- plugin.json         # Plugin metadata and component paths
|   |-- marketplace.json    # Marketplace catalog for /plugin marketplace add
|
|-- agents/           # Specialized subagents for delegation
|   |-- planner.md           # Feature implementation planning
|   |-- architect.md         # System design decisions
|   |-- tdd-guide.md         # Test-driven development
|   |-- code-reviewer.md     # Quality and security review
|   |-- security-reviewer.md # Vulnerability analysis
|   |-- build-error-resolver.md
|   |-- e2e-runner.md        # Playwright E2E testing
|   |-- refactor-cleaner.md  # Dead code cleanup
|   |-- doc-updater.md       # Documentation sync
|   |-- go-reviewer.md       # Go code review (NEW)
|   |-- go-build-resolver.md # Go build error resolution (NEW)
|
|-- skills/           # Workflow definitions and domain knowledge
|   |-- coding-standards/           # Language best practices
|   |-- backend-patterns/           # API, database, caching patterns
|   |-- frontend-patterns/          # React, Next.js patterns
|   |-- continuous-learning/        # Auto-extract patterns from sessions (Longform Guide)
|   |-- continuous-learning-v2/     # Instinct-based learning with confidence scoring
|   |-- iterative-retrieval/        # Progressive context refinement for subagents
|   |-- strategic-compact/          # Manual compaction suggestions (Longform Guide)
|   |-- tdd-workflow/               # TDD methodology
|   |-- security-review/            # Security checklist
|   |-- eval-harness/               # Verification loop evaluation (Longform Guide)
|   |-- verification-loop/          # Continuous verification (Longform Guide)
|   |-- golang-patterns/            # Go idioms and best practices (NEW)
|   |-- golang-testing/             # Go testing patterns, TDD, benchmarks (NEW)
|
|-- commands/         # Slash commands for quick execution
|   |-- tdd.md              # /tdd - Test-driven development
|   |-- plan.md             # /plan - Implementation planning
|   |-- e2e.md              # /e2e - E2E test generation
|   |-- code-review.md      # /code-review - Quality review
|   |-- build-fix.md        # /build-fix - Fix build errors
|   |-- refactor-clean.md   # /refactor-clean - Dead code removal
|   |-- learn.md            # /learn - Extract patterns mid-session (Longform Guide)
|   |-- checkpoint.md       # /checkpoint - Save verification state (Longform Guide)
|   |-- verify.md           # /verify - Run verification loop (Longform Guide)
|   |-- setup-pm.md         # /setup-pm - Configure package manager
|   |-- go-review.md        # /go-review - Go code review (NEW)
|   |-- go-test.md          # /go-test - Go TDD workflow (NEW)
|   |-- go-build.md         # /go-build - Fix Go build errors (NEW)
|
|-- rules/            # Always-follow guidelines (copy to ~/.claude/rules/)
|   |-- security.md         # Mandatory security checks
|   |-- coding-style.md     # Immutability, file organization
|   |-- testing.md          # TDD, 80% coverage requirement
|   |-- git-workflow.md     # Commit format, PR process
|   |-- agents.md           # When to delegate to subagents
|   |-- performance.md      # Model selection, context management
|
|-- hooks/            # Trigger-based automations
|   |-- hooks.json                # All hooks config (PreToolUse, PostToolUse, Stop, etc.)
|   |-- memory-persistence/       # Session lifecycle hooks (Longform Guide)
|   |-- strategic-compact/        # Compaction suggestions (Longform Guide)
|
|-- scripts/          # Cross-platform Node.js scripts (NEW)
|   |-- lib/                     # Shared utilities
|   |   |-- utils.js             # Cross-platform file/path/system utilities
|   |   |-- package-manager.js   # Package manager detection and selection
|   |-- hooks/                   # Hook implementations
|   |   |-- session-start.js     # Load context on session start
|   |   |-- session-end.js       # Save state on session end
|   |   |-- pre-compact.js       # Pre-compaction state saving
|   |   |-- suggest-compact.js   # Strategic compaction suggestions
|   |   |-- evaluate-session.js  # Extract patterns from sessions
|   |-- setup-package-manager.js # Interactive PM setup
|
|-- tests/            # Test suite (NEW)
|   |-- lib/                     # Library tests
|   |-- hooks/                   # Hook tests
|   |-- run-all.js               # Run all tests
|
|-- contexts/         # Dynamic system prompt injection contexts (Longform Guide)
|   |-- dev.md              # Development mode context
|   |-- review.md           # Code review mode context
|   |-- research.md         # Research/exploration mode context
|
|-- examples/         # Example configurations and sessions
|   |-- CLAUDE.md           # Example project-level config
|   |-- user-CLAUDE.md      # Example user-level config
|
|-- mcp-configs/      # MCP server configurations
|   |-- mcp-servers.json    # GitHub, Supabase, Vercel, Railway, etc.
|
|-- marketplace.json  # Self-hosted marketplace config (for /plugin marketplace add)
```
##### Ecosystem Tools', 'https://github.com/affaan-m/everything-claude-code#everything-claude-code', NULL);
INSERT INTO installation_methods_bflabs_ide_powerup (resource_id, method_type, scope, command_snippet, description) VALUES ('0b99afaa-6658-4126-80a0-3c478a3c733b', 'npm', 'global', '# Via environment variable
export CLAUDE_PACKAGE_MANAGER=pnpm

# Via global config
node scripts/setup-package-manager.js --global pnpm

# Via project config
node scripts/setup-package-manager.js --project bun

# Detect current setting
node scripts/setup-package-manager.js --detect', 'To set your preferred package manager:');
INSERT INTO installation_methods_bflabs_ide_powerup (resource_id, method_type, scope, command_snippet, description) VALUES ('0b99afaa-6658-4126-80a0-3c478a3c733b', 'npm', 'global', 'everything-claude-code/
|-- .claude-plugin/   # Plugin and marketplace manifests
|   |-- plugin.json         # Plugin metadata and component paths
|   |-- marketplace.json    # Marketplace catalog for /plugin marketplace add
|
|-- agents/           # Specialized subagents for delegation
|   |-- planner.md           # Feature implementation planning
|   |-- architect.md         # System design decisions
|   |-- tdd-guide.md         # Test-driven development
|   |-- code-reviewer.md     # Quality and security review
|   |-- security-reviewer.md # Vulnerability analysis
|   |-- build-error-resolver.md
|   |-- e2e-runner.md        # Playwright E2E testing
|   |-- refactor-cleaner.md  # Dead code cleanup
|   |-- doc-updater.md       # Documentation sync
|   |-- go-reviewer.md       # Go code review (NEW)
|   |-- go-build-resolver.md # Go build error resolution (NEW)
|
|-- skills/           # Workflow definitions and domain knowledge
|   |-- coding-standards/           # Language best practices
|   |-- backend-patterns/           # API, database, caching patterns
|   |-- frontend-patterns/          # React, Next.js patterns
|   |-- continuous-learning/        # Auto-extract patterns from sessions (Longform Guide)
|   |-- continuous-learning-v2/     # Instinct-based learning with confidence scoring
|   |-- iterative-retrieval/        # Progressive context refinement for subagents
|   |-- strategic-compact/          # Manual compaction suggestions (Longform Guide)
|   |-- tdd-workflow/               # TDD methodology
|   |-- security-review/            # Security checklist
|   |-- eval-harness/               # Verification loop evaluation (Longform Guide)
|   |-- verification-loop/          # Continuous verification (Longform Guide)
|   |-- golang-patterns/            # Go idioms and best practices (NEW)
|   |-- golang-testing/             # Go testing patterns, TDD, benchmarks (NEW)
|
|-- commands/         # Slash commands for quick execution
|   |-- tdd.md              # /tdd - Test-driven development
|   |-- plan.md             # /plan - Implementation planning
|   |-- e2e.md              # /e2e - E2E test generation
|   |-- code-review.md      # /code-review - Quality review
|   |-- build-fix.md        # /build-fix - Fix build errors
|   |-- refactor-clean.md   # /refactor-clean - Dead code removal
|   |-- learn.md            # /learn - Extract patterns mid-session (Longform Guide)
|   |-- checkpoint.md       # /checkpoint - Save verification state (Longform Guide)
|   |-- verify.md           # /verify - Run verification loop (Longform Guide)
|   |-- setup-pm.md         # /setup-pm - Configure package manager
|   |-- go-review.md        # /go-review - Go code review (NEW)
|   |-- go-test.md          # /go-test - Go TDD workflow (NEW)
|   |-- go-build.md         # /go-build - Fix Go build errors (NEW)
|
|-- rules/            # Always-follow guidelines (copy to ~/.claude/rules/)
|   |-- security.md         # Mandatory security checks
|   |-- coding-style.md     # Immutability, file organization
|   |-- testing.md          # TDD, 80% coverage requirement
|   |-- git-workflow.md     # Commit format, PR process
|   |-- agents.md           # When to delegate to subagents
|   |-- performance.md      # Model selection, context management
|
|-- hooks/            # Trigger-based automations
|   |-- hooks.json                # All hooks config (PreToolUse, PostToolUse, Stop, etc.)
|   |-- memory-persistence/       # Session lifecycle hooks (Longform Guide)
|   |-- strategic-compact/        # Compaction suggestions (Longform Guide)
|
|-- scripts/          # Cross-platform Node.js scripts (NEW)
|   |-- lib/                     # Shared utilities
|   |   |-- utils.js             # Cross-platform file/path/system utilities
|   |   |-- package-manager.js   # Package manager detection and selection
|   |-- hooks/                   # Hook implementations
|   |   |-- session-start.js     # Load context on session start
|   |   |-- session-end.js       # Save state on session end
|   |   |-- pre-compact.js       # Pre-compaction state saving
|   |   |-- suggest-compact.js   # Strategic compaction suggestions
|   |   |-- evaluate-session.js  # Extract patterns from sessions
|   |-- setup-package-manager.js # Interactive PM setup
|
|-- tests/            # Test suite (NEW)
|   |-- lib/                     # Library tests
|   |-- hooks/                   # Hook tests
|   |-- run-all.js               # Run all tests
|
|-- contexts/         # Dynamic system prompt injection contexts (Longform Guide)
|   |-- dev.md              # Development mode context
|   |-- review.md           # Code review mode context
|   |-- research.md         # Research/exploration mode context
|
|-- examples/         # Example configurations and sessions
|   |-- CLAUDE.md           # Example project-level config
|   |-- user-CLAUDE.md      # Example user-level config
|
|-- mcp-configs/      # MCP server configurations
|   |-- mcp-servers.json    # GitHub, Supabase, Vercel, Railway, etc.
|
|-- marketplace.json  # Self-hosted marketplace config (for /plugin marketplace add)', 'This repo is a **Claude Code plugin** - install it directly or copy components manually.');
INSERT INTO resources_bflabs_ide_powerup (id, category_id, name, slug, short_description, long_description, repo_url, website_url) VALUES ('c48916a8-a29c-46ed-ac65-7f26be96a514', '538d2e88-a26f-4c0b-a0c2-58d1965c828e', 'ecc.tools - Skill Creator', 'ecc-tools-skill-creator', 'Automatically generate Claude Code skills from your repository....', 'Automatically generate Claude Code skills from your repository.
[Install GitHub App](https://github.com/apps/skill-creator) | [ecc.tools](https://ecc.tools/)
Analyzes your repository and creates:
- **SKILL.md files** - Ready-to-use skills for Claude Code
- **Instinct collections** - For continuous-learning-v2
- **Pattern extraction** - Learns from your commit history
```shell
# After installing the GitHub App, skills appear in:
~/.claude/skills/generated/
```
Works seamlessly with the `continuous-learning-v2` skill for inherited instincts.
##### Installation
###### Option 1: Install as Plugin (Recommended)
The easiest way to use this repo - install as a Claude Code plugin:
```shell
# Add this repo as a marketplace
/plugin marketplace add affaan-m/everything-claude-code

# Install the plugin
/plugin install everything-claude-code@everything-claude-code
```

Or add directly to your `~/.claude/settings.json`:
```json
{
  "extraKnownMarketplaces": {
    "everything-claude-code": {
      "source": {
        "source": "github",
        "repo": "affaan-m/everything-claude-code"
      }
    }
  },
  "enabledPlugins": {
    "everything-claude-code@everything-claude-code": true
  }
}
```

This gives you instant access to all commands, agents, skills, and hooks.
> **Note:** The Claude Code plugin system does not support distributing `rules` via plugins ([upstream limitation](https://code.claude.com/docs/en/plugins-reference)). You need to install rules manually:
> 
> ```shell
> # Clone the repo first
> git clone https://github.com/affaan-m/everything-claude-code.git
> 
> # Option A: User-level rules (applies to all projects)
> cp -r everything-claude-code/rules/* ~/.claude/rules/
> 
> # Option B: Project-level rules (applies to current project only)
> mkdir -p .claude/rules
> cp -r everything-claude-code/rules/* .claude/rules/
> ```
###### Option 2: Manual Installation

If you prefer manual control over what''s installed:
```shell
# Clone the repo
git clone https://github.com/affaan-m/everything-claude-code.git

# Copy agents to your Claude config
cp everything-claude-code/agents/*.md ~/.claude/agents/

# Copy rules
cp everything-claude-code/rules/*.md ~/.claude/rules/

# Copy commands
cp everything-claude-code/commands/*.md ~/.claude/commands/

# Copy skills
cp -r everything-claude-code/skills/* ~/.claude/skills/
```

###### Add Hooks to settings.json
Copy the hooks from `hooks/hooks.json` to your `~/.claude/settings.json`.
##### Configure MCPs
Copy desired MCP servers from `mcp-configs/mcp-servers.json` to your `~/.claude.json`.

**Important:** Replace `YOUR_*_HERE` placeholders with your actual API keys.', 'https://github.com/apps/skill-creator', NULL);
INSERT INTO installation_methods_bflabs_ide_powerup (resource_id, method_type, scope, command_snippet, description) VALUES ('c48916a8-a29c-46ed-ac65-7f26be96a514', 'npm', 'project', '# After installing the GitHub App, skills appear in:
~/.claude/skills/generated/', '**Pattern extraction** - Learns from your commit history');
INSERT INTO installation_methods_bflabs_ide_powerup (resource_id, method_type, scope, command_snippet, description) VALUES ('c48916a8-a29c-46ed-ac65-7f26be96a514', 'npm', 'project', '# Add this repo as a marketplace
/plugin marketplace add affaan-m/everything-claude-code

# Install the plugin
/plugin install everything-claude-code@everything-claude-code', 'The easiest way to use this repo - install as a Claude Code plugin:');
INSERT INTO installation_methods_bflabs_ide_powerup (resource_id, method_type, scope, command_snippet, description) VALUES ('c48916a8-a29c-46ed-ac65-7f26be96a514', 'npm', 'project', 'This gives you instant access to all commands, agents, skills, and hooks.
> **Note:** The Claude Code plugin system does not support distributing `rules` via plugins ([upstream limitation](https://code.claude.com/docs/en/plugins-reference)). You need to install rules manually:
> 
>', 'Installation Command');
INSERT INTO installation_methods_bflabs_ide_powerup (resource_id, method_type, scope, command_snippet, description) VALUES ('c48916a8-a29c-46ed-ac65-7f26be96a514', 'npm', 'project', '###### Option 2: Manual Installation

If you prefer manual control over what''s installed:', 'Installation Command');
INSERT INTO resources_bflabs_ide_powerup (id, category_id, name, slug, short_description, long_description, repo_url, website_url) VALUES ('22db9e21-21e8-41f9-a90f-46071ecda177', 'cc50662d-853b-4bac-b2d6-712b7b93d3d7', '05 - Claude-Flow V3 ]​', '05-claude-flow-v3', '**Plataforma de orquestração multi‑agente para Claude Code, focada em desenvolvimento de software com swarms de agentes, memória vetorial própria e se...', '**Plataforma de orquestração multi‑agente para Claude Code, focada em desenvolvimento de software com swarms de agentes, memória vetorial própria e segurança de nível enterprise.**[[github](https://github.com/ruvnet/claude-flow)]​

## The Guides

Este repositório é o código e a infraestrutura completa do runtime de agentes, CLI, MCP server, memória e integrações; a explicação detalhada vem do README, Wiki e docs externos.[[github](https://github.com/ruvnet/claude-flow)]​

|||
|---|---|
|**Shorthand Guide**  <br>Visão geral rápida: o que é Claude-Flow v3, como instalar e rodar seus primeiros swarms com Claude Code.|**Longform Guide**  <br>Arquitetura, RuVector, topologias de swarm, segurança, tuning de performance e uso avançado em produção.|

## Topics / What You''ll Learn

|Topic|What You''ll Learn|
|---|---|
|Arquitetura de Orquestração|Como o fluxo `User → CLI/MCP → Router → Swarm → Agents → Memory → LLM Providers` funciona e se auto‑otimiza. [[github](https://github.com/ruvnet/claude-flow)]​|
|Swarm & Coordenação|Como rodar 60+ agentes em swarms com hierarquia de "queen/workers", padrões mesh e consenso tolerante a falhas. [[github](https://github.com/ruvnet/claude-flow)]​|
|Integração com Claude Code|Como conectar o MCP server e usar mais de 175 ferramentas de orquestração direto nas sessões do Claude Code. [[github](https://github.com/ruvnet/claude-flow)]​|
|Memória & RuVector|Como usar RuVector PostgreSQL para memória vetorial de alta performance e conhecimento coletivo dos agentes. [[github](https://github.com/ruvnet/claude-flow)]​|
|Instalação & CLI|Como instalar via script, npm/npx ou bunx e inicializar projetos com `claude-flow@alpha`. [[github](https://github.com/ruvnet/claude-flow)]​|
|Roteamento Inteligente|Como o sistema faz task routing, escolhe modelos (Claude, GPT, Gemini, Llama etc.) e otimiza custo/latência. [[github](https://github.com/ruvnet/claude-flow)]​|
|Segurança & Compliance|Quais proteções nativas existem contra prompt injection, path traversal, command injection e outros ataques. [[github](https://github.com/ruvnet/claude-flow)]​|
|Uso Programático|Como consumir os pacotes `claude-flow` e módulos relacionados direto na sua aplicação. [[github](https://github.com/ruvnet/claude-flow)]​|
|Cloud & Deploy|Como encaixar Claude-Flow em pipelines de cloud, pair‑programming e multi‑agent pipelines. [[github](https://github.com/ruvnet/claude-flow)]​|
|Suporte & Comunidade|Onde encontrar docs, issues, consultoria profissional e comunidade (Discord/Agentics Foundation). [[github](https://github.com/ruvnet/claude-flow)]​|

## Cross-Platform Support

O projeto roda em ambiente Node.js 20+ com suporte a npm, pnpm e bun, funcionando em Windows, macOS e Linux desde que os pré‑requisitos de Node estejam atendidos.[[github](https://github.com/ruvnet/claude-flow)]​  
A instalação pode ser feita via script `install.sh` (curl + bash) ou via `npx`/`npm install -g`, com perfis de instalação minimal ou completa, incluindo MCP e diagnósticos.[[github](https://github.com/ruvnet/claude-flow)]​

## Package / Runtime

- Node.js 20+ obrigatório.[[github](https://github.com/ruvnet/claude-flow)]​
    
- npm 9+ / pnpm / bun suportados; comandos de exemplo fornecidos para npx, npm global e bunx.[[github](https://github.com/ruvnet/claude-flow)]​
    

---

## What''s Inside

text

`claude-flow/ |-- .claude-plugin/           # Manifests de plugin Claude Code e marketplace interno |-- .claude/                  # Configs de agentes, skills, comandos e settings para Claude Code |-- agents/                   # Definições de agentes especializados (coding, review, security, DevOps, etc.) |-- plugin/                   # Código do plugin e integrações específicas com Claude/IDE |-- scripts/                  # scripts/install.sh, helpers e automações de desenvolvimento/diagnóstico |-- tests/                    # Testes, incluindo cenários docker-regression |-- v2/                       # Versão v2 da arquitetura / módulos legados |-- v3/                       # Nova arquitetura v3, CLI, MCP, core do swarm e módulos enterprise |-- docs/ruvector-postgres/   # Documentação para RuVector PostgreSQL (memória vetorial) |-- CHANGELOG.md              # Histórico de mudanças detalhado |-- CLAUDE.md                 # Configurações e integrações específicas para Claude Code |-- README.md                 # Guia principal de visão geral, features e instalação |-- package.json              # Metadados do pacote npm/CLI claude-flow`

## Ecosystem Tools

- **RuVector**: engine de memória vetorial em Rust/WASM com backend PostgreSQL, oferecendo busca HNSW de alta performance para memória compartilhada dos agentes.[[github](https://github.com/ruvnet/claude-flow)]​
    
- **Agentic-Flow**: infraestrutura core de "agentic engineering" usada pelo Claude-Flow para versionamento, pipelines e integrações avançadas.[[github](https://github.com/ruvnet/claude-flow)]​
    
- __Agentic-Jujutsu, Flow Nexus, Stream-Chain, @claude-flow/_ packages_*: módulos satélites para versionamento de estados, integração cloud, pipelines multi‑agente e benchmarking/performance.[[github](https://github.com/ruvnet/claude-flow)]​
    
- **Agentics Foundation Discord**: comunidade oficial para suporte, exemplos e discussões de arquitetura.[[github](https://github.com/ruvnet/claude-flow)]​
    

---

## Instalação

## Opção 1: One-Line Install (recomendado)

bash

`# Installer com barra de progresso curl -fsSL https://cdn.jsdelivr.net/gh/ruvnet/claude-flow@main/scripts/install.sh | bash # Setup completo (global + MCP + diagnostics) curl -fsSL https://cdn.jsdelivr.net/gh/ruvnet/claude-flow@main/scripts/install.sh | bash -s -- --full`

## Opção 2: npm/npx / Bun

bash

`# Quick start sem instalar globalmente npx claude-flow@alpha init # Instalar globalmente via npm npm install -g claude-flow@alpha claude-flow init # Usando Bun (mais rápido) bunx claude-flow@alpha init`

## Perfis De Instalação

bash

`# Instalação mínima (sem módulos opcionais de ML/embeddings) npm install -g claude-flow@alpha --omit=optional`

---

## Configuração

1. **Pré‑requisitos Claude Code**
    
    - Instale o Claude Code globalmente:
        
    
    bash
    
    `npm install -g @anthropic-ai/claude-code`
    
    - Opcional: pular o permissions check para setup mais rápido:
        
    
    bash
    
    `claude --dangerously-skip-permissions`
    

[[github](https://github.com/ruvnet/claude-flow)]​

2. **Integração MCP com Claude Code**
    

bash

`# Adicionar Claude-Flow como MCP server claude mcp add claude-flow -- npx -y claude-flow@latest mcp start # Verificar se está ativo claude mcp list`

3. **Configurações e memória**
    
    - RuVector PostgreSQL é o backend recomendado para memória vetorial; a pasta `docs/ruvector-postgres` traz instruções de setup.[[github](https://github.com/ruvnet/claude-flow)]​
        
    - Variáveis de ambiente e opções avançadas ficam documentadas na seção "Environment Variables / Configuration Reference" do README.[[github](https://github.com/ruvnet/claude-flow)]​
        

---

## Fluxos E Casos De Uso

- **Swarm de agentes para desenvolvimento de features**  
    Use `npx claude-flow@alpha init` para preparar o projeto e, em seguida, rode tarefas com agentes especializados (`--agent coder`, `--agent reviewer`, etc.) que se coordenam em swarm para implementar funcionalidades complexas.[[github](https://github.com/ruvnet/claude-flow)]​
    
- **Integração direta com Claude Code via MCP**  
    Após adicionar o MCP server, o Claude Code passa a enxergar mais de 175 tools (`swarm_init`, `agent_spawn`, `memory_search`, `hooks_route`, etc.), permitindo orquestrar times de agentes sem sair da IDE.[[github](https://github.com/ruvnet/claude-flow)]​
    
- **Roteamento inteligente entre modelos e tasks**  
    O core de routing aprende com o uso, roteando tarefas para os agentes e modelos mais eficientes (Claude, GPT, Gemini, Llama, locais), reduzindo custo e tempo de resposta em tarefas recorrentes.[[github](https://github.com/ruvnet/claude-flow)]​
    
- **Memória persistente e collective knowledge**  
    Swarms usam RuVector para armazenar padrões, decisões e contexto, permitindo que sessões futuras reaproveitem conhecimento e melhorem a qualidade de entregas ao longo do tempo.[[github](https://github.com/ruvnet/claude-flow)]​
    
- **Operações e automações de background**  
    Workers e hooks são disparados por eventos (mudança de arquivos, padrões detectados, sessões), permitindo automações como testes, verificações de segurança e atualizações de documentação de forma contínua.[[github](https://github.com/ruvnet/claude-flow)]​
    

---

## Requisitos E Compatibilidade

- Node.js 20+ (obrigatório).[[github](https://github.com/ruvnet/claude-flow)]​
    
- npm 9+, pnpm ou bun.[[github](https://github.com/ruvnet/claude-flow)]​
    
- Claude Code instalado globalmente para usar a integração MCP.[[github](https://github.com/ruvnet/claude-flow)]​
    
- Para memória vetorial de alta performance, um PostgreSQL configurado para RuVector (ver docs/ruvector-postgres).[[github](https://github.com/ruvnet/claude-flow)]​
    

---

## Links Úteis

|Recurso|Link|
|---|---|
|Repositório|[https://github.com/ruvnet/claude-flow](https://github.com/ruvnet/claude-flow) [[github](https://github.com/ruvnet/claude-flow)]​|
|Documentação / README|Seção principal do README no próprio repositório (overview, features, instalação). [[github](https://github.com/ruvnet/claude-flow)]​|
|Wiki|[https://github.com/ruvnet/claude-flow/wiki](https://github.com/ruvnet/claude-flow/wiki) (detalhes adicionais de arquitetura e módulos). [[github](https://github.com/ruvnet/claude-flow)]​|
|Issues|[https://github.com/ruvnet/claude-flow/issues](https://github.com/ruvnet/claude-flow/issues) [[github](https://github.com/ruvnet/claude-flow)]​|
|Releases|[https://github.com/ruvnet/claude-flow/releases](https://github.com/ruvnet/claude-flow/releases) [[github](https://github.com/ruvnet/claude-flow)]​|
|Site / Consultoria|[https://ruv.io/](https://ruv.io/) (implementação profissional e integrações enterprise). [[github](https://github.com/ruvnet/claude-flow)]​|
|Comunidade (Discord)|[https://discord.com/invite/dfxmpwkG2D](https://discord.com/invite/dfxmpwkG2D) [[github](https://github.com/ruvnet/claude-flow)]​', 'https://github.com/ruvnet/claude-flow', NULL);
INSERT INTO resources_bflabs_ide_powerup (id, category_id, name, slug, short_description, long_description, repo_url, website_url) VALUES ('7d807bc5-1e70-4566-9365-093964e56966', '0057a728-fe56-4a9b-ad82-b28872b5e0f3', '05 - n8n-MCP ]​', '05-n8n-mcp', '**Servidor MCP focado em n8n que dá ao seu assistente de IA acesso profundo à documentação, propriedades, operações e templates de mais de mil nós par...', '**Servidor MCP focado em n8n que dá ao seu assistente de IA acesso profundo à documentação, propriedades, operações e templates de mais de mil nós para construir, validar e gerenciar workflows de automação em produção.**[[github](https://github.com/czlonkowski/n8n-mcp)]​

---

## The Guides

Este repositório é principalmente código, configuração e infraestrutura para rodar um servidor MCP especializado em n8n, com foco em uso direto via Claude Desktop, IDEs e integrações self‑hosted. A explicação prática de como instalar, configurar e plugar nas suas ferramentas está detalhada a seguir, com referências para docs externas completas.[[github](https://github.com/czlonkowski/n8n-mcp)]​

|Tipo|Link|
|---|---|
|Visão Geral Rápida|Seções "🚀 Quick Start" e "🏠 Self-Hosting Options" desta doc/README. [[github](https://github.com/czlonkowski/n8n-mcp)]​|
|Guia Detalhado|Docs em `docs/` (ex.: N8N_DEPLOYMENT, CLAUDE_CODE_SETUP, etc.). [[github](https://github.com/czlonkowski/n8n-mcp)]​|

---

## Topics / What You''ll Learn

|Tópico|O que você aprende / consegue fazer|
|---|---|
|Conceito de MCP para n8n|Entender como o n8n‑MCP expõe documentação, propriedades, operações e templates de 1.084 nós n8n para uso por modelos de IA. [[github](https://github.com/czlonkowski/n8n-mcp)]​|
|Instalação via npx|Rodar o servidor MCP localmente, sem instalação prévia, usando `npx n8n-mcp` e conectá‑lo ao Claude Desktop. [[github](https://github.com/czlonkowski/n8n-mcp)]​|
|Instalação via Docker|Subir um container leve com o servidor MCP otimizado, configurando variáveis de ambiente e integração com n8n. [[github](https://github.com/czlonkowski/n8n-mcp)]​|
|Instalação local para desenvolvimento|Clonar o repo, instalar dependências, buildar e rodar o servidor MCP a partir do código‑fonte. [[github](https://github.com/czlonkowski/n8n-mcp)]​|
|Deploy em Railway|Fazer deploy em nuvem com um clique no Railway, obtendo URL pública para uso em qualquer cliente MCP. [[github](https://github.com/czlonkowski/n8n-mcp)]​|
|Integração com n8n|Conectar o servidor MCP a uma instância n8n (local ou cloud) e habilitar ferramentas de gestão de workflows. [[github](https://github.com/czlonkowski/n8n-mcp)]​|
|Integração com IDEs/clients MCP|Configurar Claude Desktop, Claude Code, VS Code, Cursor, Windsurf, Codex e Antigravity para usar o n8n‑MCP. [[github](https://github.com/czlonkowski/n8n-mcp)]​|
|Configuração de banco e memória|Escolher e tunar adaptadores SQLite (better‑sqlite3 ou sql.js) e parâmetros de memória para produção. [[github](https://github.com/czlonkowski/n8n-mcp)]​|
|Telemetria e privacidade|Entender quais métricas anônimas são coletadas e como desativar telemetria em diferentes modos de instalação. [[github](https://github.com/czlonkowski/n8n-mcp)]​|
|Boas práticas e validação de workflows|Aplicar estratégias de templates‑first, validação multi‑nível e uso seguro de IA para modificar workflows n8n. [[github](https://github.com/czlonkowski/n8n-mcp)]​|

---

## Cross-Platform Support

O projeto roda em qualquer ambiente que suporte Node.js e/ou Docker: Windows, macOS e Linux, tanto em desktops quanto em servidores. O fluxo recomendado é usar **npx** ou **Docker** localmente, e Railway ou outro provedor para deploy cloud.[[github](https://github.com/czlonkowski/n8n-mcp)]​

Principais modos de setup:[[github](https://github.com/czlonkowski/n8n-mcp)]​

- **npx / Node.js:** executa `npx n8n-mcp` com Node instalado, usando um banco SQLite embarcado.
    
- **Docker:** usa a imagem `ghcr.io/czlonkowski/n8n-mcp:latest`, com `MCP_MODE=stdio` e outras envs passadas via `docker run` ou `docker-compose`.
    
- **Local dev:** clone do repositório + `npm install`, `npm run build`, `npm start`, apontando o cliente MCP para `dist/mcp/index.js`.
    

---

## What''s Inside

bash

`n8n-mcp/ ├─ .claude/agents/           # Agentes/skills de sistema para orientar o uso ideal do n8n-MCP por modelos Claude. [page:1] ├─ data/                     # Base de dados pré‑construída com metadados de nós, docs, templates e exemplos do n8n. [page:1] ├─ deploy/                   # Arquivos de apoio para integrações MCP client e n8n (inclui configuração para client tool). [page:1] ├─ dist/                     # Build compilado do servidor MCP (entrypoint usado em produção e na integração local). [page:1] ├─ docker/                   # Scripts/entrypoints e configs Docker específicos (permissões, health, etc.). [page:1] ├─ docs/                     # Guias detalhados: Docker, Railway, n8n deployment, IDEs, troubleshooting. [page:1] ├─ examples/                 # Exemplos de servidor/documentação MCP e fluxos de uso. [page:1] ├─ scripts/                  # Scripts auxiliares: validações, ajustes de build, suporte a Docker/CI. [page:1] ├─ src/                      # Código‑fonte do servidor MCP, ferramentas, integração com banco e n8n. [page:1] ├─ tests/                    # Testes unitários, integração e benchmarks para garantir estabilidade. [page:1] ├─ types/                    # Tipagens TypeScript compartilhadas entre módulos. [page:1] ├─ docker-compose*.yml       # Vários cenários de docker-compose, incluindo n8n, buildkit, testes. [page:1] ├─ .env*.example             # Modelos de configuração de ambiente para Docker, n8n e testes. [page:1] ├─ N8N_HTTP_STREAMABLE_SETUP.md  # Guia de configuração de HTTP streaming com n8n. [page:1] ├─ CLAUDE.md                 # Instruções específicas de uso com Claude Projects/Claude Desktop. [page:1] ├─ README_ANALYSIS.md        # Referência rápida para análise/validação baseada em telemetria. [page:1] └─ package.json              # Metadados do pacote npm, scripts, dependências e versão. [page:1]`

---

## Ecosystem Tools

- **dashboard.n8n-mcp.com:** serviço hospedado que oferece o n8n‑MCP como API gerenciada, com tier gratuito e base sempre atualizada de nós/templates.[[github](https://github.com/czlonkowski/n8n-mcp)]​
    
- **Imagem Docker `ghcr.io/czlonkowski/n8n-mcp`:** container enxuto que roda apenas o servidor MCP com banco pré‑construído, ideal para produção e ambientes isolados.[[github](https://github.com/czlonkowski/n8n-mcp)]​
    
- **Railway Deployment:** template de deploy que sobe o servidor MCP em ambiente cloud com HTTPS, autoscaling e monitoramento de logs nativos.[[github](https://github.com/czlonkowski/n8n-mcp)]​
    
- **n8n‑skills (repositório externo):** coleção de skills para Claude que ensinam a IA a criar workflows n8n de produção usando o n8n‑MCP como fonte de verdade.[[github](https://github.com/czlonkowski/n8n-mcp)]​
    
- **Guias para IDEs (Claude Code, VS Code, Cursor, Windsurf, Codex, Antigravity):** docs em `docs/` que mostram como plugar o servidor MCP em cada ferramenta via configuração de MCP server.[[github](https://github.com/czlonkowski/n8n-mcp)]​
    

---

## Instalação

## Opção 1: Serviço Hospedado (Plugin / Ferramenta Externa)

Sem infraestrutura, via painel:[[github](https://github.com/czlonkowski/n8n-mcp)]​

1. Acesse `https://dashboard.n8n-mcp.com/`.[[github](https://github.com/czlonkowski/n8n-mcp)]​
    
2. Crie sua conta, gere uma API key.[[github](https://github.com/czlonkowski/n8n-mcp)]​
    
3. Configure seu cliente MCP (Claude Desktop ou outro) apontando para o endpoint e usando a key fornecida (conforme instruções do dashboard).[[github](https://github.com/czlonkowski/n8n-mcp)]​
    

## Opção 2: Npx (Local Rápido, Zero Install)

Pré‑requisito: Node.js instalado.[[github](https://github.com/czlonkowski/n8n-mcp)]​

bash

`# Rodar diretamente, sem instalar global npx n8n-mcp`

No Claude Desktop (`claude_desktop_config.json`), configuração básica:[[github](https://github.com/czlonkowski/n8n-mcp)]​

json

`{   "mcpServers": {    "n8n-mcp": {      "command": "npx",      "args": ["n8n-mcp"],      "env": {        "MCP_MODE": "stdio",        "LOG_LEVEL": "error",        "DISABLE_CONSOLE_OUTPUT": "true"      }    }  } }`

Para incluir ferramentas de gestão do n8n (com API):[[github](https://github.com/czlonkowski/n8n-mcp)]​

json

`{   "mcpServers": {    "n8n-mcp": {      "command": "npx",      "args": ["n8n-mcp"],      "env": {        "MCP_MODE": "stdio",        "LOG_LEVEL": "error",        "DISABLE_CONSOLE_OUTPUT": "true",        "N8N_API_URL": "https://your-n8n-instance.com",        "N8N_API_KEY": "your-api-key"      }    }  } }`

## Opção 3: Docker (Isolado E Reprodutível)

Pré‑requisito: Docker instalado.[[github](https://github.com/czlonkowski/n8n-mcp)]​

bash

`# Baixar imagem docker pull ghcr.io/czlonkowski/n8n-mcp:latest`

Configuração básica no Claude Desktop:[[github](https://github.com/czlonkowski/n8n-mcp)]​

json

`{   "mcpServers": {    "n8n-mcp": {      "command": "docker",      "args": [        "run",        "-i",        "--rm",        "--init",        "-e", "MCP_MODE=stdio",        "-e", "LOG_LEVEL=error",        "-e", "DISABLE_CONSOLE_OUTPUT=true",        "ghcr.io/czlonkowski/n8n-mcp:latest"      ]    }  } }`

Com integração à API do n8n:[[github](https://github.com/czlonkowski/n8n-mcp)]​

json

`{   "mcpServers": {    "n8n-mcp": {      "command": "docker",      "args": [        "run",        "-i",        "--rm",        "--init",        "-e", "MCP_MODE=stdio",        "-e", "LOG_LEVEL=error",        "-e", "DISABLE_CONSOLE_OUTPUT=true",        "-e", "N8N_API_URL=https://your-n8n-instance.com",        "-e", "N8N_API_KEY=your-api-key",        "ghcr.io/czlonkowski/n8n-mcp:latest"      ]    }  } }`

Para n8n local via Docker na mesma máquina (com webhooks moderados):[[github](https://github.com/czlonkowski/n8n-mcp)]​

json

`{   "mcpServers": {    "n8n-mcp": {      "command": "docker",      "args": [        "run",        "-i",        "--rm",        "--init",        "-e", "MCP_MODE=stdio",        "-e", "LOG_LEVEL=error",        "-e", "DISABLE_CONSOLE_OUTPUT=true",        "-e", "N8N_API_URL=http://host.docker.internal:5678",        "-e", "N8N_API_KEY=your-api-key",        "-e", "WEBHOOK_SECURITY_MODE=moderate",        "ghcr.io/czlonkowski/n8n-mcp:latest"      ]    }  } }`

## Opção 4: Instalação Local (Dev)

Pré‑requisito: Node.js instalado.[[github](https://github.com/czlonkowski/n8n-mcp)]​

bash

`# 1. Clonar e preparar git clone https://github.com/czlonkowski/n8n-mcp.git cd n8n-mcp npm install npm run build npm run rebuild # 2. Testar npm start`

Configuração no Claude Desktop (básica):[[github](https://github.com/czlonkowski/n8n-mcp)]​

json

`{   "mcpServers": {    "n8n-mcp": {      "command": "node",      "args": ["/absolute/path/to/n8n-mcp/dist/mcp/index.js"],      "env": {        "MCP_MODE": "stdio",        "LOG_LEVEL": "error",        "DISABLE_CONSOLE_OUTPUT": "true"      }    }  } }`

---

## Configuração

## Arquivos De Configuração Do Cliente

Locais típicos do arquivo `claude_desktop_config.json`:[[github](https://github.com/czlonkowski/n8n-mcp)]​

- macOS: `~/Library/Application Support/Claude/claude_desktop_config.json`
    
- Windows: `%APPDATA%\Claude\claude_desktop_config.json`
    
- Linux: `~/.config/Claude/claude_desktop_config.json`
    

Após ajustar o bloco `mcpServers`, é necessário reiniciar o Claude Desktop.[[github](https://github.com/czlonkowski/n8n-mcp)]​

## Arquivos De Ambiente Do Servidor

O repositório inclui exemplos:[[github](https://github.com/czlonkowski/n8n-mcp)]​

- `.env.example`: base para configurar envs gerais do servidor MCP (incluindo integração com n8n).
    
- `.env.docker`: config padrão para Docker, com variáveis como `DISABLED_TOOLS`.
    
- `.env.n8n.example`: exemplo focado na integração com n8n (URL, API key, etc.).
    
- `.env.test.example`: ambiente para execução de testes e benchmarks.
    

Crie seu `.env` a partir dos exemplos e preencha valores sensíveis (URLs, chaves, flags).[[github](https://github.com/czlonkowski/n8n-mcp)]​

## Variáveis De Ambiente Importantes

- `MCP_MODE=stdio`: obrigatório em clientes MCP baseados em stdio, especialmente Claude Desktop.[[github](https://github.com/czlonkowski/n8n-mcp)]​
    
- `LOG_LEVEL=error`: reduz ruído de logs e evita interferência no protocolo MCP.[[github](https://github.com/czlonkowski/n8n-mcp)]​
    
- `DISABLE_CONSOLE_OUTPUT=true`: garante que apenas mensagens JSON-RPC sejam enviadas para stdout.[[github](https://github.com/czlonkowski/n8n-mcp)]​
    
- `N8N_API_URL`: URL da sua instância n8n (local, Docker ou cloud).[[github](https://github.com/czlonkowski/n8n-mcp)]​
    
- `N8N_API_KEY`: chave da API n8n para permitir criação, atualização e execução de workflows.[[github](https://github.com/czlonkowski/n8n-mcp)]​
    
- `WEBHOOK_SECURITY_MODE=moderate`: habilita webhooks para localhost mantendo proteção contra redes privadas/metadata.[[github](https://github.com/czlonkowski/n8n-mcp)]​
    
- `N8N_MCP_TELEMETRY_DISABLED=true`: desativa telemetria anônima.[[github](https://github.com/czlonkowski/n8n-mcp)]​
    
- `SQLJS_SAVE_INTERVAL_MS`: define intervalo de persistência para o adaptador sql.js quando usado.[[github](https://github.com/czlonkowski/n8n-mcp)]​
    
- `N8N_MCP_MAX_SESSIONS`: configura o limite de sessões simultâneas (definido em CLAUDE.md).[[github](https://github.com/czlonkowski/n8n-mcp)]​
    

---

## Fluxos E Casos De Uso

- **Explorar documentação de nós n8n com IA para desenhar workflows.**  
    O usuário conversa com Claude (ou outro cliente MCP), que usa o n8n‑MCP para buscar nós, propriedades, operações e docs em markdown, sugerindo arquitetura de workflow e melhores práticas antes de qualquer alteração em produção.[[github](https://github.com/czlonkowski/n8n-mcp)]​
    
- **Validar e ajustar workflows n8n existentes com segurança.**  
    A IA consulta templates e funções de validação para revisar configurações de nós, evitar defaults perigosos, validar conexões/expressões e só então propor alterações, sempre sobre cópias de workflows.[[github](https://github.com/czlonkowski/n8n-mcp)]​
    
- **Criar novos workflows baseados em templates oficiais e comunidade.**  
    O cliente MCP pesquisa entre 2.709 templates, filtra por complexidade, serviço e papel, e instancia workflows adaptados ao contexto do negócio, com foco em time‑to‑value rápido.[[github](https://github.com/czlonkowski/n8n-mcp)]​
    
- **Gerenciar workflows via API do n8n (quando configurado).**  
    Com `N8N_API_URL` e `N8N_API_KEY` definidos, a IA pode criar, atualizar, validar e testar workflows diretamente na instância n8n, seguindo a estratégia de validação multi‑nível documentada.[[github](https://github.com/czlonkowski/n8n-mcp)]​
    
- **Integração com IDEs para desenvolvimento assistido.**  
    Em IDEs como Claude Code, VS Code, Cursor ou Windsurf, o n8n‑MCP é usado como ferramenta de contexto: o assistente entende o ambiente n8n, sugere nós e monta workflows enquanto o dev itera no código e na automação.[[github](https://github.com/czlonkowski/n8n-mcp)]​
    

---

## Requisitos E Compatibilidade

- **Node.js:** necessário para uso via npx ou instalação local; o projeto utiliza versões modernas (a imagem Docker de teste já está baseada em Node 22 LTS).[[github](https://github.com/czlonkowski/n8n-mcp)]​
    
- **Docker:** recomendado para isolamento e reprodutibilidade em ambientes de servidor ou desktop.[[github](https://github.com/czlonkowski/n8n-mcp)]​
    
- **Banco de dados:** SQLite embarcado, com adaptadores `better-sqlite3` (padrão em Docker) ou `sql.js` como fallback.[[github](https://github.com/czlonkowski/n8n-mcp)]​
    
- **n8n (opcional):** requerido apenas se você desejar ferramentas de gestão de workflows via API; a documentação acompanha atualizações frequentes da versão do n8n.[[github](https://github.com/czlonkowski/n8n-mcp)]​
    
- **Clientes MCP:** Claude Desktop, Claude Code, VS Code, Cursor, Windsurf, Codex, Antigravity e quaisquer outros compatíveis com MCP stdio.[[github](https://github.com/czlonkowski/n8n-mcp)]​
    

Dependências externas como Postgres ou Redis não são exigidas pelo servidor MCP em si; a responsabilidade de infraestrutura extra recai sobre sua instância n8n, caso usada.[[github](https://github.com/czlonkowski/n8n-mcp)]​

---

## Links Úteis

| Tipo                | Link                                                                                                                                                                              |
| ------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Repositório         | [https://github.com/czlonkowski/n8n-mcp](https://github.com/czlonkowski/n8n-mcp) [[github](https://github.com/czlonkowski/n8n-mcp)]​                                              |
| Documentação / Wiki | Diretório `docs/` no próprio repositório (Docker, Railway, IDEs, n8n). [[github](https://github.com/czlonkowski/n8n-mcp)]​                                                        |
| Issues              | [https://github.com/czlonkowski/n8n-mcp/issues](https://github.com/czlonkowski/n8n-mcp/issues) [[github](https://github.com/czlonkowski/n8n-mcp)]​                                |
| Comunidade          | Discussões GitHub em [https://github.com/czlonkowski/n8n-mcp/discussions](https://github.com/czlonkowski/n8n-mcp/discussions) [[github](https://github.com/czlonkowski/n8n-mcp)]​ |
| Site / Comercial    | Serviço hosted em [https://dashboard.n8n-mcp.com](https://dashboard.n8n-mcp.com/) [[github](https://github.com/czlonkowski/n8n-mcp)]​                                             |', 'https://github.com/czlonkowski/n8n-mcp', NULL);
INSERT INTO resources_bflabs_ide_powerup (id, category_id, name, slug, short_description, long_description, repo_url, website_url) VALUES ('24517d0d-82f9-47ed-9600-65c58a92aef4', 'cc50662d-853b-4bac-b2d6-712b7b93d3d7', 'Auto Claude ]​', 'auto-claude', '**Framework autônomo de multi-agentes que planeja, implementa e valida tarefas de desenvolvimento em projetos Git, com interface desktop e CLI para ro...', '**Framework autônomo de multi-agentes que planeja, implementa e valida tarefas de desenvolvimento em projetos Git, com interface desktop e CLI para rodar “maratonas” de coding assistido por Claude.**[[github](https://github.com/AndyMik90/Auto-Claude)]​

---

#### The Guides

Este repositório é principalmente uma aplicação desktop + backend de agentes Python, com foco em executar tarefas autônomas de desenvolvimento dentro de um repositório Git.[[github](https://github.com/AndyMik90/Auto-Claude)]​  
Abaixo você encontra uma visão geral prática de arquitetura, instalação, fluxo de uso e scripts essenciais para colocar o Auto Claude para trabalhar em projetos reais.[[github](https://github.com/AndyMik90/Auto-Claude)]​

|Tipo|Link|
|---|---|
|Visão Geral Rápida|Seções “Quick Start” e “Features”|
|Guia Detalhado|`CLAUDE.md`, `guides/CLI-USAGE.md`, `guides/linux.md`|

[[github](https://github.com/AndyMik90/Auto-Claude)]​

---

## Topics / What You’ll Learn

|Tópico|O que você aprende / consegue fazer|
|---|---|
|Arquitetura de Agentes|Entender como backend Python, terminais de agentes e memória trabalham juntos no fluxo autônomo. [[github](https://github.com/AndyMik90/Auto-Claude)]​|
|Kanban & Gestão de Tarefas|Usar o board interno para criar tasks, acompanhar status e orquestrar múltiplas execuções. [[github](https://github.com/AndyMik90/Auto-Claude)]​|
|Integração com Claude Code|Conectar via Claude Pro/Max + Claude Code CLI para habilitar agentes com acesso ao seu código. [[github](https://github.com/AndyMik90/Auto-Claude)]​|
|Execução Autônoma (CLI)|Rodar builds autônomos headless via `run.py` e specs configuráveis para CI/CD ou servidores. [[github](https://github.com/AndyMik90/Auto-Claude)]​|
|Worktrees & Segurança|Isolar mudanças em git worktrees para proteger a `main` e aplicar o modelo de sandbox em camadas. [[github](https://github.com/AndyMik90/Auto-Claude)]​|
|QA e Auto‑Merge|Deixar o sistema validar, revisar e mesclar código com loops de QA embutidos. [[github](https://github.com/AndyMik90/Auto-Claude)]​|
|Integrações com Git Hosts|Conectar GitHub/GitLab/Linear para importar issues e gerar merge requests/PRs de forma automatizada. [[github](https://github.com/AndyMik90/Auto-Claude)]​|
|Desenvolvimento & Build|Construir e empacotar a aplicação desktop para Windows, macOS e Linux usando scripts npm. [[github](https://github.com/AndyMik90/Auto-Claude)]​|
|Testes e Qualidade|Rodar testes frontend e backend com scripts dedicados e linting integrado. [[github](https://github.com/AndyMik90/Auto-Claude)]​|
|Guia de Contribuição|Seguir padrões de contribuição, estilo e processos de PR definidos no projeto. [[github](https://github.com/AndyMik90/Auto-Claude)]​|

---

## Cross-Platform Support

O Auto Claude oferece builds nativos para Windows, macOS (Intel e Apple Silicon) e Linux (AppImage, .deb e Flatpak), permitindo rodar o cliente desktop em praticamente qualquer ambiente de desenvolvimento.[[github](https://github.com/AndyMik90/Auto-Claude)]​  
A aplicação usa Node/npm para instalar dependências do frontend e empacotar o app, enquanto o backend de agentes roda em Python, operando sobre um repositório Git local.[[github](https://github.com/AndyMik90/Auto-Claude)]​

---

## What’s Inside

text

`Auto-Claude/ ├── apps/ │   ├── backend/        # Backend Python: agentes, specs, pipeline de QA e execução autônoma. [page:2] │   └── frontend/       # Aplicação desktop (Electron) com Kanban, terminais e UI de tarefas. [page:2] ├── guides/             # Documentação adicional (CLI, Linux, etc.). [page:2] ├── tests/              # Suite de testes para backend e frontend. [page:2] ├── scripts/            # Scripts de build, empacotamento e utilitários. [page:2] ├── .claude/commands/   # Comandos/configs específicos para interação com Claude Code. [page:2] ├── .design-system/     # Sistema de design compartilhado para a interface. [page:2] ├── run.py              # Entry point backend para rodar specs e builds autônomos. [page:2] ├── package.json        # Scripts npm para instalar deps, rodar, testar e empacotar o app. [page:2] ├── CHANGELOG.md        # Histórico de releases e mudanças relevantes. [page:2] ├── CLAUDE.md           # Guia detalhado de uso com Claude/Claude Code. [page:2] └── guides/linux.md     # Instruções específicas para build em Linux/Flatpak/AppImage. [page:2]`

---

## Ecosystem Tools

- **Claude Code CLI (`@anthropic-ai/claude-code`)** – requisito para integrar o Auto Claude com Claude, permitindo que os agentes acessem e modifiquem seu código via CLI oficial.[[github](https://github.com/AndyMik90/Auto-Claude)]​
    
- **GitHub/GitLab** – usados como origem de issues e destino de merge requests, permitindo que tarefas de produto/bug entrem diretamente no fluxo autônomo.[[github](https://github.com/AndyMik90/Auto-Claude)]​
    
- **Linear** – integração para sincronizar tasks de produto e acompanhar progresso do time a partir do board do Auto Claude.[[github](https://github.com/AndyMik90/Auto-Claude)]​
    
- **Discord & YouTube do projeto** – canais de comunidade, suporte e conteúdo educacional sobre uso avançado e novas features.[[github](https://github.com/AndyMik90/Auto-Claude)]​
    

---

## Instalação

## Opção 1: App Desktop (recomendado)

1. Acesse a seção de **Stable Release** e baixe o instalador da sua plataforma (Windows, macOS, Linux).[[github](https://github.com/AndyMik90/Auto-Claude)]​
    
2. Execute o instalador correspondente (`.exe`, `.dmg`, `.AppImage`, `.deb` ou `.flatpak`) e conclua a instalação padrão do sistema.[[github](https://github.com/AndyMik90/Auto-Claude)]​
    

## Opção 2: Desenvolvimento / build a partir do código

1. Clone o repositório:
    

bash

`git clone https://github.com/AndyMik90/Auto-Claude.git cd Auto-Claude`

2. Instale dependências de frontend e backend:
    

bash

`npm run install:all`

3. Rodar o app em modo desenvolvimento (desktop):
    

bash

`npm run dev`

4. Rodar o app em modo normal:
    

bash

`npm start`

5. Empacotar para sua plataforma (exemplos):
    

bash

`npm run package          # empacota para a plataforma atual npm run package:mac      # build para macOS npm run package:win      # build para Windows npm run package:linux    # build para Linux npm run package:flatpak  # build Flatpak (Linux)`

---

## Configuração

- **Pré‑requisitos de conta/ferramenta**
    
    - Assinatura **Claude Pro/Max** ativa.[[github](https://github.com/AndyMik90/Auto-Claude)]​
        
    - **Claude Code CLI** instalado globalmente:
        
        bash
        
        `npm install -g @anthropic-ai/claude-code`
        

[[github](https://github.com/AndyMik90/Auto-Claude)]​

- Projeto inicializado como repositório Git (o Auto Claude trabalha em cima de repos Git).[[github](https://github.com/AndyMik90/Auto-Claude)]​
    
- **Conexão com Claude**
    
    - Ao abrir o app pela primeira vez, selecione a pasta do repositório Git.[[github](https://github.com/AndyMik90/Auto-Claude)]​
        
    - Siga o fluxo de OAuth na UI para conectar sua conta Claude.[[github](https://github.com/AndyMik90/Auto-Claude)]​
        
- **Configuração de CLI/backend**
    
    - Para uso headless, entre em `apps/backend` e use `spec_runner.py` e `run.py` com os argumentos adequados para criar specs e rodar builds.[[github](https://github.com/AndyMik90/Auto-Claude)]​
        
    - Arquivos de configuração adicionais, perfis de agentes e fases de pipeline são definidos no backend, detalhados em `CLAUDE.md` e `guides/CLI-USAGE.md`.[[github](https://github.com/AndyMik90/Auto-Claude)]​
        
- **Segurança e sandbox**
    
    - O projeto aplica sandbox em três camadas: isolamento de comandos no SO, restrições de filesystem ao diretório do projeto e allowlist dinâmica de comandos por stack detectada.[[github](https://github.com/AndyMik90/Auto-Claude)]​
        

---

## Fluxos e Casos de Uso

- **Rodar uma tarefa autônoma de desenvolvimento a partir do app desktop**
    
    - Abra o Auto Claude, selecione seu repositório Git, conecte o Claude e crie uma nova task descrevendo a feature ou refactor desejado.[[github](https://github.com/AndyMik90/Auto-Claude)]​
        
    - A partir daí, os agentes planejam, escrevem código e executam QA, enquanto você acompanha no Kanban e nos terminais de agentes.[[github](https://github.com/AndyMik90/Auto-Claude)]​
        
- **Execução headless via CLI para uma spec específica**
    
    - No backend, crie uma spec interativa com `spec_runner.py` e, em seguida, dispare o build com `run.py --spec 001`.[[github](https://github.com/AndyMik90/Auto-Claude)]​
        
        bash
        
        `cd apps/backend python spec_runner.py --interactive python run.py --spec 001`
        

[[github](https://github.com/AndyMik90/Auto-Claude)]​

- Use flags adicionais para rodar revisão ou merge:
    
    bash
    
    `python run.py --spec 001 --review python run.py --spec 001 --merge`
    

[[github](https://github.com/AndyMik90/Auto-Claude)]​

- **Uso como “fábrica” de múltiplas tarefas em paralelo**
    
    - Crie várias tasks no Kanban, configurando prioridade e contexto; o sistema distribui trabalho entre até 12 terminais de agentes em paralelo.[[github](https://github.com/AndyMik90/Auto-Claude)]​
        
    - Ideal para gerar múltiplos testes, docs ou refactors em série em um mesmo repo.[[github](https://github.com/AndyMik90/Auto-Claude)]​
        
- **Integração com GitHub/GitLab/Linear**
    
    - Importe issues/tickets para o board, deixando que os agentes façam investigação, implementação e abram merge requests automaticamente.[[github](https://github.com/AndyMik90/Auto-Claude)]​
        
    - Esse fluxo reduz overhead de coordenação manual de backlog em times enxutos.[[github](https://github.com/AndyMik90/Auto-Claude)]​
        
- **Planejamento e roadmap assistido por IA**
    
    - Use a área de Roadmap para mapear features, comparar com concorrentes e organizar prioridades, alimentando o pipeline de tarefas do board.[[github](https://github.com/AndyMik90/Auto-Claude)]​
        

---

## Requisitos e Compatibilidade

- **Conta / API**
    
    - Assinatura **Claude Pro/Max**.[[github](https://github.com/AndyMik90/Auto-Claude)]​
        
- **Ferramentas obrigatórias**
    
    - **Claude Code CLI** instalado globalmente via npm.[[github](https://github.com/AndyMik90/Auto-Claude)]​
        
    - Repositório **Git** inicializado.[[github](https://github.com/AndyMik90/Auto-Claude)]​
        
- **Plataformas suportadas (desktop)**
    
    - Windows (installer `.exe`).[[github](https://github.com/AndyMik90/Auto-Claude)]​
        
    - macOS (Intel e Apple Silicon, `.dmg` específicos).[[github](https://github.com/AndyMik90/Auto-Claude)]​
        
    - Linux (AppImage, `.deb` e Flatpak).[[github](https://github.com/AndyMik90/Auto-Claude)]​
        
- **Stacks internas**
    
    - Frontend/desktop: Node.js + Electron (scripts npm para build, dev e package).[[github](https://github.com/AndyMik90/Auto-Claude)]​
        
    - Backend: Python para agentes, specs e QA.[[github](https://github.com/AndyMik90/Auto-Claude)]​
        

---

## Links Úteis

|Recurso|Link|
|---|---|
|Repositório|[https://github.com/AndyMik90/Auto-Claude](https://github.com/AndyMik90/Auto-Claude)|
|README / Docs base|`README.md` e `CLAUDE.md` no próprio repositório|
|Documentação CLI|`guides/CLI-USAGE.md`|
|Docs Linux|`guides/linux.md`|
|Issues|[https://github.com/AndyMik90/Auto-Claude/issues](https://github.com/AndyMik90/Auto-Claude/issues)|
|Discussões|[https://github.com/AndyMik90/Auto-Claude/discussions](https://github.com/AndyMik90/Auto-Claude/discussions)|
|Comunidade (Discord)|[https://discord.gg/KCXaPBr4Dj](https://discord.gg/KCXaPBr4Dj)|
|Releases|[https://github.com/AndyMik90/Auto-Claude/releases](https://github.com/AndyMik90/Auto-Claude/releases)|
|Canal YouTube|[https://www.youtube.com/@AndreMikalsen](https://www.youtube.com/@AndreMikalsen)|', 'https://github.com/AndyMik90/Auto-Claude', NULL);
INSERT INTO resources_bflabs_ide_powerup (id, category_id, name, slug, short_description, long_description, repo_url, website_url) VALUES ('921f2046-8416-47f0-8670-9b512d901e1b', '0057a728-fe56-4a9b-ad82-b28872b5e0f3', 'Marketing Skills for Claude Code ]​', 'marketing-skills-for-claude-code', '**Coleção de skills em Markdown que dão superpoderes de marketing para Claude Code e outros agentes de IA, focando em CRO, copywriting, SEO, analytics...', '**Coleção de skills em Markdown que dão superpoderes de marketing para Claude Code e outros agentes de IA, focando em CRO, copywriting, SEO, analytics e growth engineering em produtos digitais reais.**[[github](https://github.com/coreyhaines31/marketingskills)]​

---

#### The Guides

Este repositório é basicamente um catálogo organizado de skills em Markdown que você instala no ambiente do Claude Code (ou via CLIs compatíveis) para que o agente entenda e execute tarefas de marketing com frameworks prontos. Não é um app standalone: ele funciona como “camada de conhecimento + playbooks” plugável nos seus projetos. A explicação prática de uso está nas seções de instalação, categorias de skills e exemplos de uso logo abaixo.[[github](https://github.com/coreyhaines31/marketingskills)]​

Como não há wiki interna extensa, use estas âncoras dentro desta própria doc:

|Tipo|Link|
|---|---|
|Visão Geral Rápida|[Instalação](https://www.perplexity.ai/sidecar/search/voce-esta-com-acesso-ao-reposi-OxjBWHhKSmuLf085JIwxTg#instala%C3%A7%C3%A3o)|
|Guia Detalhado|[Fluxos e Casos de Uso](https://www.perplexity.ai/sidecar/search/voce-esta-com-acesso-ao-reposi-OxjBWHhKSmuLf085JIwxTg#fluxos-e-casos-de-uso)|

Além disso, há o site externo [marketing-skills.com](https://marketing-skills.com/) com visão geral pública do projeto.[[github](https://github.com/coreyhaines31/marketingskills)]​

---

#### Topics / What You’ll Learn

|Tópico|O que você aprende / consegue fazer|
|---|---|
|Skills de Marketing para Agentes|Entender o conceito de “skills” em Markdown e como elas dão contexto e workflows específicos para Claude Code e outros agentes. [[github](https://github.com/coreyhaines31/marketingskills)]​|
|Conversão (CRO) em Páginas, Formulários e Fluxos|Otimizar landing pages, fluxos de cadastro, onboarding e formulários usando skills como `page-cro`, `signup-flow-cro`, `onboarding-cro`, `form-cro`, `popup-cro` e `paywall-upgrade-cro`. [[github](https://github.com/coreyhaines31/marketingskills)]​|
|Copywriting, E-mail e Conteúdo|Escrever e revisar copy para páginas, e-mails e redes sociais com skills como `copywriting`, `copy-editing`, `email-sequence` e `social-content`. [[github](https://github.com/coreyhaines31/marketingskills)]​|
|SEO Técnico, Programático e Conteúdo de Descoberta|Rodar auditorias de SEO, planejar programmatic SEO e criar páginas de comparação/alternativas com `seo-audit`, `programmatic-seo`, `competitor-alternatives` e `schema-markup`. [[github](https://github.com/coreyhaines31/marketingskills)]​|
|Paid Media e Distribuição|Pedir ajuda estruturada para campanhas em Google Ads, Meta, LinkedIn e distribuição orgânica com `paid-ads` e `social-content`. [[github](https://github.com/coreyhaines31/marketingskills)]​|
|Analytics, Tracking e Experimentação|Configurar e revisar tracking (ex.: GA4, eventos) e estruturar experimentos com `analytics-tracking` e `ab-test-setup`. [[github](https://github.com/coreyhaines31/marketingskills)]​|
|Growth Engineering e Ferramentas Gratuitas|Planejar e desenhar free tools, calculadoras e programas de indicação via `free-tool-strategy` e `referral-program`. [[github](https://github.com/coreyhaines31/marketingskills)]​|
|Estratégia, Pricing e Lançamentos|Usar skills como `marketing-ideas`, `marketing-psychology`, `launch-strategy` e `pricing-strategy` para decisões de go-to-market e monetização. [[github](https://github.com/coreyhaines31/marketingskills)]​|
|Integração com Claude Code / Plugins|Instalar o pacote via CLI, plugin interno do Claude Code, submódulo Git ou SkillKit multi-agent, conectando facilmente ao seu workflow atual. [[github](https://github.com/coreyhaines31/marketingskills)]​|
|Colaboração e Contribuição|Entender como propor novas skills, melhorar existentes e manter um catálogo interno de marketing alinhado ao seu produto. [[github](https://github.com/coreyhaines31/marketingskills)]​|

---

## Cross-Platform Support

Este projeto é composto por arquivos de configuração e Markdown, portanto funciona em qualquer sistema que suporte Git e terminal (Windows, macOS, Linux e ambientes server-side). Como não há runtime próprio (Node app, Python service, etc.), a compatibilidade está ligada às ferramentas de instalação (npx, Git, SkillKit) e ao próprio editor/IDE onde o Claude Code roda.[[github](https://github.com/coreyhaines31/marketingskills)]​

Os principais caminhos de instalação são:

- Uso de `npx skills` (CLI mantido pela Vercel) para instalar diretamente na pasta `.claude/skills/`.[[github](https://github.com/coreyhaines31/marketingskills)]​
    
- Instalação como plugin pelo sistema interno do Claude Code via comandos `/plugin`.[[github](https://github.com/coreyhaines31/marketingskills)]​
    
- Clone e cópia direta do diretório `skills/` para `.claude/skills/` do seu projeto.[[github](https://github.com/coreyhaines31/marketingskills)]​
    
- Git submodule apontando para `.claude/marketingskills`.[[github](https://github.com/coreyhaines31/marketingskills)]​
    
- Uso do `npx skillkit` para instalação multi-agent (Claude Code, Cursor, Copilot etc.).[[github](https://github.com/coreyhaines31/marketingskills)]​
    

---

## What’s Inside

Estrutura simplificada para você entender o que importa:

bash

`marketingskills/ ├─ .claude-plugin/ │  └─ ...           # Configurações de plugin/marketplace para Claude Code reconhecer e instalar o pacote de skills. [page:1] ├─ .github/ │  └─ ...           # Templates de issues/PRs, configs de contribuição e automações do repositório. [page:1] ├─ skills/ │  ├─ ab-test-setup │  ├─ analytics-tracking │  ├─ page-cro │  ├─ signup-flow-cro │  ├─ seo-audit │  ├─ copywriting │  ├─ email-sequence │  ├─ social-content │  ├─ pricing-strategy │  └─ ...          # Cada entrada é uma skill de marketing em Markdown com instruções, triggers e contexto especializado. [page:1] ├─ tools/ │  └─ ...          # Arquivos auxiliares, incluindo registry de marketing tools para descoberta pelos agentes. [page:1] ├─ AGENTS.md       # Lista e contexto de agentes que podem usar essas skills, além de registry para discovery. [page:1] ├─ CLAUDE.md       # Guia específico de como usar as skills com Claude Code (plugin, configuração e exemplos). [page:1] ├─ CONTRIBUTING.md # Regras de contribuição, naming, frontmatter das skills e guidelines de PR. [page:1] ├─ LICENSE         # Licença MIT permitindo uso livre em projetos comerciais. [page:1] └─ README.md       # Visão geral, lista de skills, instalação e categorias de uso. [page:1]`

---

## Ecosystem Tools

Ferramentas satélites e integrações que conversam bem com este repositório:

- **Vercel Labs Skills CLI (`npx skills`)**: CLI que instala automaticamente as skills deste repo na pasta `.claude/skills/` do seu projeto, permitindo adicionar todas ou apenas algumas skills específicas.[[github](https://github.com/coreyhaines31/marketingskills)]​
    
- **Claude Code Plugin System**: Sistema de plugins interno do Claude Code que permite adicionar este marketplace (`coreyhaines31/marketingskills`) e instalar o pacote de marketing com comandos `/plugin`.[[github](https://github.com/coreyhaines31/marketingskills)]​
    
- **SkillKit (Multi-Agent)**: CLI (`npx skillkit`) para instalar essas skills simultaneamente em múltiplos agentes (Claude Code, Cursor, Copilot etc.), facilitando padronizar o mesmo “cérebro de marketing” em várias ferramentas.[[github](https://github.com/coreyhaines31/marketingskills)]​
    
- **Sites do Autor (Conversion Factory, Swipe Files, Coding for Marketers)**: Recursos educativos e de consultoria que complementam o uso das skills com estratégia, exemplos e aprofundamento em marketing.[[github](https://github.com/coreyhaines31/marketingskills)]​
    

---

## Instalação

## Opção 1: Instalar via CLI (Recomendado)

Use o [npx skills](https://github.com/vercel-labs/skills) para instalar as skills direto no seu projeto:[[github](https://github.com/coreyhaines31/marketingskills)]​

bash

`# Instalar todas as skills npx skills add coreyhaines31/marketingskills # Instalar skills específicas npx skills add coreyhaines31/marketingskills --skill page-cro copywriting # Listar skills disponíveis npx skills add coreyhaines31/marketingskills --list`

Isso instala automaticamente em `.claude/skills/` dentro do seu projeto.[[github](https://github.com/coreyhaines31/marketingskills)]​

## Opção 2: Plugin do Claude Code

Use o sistema de plugins do Claude Code:[[github](https://github.com/coreyhaines31/marketingskills)]​

bash

`# Adicionar o marketplace /plugin marketplace add coreyhaines31/marketingskills # Instalar todas as skills de marketing /plugin install marketing-skills`

## Opção 3: Instalação Manual (Clone e Cópia)

Clone o repositório e copie o diretório de skills para o seu projeto:[[github](https://github.com/coreyhaines31/marketingskills)]​

bash

`git clone https://github.com/coreyhaines31/marketingskills.git # Copiar apenas as skills para o diretório do Claude Code cp -r marketingskills/skills/ .claude/skills/`

## Opção 4: Git Submodule

Se quiser manter como dependência versionada:[[github](https://github.com/coreyhaines31/marketingskills)]​

bash

`git submodule add https://github.com/coreyhaines31/marketingskills.git .claude/marketingskills`

Depois, referencie as skills a partir de `.claude/marketingskills/skills/`.[[github](https://github.com/coreyhaines31/marketingskills)]​

## Opção 5: Fork e Customização

Para empresas que querem um catálogo próprio de skills:[[github](https://github.com/coreyhaines31/marketingskills)]​

1. Fork deste repositório no GitHub.[[github](https://github.com/coreyhaines31/marketingskills)]​
    
2. Ajuste as skills para o seu contexto (ICP, produto, linguagem, frameworks internos).[[github](https://github.com/coreyhaines31/marketingskills)]​
    
3. Clone seu fork nos projetos e instale/consuma as skills da mesma forma que o original.[[github](https://github.com/coreyhaines31/marketingskills)]​
    

## Opção 6: SkillKit (Multi-Agent)

Para usar em vários agentes (Claude Code, Cursor, Copilot, etc.):[[github](https://github.com/coreyhaines31/marketingskills)]​

bash

`# Instalar todas as skills npx skillkit install coreyhaines31/marketingskills # Instalar skills específicas npx skillkit install coreyhaines31/marketingskills --skill page-cro copywriting # Listar skills npx skillkit install coreyhaines31/marketingskills --list`

---

## Configuração

A configuração principal é estrutural: garantir que os arquivos de skill estejam acessíveis no caminho esperado pelo agente (geralmente `.claude/skills/` ou pastas configuradas pela CLI/IDE).[[github](https://github.com/coreyhaines31/marketingskills)]​

Pontos de atenção:

- **Diretório `.claude/skills/`**: Quando instala via `npx skills`, as skills já são copiadas para este diretório, pronto para Claude Code usar.[[github](https://github.com/coreyhaines31/marketingskills)]​
    
- **Plugin / Marketplace**: Ao adicionar o marketplace (`/plugin marketplace add ...`) e instalar (`/plugin install marketing-skills`), o Claude Code passa a carregar automaticamente essas skills quando detectar tarefas de marketing.[[github](https://github.com/coreyhaines31/marketingskills)]​
    
- **Submódulo Git**: Se usar `.claude/marketingskills`, a configuração é apenas apontar o Claude Code ou sua ferramenta de skills para também ler esse caminho.[[github](https://github.com/coreyhaines31/marketingskills)]​
    

Não há `.env` nem variáveis de ambiente obrigatórias no repositório em si; integrações com GA4, ads, etc., são descritas nas skills em nível de instrução, não de código. Para detalhes específicos de uso com Claude Code, consulte o arquivo `CLAUDE.md` na raiz do repo.[[github](https://github.com/coreyhaines31/marketingskills)]​

---

## Fluxos e Casos de Uso

- **Otimizar uma landing page de SaaS para conversão**  
    Peça algo como “otimize esta landing page para aumentar conversão de trial” e deixe o agente acionar a skill `page-cro`, que traz frameworks de CRO, seções ideais, provas sociais e recomendações de layout. Você também pode invocar diretamente `/page-cro` no Claude Code para trabalhar em cima de um HTML ou texto.[[github](https://github.com/coreyhaines31/marketingskills)]​
    
- **Criar ou revisar uma sequência de e-mails de onboarding**  
    Solicite “crie uma sequência de 5 e-mails de welcome para este produto” e o agente utilizará a skill `email-sequence` para estruturar objetivos, cadência, CTAs e mensagens. Você pode iterar a copy usando `copy-editing` para polir o texto final.[[github](https://github.com/coreyhaines31/marketingskills)]​
    
- **Configurar tracking de eventos (ex.: GA4) para um funil**  
    Use comandos como “defina o tracking de signup, onboarding e upgrade no GA4 para este app” e o agente acionará `analytics-tracking`, que vem com checklists e padrões de eventos. Isso ajuda a gerar planos de implementação que você ou o time de engenharia podem seguir.[[github](https://github.com/coreyhaines31/marketingskills)]​
    
- **Planejar um lançamento de funcionalidade ou produto**  
    Peça “monte um plano de lançamento para esta nova feature” e a skill `launch-strategy` organiza canais, mensagens, fases e ativos necessários. Você pode conectar isso com `social-content` e `email-sequence` para produzir os materiais.[[github](https://github.com/coreyhaines31/marketingskills)]​
    
- **Rodar uma auditoria de SEO e plano de programmatic SEO**  
    Pergunte “faça uma auditoria de SEO deste site” para acionar `seo-audit`, que guia o agente em diagnósticos técnicos e on-page. Em seguida, use `programmatic-seo` para desenhar templates e campos para gerar páginas em escala.[[github](https://github.com/coreyhaines31/marketingskills)]​
    
- **Definir pricing, planos e estratégia de monetização**  
    Conte o contexto do seu produto e peça “me ajude a repensar pricing e planos”; o agente usará `pricing-strategy` com frameworks de monetização, ancoragem e diferenciação. Dá para complementar com `marketing-psychology` para testar mensagens com gatilhos mais fortes.[[github](https://github.com/coreyhaines31/marketingskills)]​
    
- **Criar um programa de indicação/referral para SaaS**  
    Use “desenhe um programa de referral para este SaaS B2B” para acionar `referral-program`, que estrutura incentivos, regras, fluxos de comunicação e métricas-chave. Você pode depois usar `email-sequence` e `social-content` para construir os ativos de divulgação.[[github](https://github.com/coreyhaines31/marketingskills)]​
    

---

## Requisitos e Compatibilidade

Como o repositório é composto por Markdown e configs, não há “runtime” obrigatório de linguagem, mas há ferramentas de instalação com requisitos mínimos:[[github](https://github.com/coreyhaines31/marketingskills)]​

- **Git**: Necessário para clonar o repositório ou adicionar como submódulo.[[github](https://github.com/coreyhaines31/marketingskills)]​
    
- **Node + npx**: Recomendado ter Node.js instalado em versão compatível com `npx` (qualquer versão moderna LTS) para usar `npx skills` e `npx skillkit`.[[github](https://github.com/coreyhaines31/marketingskills)]​
    
- **Ambiente do Editor / IDE**: Claude Code (VS Code ou editor compatível) ou outras IDEs que suportem SkillKit/skills.[[github](https://github.com/coreyhaines31/marketingskills)]​
    

Não há dependências de banco de dados, Redis, Docker ou serviços externos para o funcionamento das skills em si; qualquer dependência técnica (ex.: GA4, plataformas de ads) é operacional, não de infraestrutura do repo.[[github](https://github.com/coreyhaines31/marketingskills)]​

---

## Links Úteis

|Tipo|Link|
|---|---|
|Repositório|[https://github.com/coreyhaines31/marketingskills](https://github.com/coreyhaines31/marketingskills) [[github](https://github.com/coreyhaines31/marketingskills)]​|
|Documentação / README|[README.md na raiz do repo](https://github.com/coreyhaines31/marketingskills/blob/main/README.md) [[github](https://github.com/coreyhaines31/marketingskills)]​|
|Issues|[https://github.com/coreyhaines31/marketingskills/issues](https://github.com/coreyhaines31/marketingskills/issues) [[github](https://github.com/coreyhaines31/marketingskills)]​|
|Comunidade / Autor|[Corey Haines](https://corey.co/?ref=marketingskills), [Conversion Factory](https://conversionfactory.co/?ref=marketingskills), [Swipe Files](https://swipefiles.com/?ref=marketingskills) [[github](https://github.com/coreyhaines31/marketingskills)]​|
|Site do Projeto|[https://marketing-skills.com/](https://marketing-skills.com/) [[github](https://github.com/coreyhaines31/marketingskills)]​|', 'https://github.com/coreyhaines31/marketingskills', NULL);
INSERT INTO resources_bflabs_ide_powerup (id, category_id, name, slug, short_description, long_description, repo_url, website_url) VALUES ('1ae9068f-6e60-4873-ab2c-d6b0757d4178', '0057a728-fe56-4a9b-ad82-b28872b5e0f3', 'Ralph for Claude Code ]​', 'ralph-for-claude-code', '**Loop autônomo de desenvolvimento com Claude Code, focado em ciclos contínuos de refino de código com detecção inteligente de término, limite de uso ...', '**Loop autônomo de desenvolvimento com Claude Code, focado em ciclos contínuos de refino de código com detecção inteligente de término, limite de uso de API e monitoramento em tempo real para projetos reais.**[[github](https://github.com/frankbria/ralph-claude-code)]​

---

## The Guides

Este repositório é principalmente um conjunto de scripts Bash, templates e documentação complementar que habilitam um loop de desenvolvimento autônomo em cima do Claude Code CLI, com instalação global e comandos de projeto. Abaixo você encontra uma visão rápida dos conceitos chave, estrutura de pastas e fluxos típicos para colocar o Ralph para trabalhar em projetos de produção em poucas horas. A documentação profunda vive em vários arquivos Markdown dentro do próprio repo (README, IMPLEMENTATION_PLAN, TESTING, etc.).[[github](https://github.com/frankbria/ralph-claude-code)]​

|Tipo|Link|
|---|---|
|Visão Geral Rápida|[README.md – Ralph for Claude Code](https://github.com/frankbria/ralph-claude-code) [[github](https://github.com/frankbria/ralph-claude-code)]​|
|Guia Detalhado|[IMPLEMENTATION_PLAN.md – Roadmap e fases](https://github.com/frankbria/ralph-claude-code/blob/main/IMPLEMENTATION_PLAN.md) [[github](https://github.com/frankbria/ralph-claude-code)]​|

---

## Topics / What You’ll Learn

|Tópico|O que você aprende / consegue fazer|
|---|---|
|Loop autônomo de desenvolvimento|Configurar um ciclo contínuo onde Claude Code lê requisitos, gera mudanças, avalia progresso e decide quando parar. [[github](https://github.com/frankbria/ralph-claude-code)]​|
|Detecção inteligente de saída|Usar o gate dual (indicadores de conclusão + `EXIT_SIGNAL`) para evitar loops infinitos ou saída prematura. [[github](https://github.com/frankbria/ralph-claude-code)]​|
|Rate limiting e circuit breaker|Limitar chamadas por hora, lidar com limites de 5h da API e abrir/fechar circuit breaker em loops problemáticos. [[github](https://github.com/frankbria/ralph-claude-code)]​|
|Estrutura `.ralph/` por projeto|Organizar PROMPT, plano de correções, specs, logs e docs geradas em uma pasta dedicada, mantida pelo Ralph. [[github](https://github.com/frankbria/ralph-claude-code)]​|
|Importação de PRD (`ralph-import`)|Converter PRDs/requirements (md, txt, json, docx, pdf) em um projeto estruturado pronto para desenvolvimento autônomo. [[github](https://github.com/frankbria/ralph-claude-code)]​|
|Setup de projetos (`ralph-setup`)|Criar rapidamente novos projetos com templates de estrutura, tarefas e especificações já pensadas para AI. [[github](https://github.com/frankbria/ralph-claude-code)]​|
|Monitoramento com tmux|Acompanhar em tempo real loops, uso de API, logs e status via `ralph --monitor` e `ralph-monitor`. [[github](https://github.com/frankbria/ralph-claude-code)]​|
|Sessões e continuidade|Gerenciar contexto de sessão (continuar, resetar, expirar) para iterações mais coerentes e controladas. [[github](https://github.com/frankbria/ralph-claude-code)]​|
|Configuração de timeouts e prompts|Ajustar timeouts, usar prompts customizados e flags de CLI modernas (`--output-format`, `--allowed-tools`). [[github](https://github.com/frankbria/ralph-claude-code)]​|
|Testes e qualidade|Rodar a suíte de testes BATS e entender como o projeto garante confiabilidade via 300+ testes automatizados. [[github](https://github.com/frankbria/ralph-claude-code)]​|

---

## Cross-Platform Support

Ralph é orientado a ambiente Unix-like com Bash 4+, GNU coreutils, `jq`, `tmux` e ferramentas padrão de linha de comando, rodando bem em distribuições Linux e macOS com essas dependências instaladas. Em macOS é necessário instalar `coreutils` via Homebrew para fornecer `gtimeout`, que o Ralph detecta automaticamente.[[github](https://github.com/frankbria/ralph-claude-code)]​

A instalação é script-driven via Bash: você clona o repo e executa `./install.sh`, que registra comandos globais (`ralph`, `ralph-monitor`, `ralph-setup`, `ralph-import`, `ralph-migrate`) no seu PATH. Depois, por projeto, você usa `ralph-setup` ou `ralph-import` para inicializar a estrutura `.ralph/` no diretório daquele código.[[github](https://github.com/frankbria/ralph-claude-code)]​

---

## What’s Inside

bash

``ralph-claude-code/ ├── docs/                 # Documentação complementar, exemplos de uso e notas de design. [page:1] ├── examples/             # Estrutura para exemplos de projetos Ralph. [page:1] ├── lib/                  # Funções Bash reutilizáveis (analisador, sessão, rate limiting, etc.). [page:1] ├── specs/ │   └── stdlib/          # Especificações de biblioteca padrão usadas na geração de projetos. [page:1] ├── src/                  # Código-fonte adicional de suporte (scripts/auxiliares). [page:1] ├── templates/            # Templates para PROMPT, fix_plan, specs e estrutura `.ralph/` por projeto. [page:1] ├── tests/                # Suíte BATS com testes unitários e de integração (loop, instalação, import, etc.). [page:1] ├── logs/                 # Pasta de logs do próprio Ralph (estrutura utilizada em runtime). [page:1] ├── CLAUDE.md             # Instruções específicas para integração com Claude Code. [page:1] ├── TESTING.md            # Guia detalhado para rodar e entender os testes. [page:1] ├── IMPLEMENTATION_PLAN.md # Roadmap e fases até v1.0. [page:1] ├── IMPLEMENTATION_STATUS.md # Status atual de implementação. [page:1] ├── SPECIFICATION_WORKSHOP.md # Workshop de especificação e requisitos. [page:1] ├── README.md             # Documentação principal de uso e conceitos. [page:1] ├── install.sh            # Instalação global do Ralph e comandos auxiliares. [page:1] ├── uninstall.sh          # Remoção limpa de todos os comandos e arquivos globais. [page:1] ├── setup.sh              # Inicialização/bootstrapping de novos projetos (usado por ralph-setup). [page:1] ├── ralph_loop.sh         # Loop principal de execução, exit detection, sessão e circuit breaker. [page:1] ├── ralph_monitor.sh      # Monitor em tempo real (dashboard em tmux). [page:1] ├── ralph_import.sh       # Importador de PRD/requirements, gera estrutura `.ralph/`. [page:1] ├── ralph_enable.sh       # Script de enable/config em projetos existentes ou no ambiente. [page:1] ├── ralph_enable_ci.sh    # Integração com CI, especialmente GitHub Actions. [page:1] ├── migrate_to_ralph_folder.sh # Migração de projetos antigos para a estrutura `.ralph/`. [page:1] └── package.json          # Config de projeto Node para dependências e scripts de teste (BATS). [page:1]``

---

## Ecosystem Tools

- **Claude Code CLI (@anthropic-ai/claude-code)** – Ferramenta oficial da Anthropic para interação via linha de comando, usada como engine principal por trás de todos os loops e conversões do Ralph.[[github](https://github.com/frankbria/ralph-claude-code)]​
    
- **tmux** – Multiplexador de terminal usado para fornecer o dashboard ao vivo (`ralph --monitor` / `ralph-monitor`) sem bloquear o shell principal.[[github](https://github.com/frankbria/ralph-claude-code)]​
    
- **BATS + bats-support/bats-assert** – Framework de testes em Bash que valida instalação, loop, import, CLI moderna e comportamento do circuit breaker.[[github](https://github.com/frankbria/ralph-claude-code)]​
    
- **GitHub Actions** – Pipeline CI que executa a suíte de testes e reporta status, garantindo que mudanças não quebrem a automação.[[github](https://github.com/frankbria/ralph-claude-code)]​
    
- **Aider / técnica Ralph original** – Referência conceitual da técnica de desenvolvimento contínuo de Geoffrey Huntley, adaptada aqui para o ecossistema Claude Code.[[github](https://github.com/frankbria/ralph-claude-code)]​
    

---

## Instalação

## Opção 1: Instalar como Ferramenta Global

Clone o repositório e rode o instalador para registrar os comandos globais:

bash

`git clone https://github.com/frankbria/ralph-claude-code.git cd ralph-claude-code ./install.sh`

Após isso, você passa a ter disponíveis: `ralph`, `ralph-monitor`, `ralph-setup`, `ralph-import` e `ralph-migrate` no PATH.[[github](https://github.com/frankbria/ralph-claude-code)]​

Para remover completamente do sistema:

bash

`./uninstall.sh # ou, se já removeu o repo: curl -sL https://raw.githubusercontent.com/frankbria/ralph-claude-code/main/uninstall.sh | bash`

## Opção 2: Instalação Manual / Ambiente de Dev

Para desenvolvimento no próprio repo (rodar testes, contribuir, etc.):

bash

`git clone https://github.com/YOUR_USERNAME/ralph-claude-code.git cd ralph-claude-code npm install npm test`

Você também pode usar diretamente scripts como `./setup.sh`, `./ralph_import.sh` ou `./ralph_loop.sh` apontando seus projetos locais, mas o fluxo recomendado é sempre via `./install.sh` para uso global.[[github](https://github.com/frankbria/ralph-claude-code)]​

---

## Configuração

A configuração principal é feita por projeto dentro da pasta `.ralph/`, criada via `ralph-setup` ou `ralph-import`. Nela você edita:[[github](https://github.com/frankbria/ralph-claude-code)]​

- `.ralph/PROMPT.md` – instruções de alto nível do projeto, escopo, objetivos e estilo de implementação.[[github](https://github.com/frankbria/ralph-claude-code)]​
    
- `.ralph/fix_plan.md` – backlog/priorização de tarefas que o loop usa para guiar a evolução.[[github](https://github.com/frankbria/ralph-claude-code)]​
    
- `.ralph/specs/` – requisitos técnicos detalhados, specs de APIs, modelos de dados e fluxos de negócio.[[github](https://github.com/frankbria/ralph-claude-code)]​
    
- `.ralph/AGENT.md` – instruções de build/run, dependências e comandos para o agente e para humanos.[[github](https://github.com/frankbria/ralph-claude-code)]​
    

Configurações operacionais são passadas via flags de CLI:

bash

`# Limite de chamadas por hora (default 100) ralph --calls 50 # Timeout de execução do Claude Code ralph --timeout 30 # Formato de saída (json ou text) ralph --output-format json # Ferramentas permitidas no Claude Code ralph --allowed-tools "Write,Bash(git *),Read" # Continuar ou não a sessão ralph --no-continue ralph --reset-session`

No host, alguns thresholds podem ser ajustados editando `~/.ralph/ralph_loop.sh`, como limites de loops de teste, sinais de “done” e parâmetros do circuit breaker. Não há `.env` dedicado, mas o Claude Code CLI precisa estar corretamente configurado com credenciais da API conforme a própria ferramenta.[[github](https://github.com/frankbria/ralph-claude-code)]​

---

## Fluxos e Casos de Uso

- **Rodar um loop autônomo de desenvolvimento num projeto existente.**  
    Você inicializa a estrutura `.ralph/` via `ralph-setup my-project` ou `ralph-import`, ajusta PROMPT, fix_plan e specs e depois roda `ralph --monitor` dentro do diretório do projeto para deixar o Claude iterar até completar o escopo.[[github](https://github.com/frankbria/ralph-claude-code)]​
    
- **Converter um PRD em um projeto pronto para AI.**  
    Usando `ralph-import my-requirements.md my-project`, o script gera `.ralph/PROMPT.md`, `.ralph/fix_plan.md` e `.ralph/specs/requirements.md`, permitindo que você revise rapidamente e inicie o loop com `ralph --monitor`.[[github](https://github.com/frankbria/ralph-claude-code)]​
    
- **Operar com monitoramento ao vivo em produção.**  
    Em qualquer projeto Ralph você executa `ralph --monitor` para abrir uma sessão tmux com monitor, ou roda `ralph` em um terminal e `ralph-monitor` em outro para acompanhar logs, uso de API e status em tempo real.[[github](https://github.com/frankbria/ralph-claude-code)]​
    
- **Gerenciar limites de API e evitar desperdício de chamadas.**  
    Para ambientes com budget apertado, você ajusta `--calls`, timeouts e deixa o circuit breaker atuar automaticamente; Ralph lida com o limite de 5h do Claude pedindo para esperar ou sair, evitando loops inúteis.[[github](https://github.com/frankbria/ralph-claude-code)]​
    
- **Rodar revisões incrementais com controle de sessão.**  
    Você pode usar `ralph --no-continue` para rodadas isoladas ou `ralph --reset-session` quando quiser “zerar” o contexto de sessão, por exemplo após um grande refactor manual.[[github](https://github.com/frankbria/ralph-claude-code)]​
    
- **Migrar projetos antigos para a nova estrutura `.ralph/`.**  
    Em projetos pré-0.10, basta rodar `ralph-migrate` para mover arquivos para o subfolder `.ralph/` de forma segura, mantendo backups e ajustando caminhos usados pelos scripts.[[github](https://github.com/frankbria/ralph-claude-code)]​
    

---

## Requisitos e Compatibilidade

- **Shell / SO**
    
    - Bash 4.0+.[[github](https://github.com/frankbria/ralph-claude-code)]​
        
    - Ambiente Unix-like (Linux, macOS) com GNU coreutils (especialmente `timeout`/`gtimeout`).[[github](https://github.com/frankbria/ralph-claude-code)]​
        
- **Ferramentas obrigatórias**
    
    - Claude Code CLI: `npm install -g @anthropic-ai/claude-code`.[[github](https://github.com/frankbria/ralph-claude-code)]​
        
    - `tmux` para monitoramento integrado (recomendado).[[github](https://github.com/frankbria/ralph-claude-code)]​
        
    - `jq` para parsing JSON.[[github](https://github.com/frankbria/ralph-claude-code)]​
        
    - Git para inicialização de repositórios de projeto.[[github](https://github.com/frankbria/ralph-claude-code)]​
        
- **Ferramentas de teste (dev)**
    
    - Node + npm para instalar BATS e rodar `npm test`.[[github](https://github.com/frankbria/ralph-claude-code)]​
        
    - BATS, bats-support, bats-assert instalados globalmente.[[github](https://github.com/frankbria/ralph-claude-code)]​
        

Não há dependência de banco de dados, Redis ou Docker por padrão; o foco é automação baseada em arquivos e CLI.[[github](https://github.com/frankbria/ralph-claude-code)]​

---

## Links Úteis

| Tipo               | Link                                                                                                                                                                  |
| ------------------ | --------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Repositório        | [GitHub – frankbria/ralph-claude-code](https://github.com/frankbria/ralph-claude-code) [[github](https://github.com/frankbria/ralph-claude-code)]​                    |
| Documentação       | [README.md](https://github.com/frankbria/ralph-claude-code/blob/main/README.md) [[github](https://github.com/frankbria/ralph-claude-code)]​                           |
| Roadmap            | [IMPLEMENTATION_PLAN.md](https://github.com/frankbria/ralph-claude-code/blob/main/IMPLEMENTATION_PLAN.md) [[github](https://github.com/frankbria/ralph-claude-code)]​ |
| Issues             | [GitHub Issues](https://github.com/frankbria/ralph-claude-code/issues) [[github](https://github.com/frankbria/ralph-claude-code)]​                                    |
| Contribuição       | [CONTRIBUTING.md](https://github.com/frankbria/ralph-claude-code/blob/main/CONTRIBUTING.md) [[github](https://github.com/frankbria/ralph-claude-code)]​               |
| Testes             | [TESTING.md](https://github.com/frankbria/ralph-claude-code/blob/main/TESTING.md) [[github](https://github.com/frankbria/ralph-claude-code)]​                         |
| Comunidade/X       | [Frank Bria no X](https://x.com/FrankBria18044) [[github](https://github.com/frankbria/ralph-claude-code)]​                                                           |
| Referência técnica | [Ralph technique – ghuntley.com](https://ghuntley.com/ralph/) [[github](https://github.com/frankbria/ralph-claude-code)]​                                             |', 'https://github.com/frankbria/ralph-claude-code', NULL);
INSERT INTO resources_bflabs_ide_powerup (id, category_id, name, slug, short_description, long_description, repo_url, website_url) VALUES ('01ce5e3c-b101-45d2-82b6-2128d7688b0c', 'b9f99d29-ef1f-4416-9f0e-fae44f8f4b48', 'Antigravity Skills', 'antigravity-skills', '...', '', NULL, NULL);
INSERT INTO resources_bflabs_ide_powerup (id, category_id, name, slug, short_description, long_description, repo_url, website_url) VALUES ('a919d5c0-bc48-4ef7-b840-a4a59c490b0b', 'cc50662d-853b-4bac-b2d6-712b7b93d3d7', 'Antigravity Awesome Skills ]​', 'antigravity-awesome-skills', '**Coleção curada de mais de 250 skills agenticas prontas para transformar Claude Code, Gemini CLI, Cursor, Copilot, Antigravity e outros em uma “agênc...', '**Coleção curada de mais de 250 skills agenticas prontas para transformar Claude Code, Gemini CLI, Cursor, Copilot, Antigravity e outros em uma “agência digital full-stack” focada em produção real, não só playground.**[[github](https://github.com/sickn33/antigravity-awesome-skills)]​

---

## The Guides

Este repositório é principalmente um catálogo estruturado de skills em arquivos Markdown, mais documentação de suporte e scripts de manutenção/automação para manter tudo organizado, versionado e fácil de instalar. A lógica de “como usar na prática” está distribuída entre o README principal, o GETTING_STARTED, os bundles em docs e a própria árvore de skills. Abaixo está um guia condensado em português para alguém chegar da instalação ao uso produtivo em um dia.[[github](https://github.com/sickn33/antigravity-awesome-skills)]​

|Tipo|Link|
|---|---|
|Visão Geral Rápida|[GETTING_STARTED.md](https://github.com/sickn33/antigravity-awesome-skills/blob/main/GETTING_STARTED.md) [[github](https://github.com/sickn33/antigravity-awesome-skills)]​|
|Guia Detalhado|Seções deste doc: [Instalação](https://www.perplexity.ai/sidecar/search/voce-esta-com-acesso-ao-reposi-BcId1CreQymClO5Uj6Zu7g#instala%C3%A7%C3%A3o), [Configuração](https://www.perplexity.ai/sidecar/search/voce-esta-com-acesso-ao-reposi-BcId1CreQymClO5Uj6Zu7g#configura%C3%A7%C3%A3o) e [Fluxos-e-Casos-de-Uso](https://www.perplexity.ai/sidecar/search/voce-esta-com-acesso-ao-reposi-BcId1CreQymClO5Uj6Zu7g#fluxos-e-casos-de-uso)|

---

## Topics / What You’ll Learn

|Tópico|O que você aprende / consegue fazer|
|---|---|
|Arquitetura de Skills Agenticas|Entender o formato universal de SKILL.md, organização por categorias e como plugar isso em diferentes CLIs/IDEs. [[github](https://github.com/sickn33/antigravity-awesome-skills)]​|
|Compatibilidade Multiplataforma|Usar o mesmo conjunto de skills em Claude Code, Gemini CLI, Antigravity, Cursor, Copilot e OpenCode, aproveitando paths específicos. [[github](https://github.com/sickn33/antigravity-awesome-skills)]​|
|Bundles e Personas|Carregar pacotes de skills por perfil (web dev, security, essentials, etc.) a partir de `docs/BUNDLES.md`. [[github](https://github.com/sickn33/antigravity-awesome-skills)]​|
|Desenvolvimento & Dev Patterns|Reforçar padrões de backend, frontend, arquitetura e TDD com skills de guidelines e boas práticas. [[github](https://github.com/sickn33/antigravity-awesome-skills)]​|
|Infra, Git & DevOps|Aplicar skills de Docker, Git workflow, deployment e Cloud (AWS, GCP, serverless) direto via seu agente. [[github](https://github.com/sickn33/antigravity-awesome-skills)]​|
|Segurança & Pentest|Usar um conjunto grande de skills de segurança ofensiva/defensiva (XSS, IDOR, cloud pentest, Burp, etc.). [[github](https://github.com/sickn33/antigravity-awesome-skills)]​|
|Marketing, Growth & Produto|Ativar skills de CRO, copywriting, email, SEO, ASO e estratégia de produto dentro do próprio assistente. [[github](https://github.com/sickn33/antigravity-awesome-skills)]​|
|Agentes, Memória e Orquestração|Projetar agentes autônomos, memória, workflows multi-agente, browser automation e computer-use. [[github](https://github.com/sickn33/antigravity-awesome-skills)]​|
|Documentos e Processamento|Trabalhar com DOCX, PDF, PPTX, XLSX usando skills oficiais/alternativas para manipular docs profissionais. [[github](https://github.com/sickn33/antigravity-awesome-skills)]​|
|Automação de Fluxos de Trabalho|Usar skills de planejamento, execução de planos, revisão de código, testes e finalização de branches. [[github](https://github.com/sickn33/antigravity-awesome-skills)]​|

---

## Cross-Platform Support

O projeto é agnóstico de sistema operacional: funciona onde você conseguir clonar o repositório (Windows, macOS, Linux, servidores) e apontar sua ferramenta para as pastas de skills. Em Windows há um ponto de atenção com symlinks: é necessário habilitar o Modo Desenvolvedor ou rodar o Git como Administrador, usando algo como `git clone -c core.symlinks=true ...`.[[github](https://github.com/sickn33/antigravity-awesome-skills)]​

O consumo é “runtime-agnostic”: as skills são Markdown e são usadas por ferramentas como Claude Code (CLI), Gemini CLI, Antigravity IDE, Cursor, GitHub Copilot e outras, apenas mudando o path onde os arquivos são copiados (ex.: `.claude/skills/`, `.agent/skills/`, `.cursor/skills/`). O README sugere um **caminho universal recomendado** clonando o repo em `.agent/skills/` para que várias ferramentas modernas encontrem as skills automaticamente.[[github](https://github.com/sickn33/antigravity-awesome-skills)]​

---

## What’s Inside

bash

``antigravity-awesome-skills/ ├─ skills/                     # Núcleo: mais de 250 skills organizadas por tema (dev, infra, security, marketing, agents, etc.). [page:1] │  ├─ game-development/        # Subgrupo de skills de game dev (2D/3D, art, audio, design, orquestração). [page:1] │  ├─ ...                      # Diversas pastas temáticas como ai-agents, security, marketing, infra, etc. [page:1] │  └─ <skill-name>/SKILL.md    # Cada skill com descrição, quando usar, padrões e exemplos. [page:1] ├─ docs/ │  ├─ BUNDLES.md               # Coleções/bundles de skills por persona (Web Wizard, Security Engineer, Essentials, etc.). [page:1] │  └─ ...                      # Documentos auxiliares e guias complementares. [page:1] ├─ scripts/ │  └─ ...                      # Scripts internos para manutenção, atualização automática do README e sincronização de índices. [page:1] ├─ assets/ │  └─ ...                      # Imagens como gráfico de histórico de estrelas do GitHub e outros assets visuais. [page:1] ├─ .github/ │  └─ ...                      # Workflows de CI para validar, atualizar README, sincronizar `skills_index.json`, etc. [page:1] ├─ skills_index.json           # Índice gerado com metadados de todas as skills (nome, risco, path). [page:1] ├─ README.md                   # Visão geral, compatibilidade, features, tabela de categorias, instalação e seções de comunidade. [page:1] ├─ GETTING_STARTED.md          # Guia passo a passo para novos usuários, explicando contexto, bundles e uso prático. [page:1] ├─ FAQ.md                      # Perguntas frequentes: manutenção, contagem de skills, padrões, dúvidas comuns. [page:1] ├─ CONTRIBUTING.md             # Regras detalhadas para contribuir, padronização e fluxo de PR. [page:1] ├─ CHANGELOG.md                # Histórico de versões, ex.: v3.4.0 com foco em Voice AI & Categorization. [page:1] ├─ SECURITY.md                 # Políticas de segurança e compliance para uso/contribuição. [page:1] └─ LICENSE                     # Licença MIT. [page:1]``

---

## Ecosystem Tools

- **Claude Code / Anthropic CLI** – Usa as skills via CLI, geralmente mapeadas em `.claude/skills/`, permitindo invocação com `>> /skill-name ...`.[[github](https://github.com/sickn33/antigravity-awesome-skills)]​
    
- **Gemini CLI** – Integra skills em `.gemini/skills/` para enriquecer o fluxo de trabalho de desenvolvimento com o modelo da Google DeepMind.[[github](https://github.com/sickn33/antigravity-awesome-skills)]​
    
- **Antigravity IDE** – IDE focada em agentes onde `.agent/skills/` é o path padrão, tornando este repo praticamente o “core skill pack” da ferramenta.[[github](https://github.com/sickn33/antigravity-awesome-skills)]​
    
- **Cursor** – IDE AI-native que pode usar skills via `.cursor/skills/` e menções como `@skill-name` no chat.[[github](https://github.com/sickn33/antigravity-awesome-skills)]​
    
- **GitHub Copilot & OpenCode** – Usam conteúdo das skills como referência operacional e padrões, ainda que com integração mais manual (copiar/colar ou caminhos específicos).[[github](https://github.com/sickn33/antigravity-awesome-skills)]​
    
- **Ferramentas oficiais de terceiros** – Algumas skills encapsulam funcionalidades de Anthropic, Google, Supabase, Vercel Labs, etc., atuando como “manual operacional” para usar essas plataformas com menos atrito.[[github](https://github.com/sickn33/antigravity-awesome-skills)]​
    

---

## Instalação

## Opção 1: Clonar direto na pasta universal `.agent/skills/`

Recomendada para ambientes com Antigravity, CLIs mais novos ou setups onde você quer um local único de skills para múltiplas ferramentas.[[github](https://github.com/sickn33/antigravity-awesome-skills)]​

bash

`# Dentro do diretório do seu projeto git clone https://github.com/sickn33/antigravity-awesome-skills.git .agent/skills`

Depois disso, configure seu agente (Claude Code, Gemini CLI, Antigravity, etc.) para olhar para `.agent/skills/` como fonte de skills, se ainda não o fizer por padrão.[[github](https://github.com/sickn33/antigravity-awesome-skills)]​

## Opção 2: Instalação “por ferramenta” (paths específicos)

Você pode clonar o repositório uma vez e então copiar/mover os diretórios de skills relevantes para o path que cada ferramenta espera.[[github](https://github.com/sickn33/antigravity-awesome-skills)]​

bash

`# Clone principal em qualquer pasta de trabalho git clone https://github.com/sickn33/antigravity-awesome-skills.git cd antigravity-awesome-skills`

Exemplos de paths (ajuste conforme seu setup):[[github](https://github.com/sickn33/antigravity-awesome-skills)]​

- Claude Code (CLI): copiar skills para `.claude/skills/` no seu projeto.[[github](https://github.com/sickn33/antigravity-awesome-skills)]​
    
- Gemini CLI: copiar skills para `.gemini/skills/`.[[github](https://github.com/sickn33/antigravity-awesome-skills)]​
    
- Cursor: copiar skills para `.cursor/skills/` na raiz do projeto.[[github](https://github.com/sickn33/antigravity-awesome-skills)]​
    
- Antigravity IDE: apontar a IDE para a pasta clonada ou usar `.agent/skills/`.[[github](https://github.com/sickn33/antigravity-awesome-skills)]​
    

Em Windows, se quiser preservar symlinks de skills oficiais, use:[[github](https://github.com/sickn33/antigravity-awesome-skills)]​

bash

`git clone -c core.symlinks=true https://github.com/sickn33/antigravity-awesome-skills.git`

---

## Configuração

A principal “configuração” é apontar cada ferramenta para o diretório correto de skills, seguindo a tabela de compatibilidade: `.claude/skills/`, `.gemini/skills/`, `.agent/skills/`, `.cursor/skills/`, etc. Recomenda-se usar `.agent/skills/` como caminho universal para maximizar reaproveitamento entre IDEs/CLIs.[[github](https://github.com/sickn33/antigravity-awesome-skills)]​

Algumas skills assumem que você tem variáveis de ambiente e credenciais configuradas para serviços externos (Stripe, Firebase, Supabase, Vercel, Twilio, HubSpot, etc.), mas essa configuração é feita no seu projeto/app, não neste repo. O GETTING_STARTED.md detalha a experiência de uso, incluindo como chamar skills e como combinar com o contexto do seu código.[[github](https://github.com/sickn33/antigravity-awesome-skills)]​

Para manutenção e consistência interna do repo (se você pretende contribuir), existem scripts e workflows que geram/atualizam `skills_index.json` e o README, mas isso é irrelevante para quem só quer consumir as skills.[[github](https://github.com/sickn33/antigravity-awesome-skills)]​

---

## Fluxos e Casos de Uso

- **Montar um setup padrão de desenvolvimento com bundles pré-definidos.**  
    Clone o repo, escolha um bundle em `docs/BUNDLES.md` (por exemplo, Web Wizard, Security Engineer ou Essentials) e ative essas skills no seu agente para acelerar desenvolvimento de features, refatorações e debugging.[[github](https://github.com/sickn33/antigravity-awesome-skills)]​
    
- **Rodar um “agente full-stack” cobrindo backend, frontend, infra e análise.**  
    Ao usar skills de development, backend/front patterns, infra e deployment juntas, você consegue guiar o agente a escrever código, revisar, propor arquitetura e sugerir estratégias de deploy num fluxo único.[[github](https://github.com/sickn33/antigravity-awesome-skills)]​
    
- **Aplicar um “modo security” para pentest e hardening.**  
    Ative skills de segurança (XSS, IDOR, API fuzzing, cloud pentest, Burp, etc.) para orientar o agente em testes, checklist de segurança e recomendações de mitigação em endpoints e infra.[[github](https://github.com/sickn33/antigravity-awesome-skills)]​
    
- **Orquestrar agentes e fluxos complexos de trabalho.**  
    Use skills como autonomous-agent-patterns, dispatching-parallel-agents, agent-memory-systems e computer-use-agents para desenhar agentes autônomos, multi-agente e com memória, inclusive com automação de browser/computador.[[github](https://github.com/sickn33/antigravity-awesome-skills)]​
    
- **Acelerar marketing e growth com o mesmo agente técnico.**  
    Combine skills de copywriting, content-creator, email-sequence, marketing & growth, CRO e free-tool-strategy para sair de “ideia de campanha” até landing pages, emails e estratégias de aquisição num só ambiente.[[github](https://github.com/sickn33/antigravity-awesome-skills)]​
    
- **Trabalhar com documentos de negócio (propostas, relatórios, apresentações).**  
    Use skills DOCX, PDF, PPTX, XLSX (incluindo versões oficiais) para gerar, revisar e ajustar documentos com qualidade de produção dentro do fluxo do seu assistente de código.[[github](https://github.com/sickn33/antigravity-awesome-skills)]​
    

---

## Requisitos e Compatibilidade

- **SO:** Windows, macOS, Linux (qualquer ambiente com Git e acesso ao sistema de arquivos do seu projeto).[[github](https://github.com/sickn33/antigravity-awesome-skills)]​
    
- **Ferramentas suportadas:** Claude Code, Gemini CLI, Codex CLI, Antigravity IDE, GitHub Copilot, Cursor, OpenCode e outros que adotem o formato SKILL.md.[[github](https://github.com/sickn33/antigravity-awesome-skills)]​
    
- **Dependências externas:** nenhuma obrigatória para usar o repo em si; cada skill pode depender de serviços externos (APIs, bancos, clouds) que você já usa no seu projeto.[[github](https://github.com/sickn33/antigravity-awesome-skills)]​
    
- **Windows:** requer atenção a symlinks (Developer Mode ou `core.symlinks=true` no clone) para preservar links de skills oficiais.[[github](https://github.com/sickn33/antigravity-awesome-skills)]​
    

---

## Links Úteis

|Tipo|Link|
|---|---|
|Repositório|[https://github.com/sickn33/antigravity-awesome-skills](https://github.com/sickn33/antigravity-awesome-skills) [[github](https://github.com/sickn33/antigravity-awesome-skills)]​|
|Documentação|README + [GETTING_STARTED.md](https://github.com/sickn33/antigravity-awesome-skills/blob/main/GETTING_STARTED.md) + `docs/` [[github](https://github.com/sickn33/antigravity-awesome-skills)]​|
|Issues|[https://github.com/sickn33/antigravity-awesome-skills/issues](https://github.com/sickn33/antigravity-awesome-skills/issues) [[github](https://github.com/sickn33/antigravity-awesome-skills)]​|
|Comunidade|Issues/PRs do GitHub (não há link explícito para Discord/Slack neste repo). [[github](https://github.com/sickn33/antigravity-awesome-skills)]​|', 'https://github.com/sickn33/antigravity-awesome-skills', NULL);
