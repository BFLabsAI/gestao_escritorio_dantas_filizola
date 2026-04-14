import "@supabase/functions-js/edge-runtime.d.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.57.4"

type FaseCritica = "DOC_PENDENTE" | "APROVACAO_GESTOR" | "PENDENCIA"

type ProcessoCritico = {
  id: string
  fase_kanban: FaseCritica
  numero_processo: string | null
  tipo_beneficio: string
  dias_na_fase: number
  cliente: {
    nome_completo: string
    telefone: string | null
  } | null
}

const CRITICAL_PHASES: FaseCritica[] = ["DOC_PENDENTE", "APROVACAO_GESTOR", "PENDENCIA"]

function json(data: unknown, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { "Content-Type": "application/json" },
  })
}

function getEnv(name: string) {
  const value = Deno.env.get(name)
  if (!value) {
    throw new Error(`Variavel de ambiente ausente: ${name}`)
  }
  return value
}

function sanitizePhone(phone: string) {
  return phone.replace(/\D/g, "")
}

function buildMessage(processo: ProcessoCritico) {
  const nome = processo.cliente?.nome_completo ?? "cliente"
  const identificador = processo.numero_processo
    ? `Processo ${processo.numero_processo}`
    : `Processo ${processo.id}`

  const phaseMessage: Record<FaseCritica, string> = {
    DOC_PENDENTE:
      "identificamos documentacao pendente no seu atendimento. Assim que os documentos restantes forem enviados, daremos continuidade ao protocolo.",
    APROVACAO_GESTOR:
      "seu processo esta em aprovacao interna da gestao. Estamos validando os ultimos detalhes antes do protocolo.",
    PENDENCIA:
      "seu processo entrou em pendencia e precisa de acompanhamento prioritario. Nossa equipe ja esta atuando para resolver o ponto pendente.",
  }

  return [
    `Olá, ${nome}.`,
    `${identificador}: ${phaseMessage[processo.fase_kanban]}`,
    `Fase atual: ${processo.fase_kanban}.`,
    `Tempo na fase: ${processo.dias_na_fase} dia(s).`,
    "Equipe Dantas & Filizola.",
  ].join("\n")
}

async function sendWhatsappMessage(phone: string, text: string) {
  const apiUrl = getEnv("UAZAPI_API_URL").replace(/\/$/, "")
  const token = getEnv("UAZAPI_TOKEN")
  const sendPath = Deno.env.get("UAZAPI_SEND_PATH") ?? "/send/text"
  const instance = Deno.env.get("UAZAPI_INSTANCE")
  const authHeader = Deno.env.get("UAZAPI_AUTH_HEADER") ?? "Authorization"
  const authScheme = Deno.env.get("UAZAPI_AUTH_SCHEME") ?? "Bearer"

  const headers = new Headers({ "Content-Type": "application/json" })
  headers.set(authHeader, authHeader.toLowerCase() === "authorization" ? `${authScheme} ${token}` : token)

  const body: Record<string, unknown> = {
    number: sanitizePhone(phone),
    text,
  }

  if (instance) {
    body.instance = instance
    body.instanceId = instance
  }

  const response = await fetch(`${apiUrl}${sendPath}`, {
    method: "POST",
    headers,
    body: JSON.stringify(body),
  })

  const raw = await response.text()
  let parsed: unknown = raw
  try {
    parsed = raw ? JSON.parse(raw) : null
  } catch {
    parsed = { raw }
  }

  return {
    ok: response.ok,
    status: response.status,
    body: parsed,
  }
}

Deno.serve(async (req) => {
  if (req.method !== "POST") {
    return json({ error: "Metodo nao permitido" }, 405)
  }

  try {
    const expectedSecret = getEnv("CRON_SECRET")
    const authorization = req.headers.get("Authorization")

    if (authorization !== `Bearer ${expectedSecret}`) {
      return json({ error: "Nao autorizado" }, 401)
    }

    const supabase = createClient(
      getEnv("SUPABASE_URL"),
      getEnv("SUPABASE_SERVICE_ROLE_KEY"),
      { auth: { persistSession: false, autoRefreshToken: false } },
    )

    const { data: processos, error } = await supabase
      .from("processos_gestao_escritorio_filizola")
      .select(`
        id,
        fase_kanban,
        numero_processo,
        tipo_beneficio,
        dias_na_fase,
        cliente:clientes_gestao_escritorio_filizola(
          nome_completo,
          telefone
        )
      `)
      .in("fase_kanban", CRITICAL_PHASES)

    if (error) {
      throw error
    }

    const groupId = Deno.env.get("UAZAPI_GROUP_ID")
    const candidatos = ((processos ?? []) as ProcessoCritico[]).filter((processo) => groupId || processo.cliente?.telefone)
    const resultados = []

    for (const processo of candidatos) {
      const mensagem = buildMessage(processo)
      const telefoneDestino = groupId ?? processo.cliente?.telefone ?? ""
      const envio = await sendWhatsappMessage(telefoneDestino, mensagem)

      const { error: logError } = await supabase
        .from("notificacoes_gestao_escritorio_filizola")
        .insert({
          processo_id: processo.id,
          telefone_destino: sanitizePhone(telefoneDestino),
          mensagem,
          tipo_notificacao: processo.fase_kanban,
          status_envio: envio.ok ? "ENVIADO" : "ERRO",
          resposta_uazapi: envio.body,
          agendado_para: new Date().toISOString(),
          enviado_em: envio.ok ? new Date().toISOString() : null,
        })

      if (logError) {
        throw logError
      }

      resultados.push({
        processo_id: processo.id,
        telefone: sanitizePhone(telefoneDestino),
        fase: processo.fase_kanban,
        status: envio.ok ? "ENVIADO" : "ERRO",
        status_code: envio.status,
      })
    }

    return json({
      executado_em: new Date().toISOString(),
      total_processos_criticos: (processos ?? []).length,
      total_com_telefone: candidatos.length,
      total_enviados: resultados.filter((item) => item.status === "ENVIADO").length,
      total_com_erro: resultados.filter((item) => item.status === "ERRO").length,
      resultados,
    })
  } catch (error) {
    const message = error instanceof Error ? error.message : "Erro desconhecido"
    return json({ error: message }, 500)
  }
})
