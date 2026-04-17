import "@supabase/functions-js/edge-runtime.d.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.57.4"

type DocumentoRow = {
  id: string
  processo_id: string
  tipo_documento: string
  categoria_documento: string
  storage_path: string
  mimetype: string | null
}

type ExigenciaRow = {
  tipo_documento: string
  obrigatorio: boolean
  ordem_exibicao: number
}

type Classificacao = {
  tipo: string
  categoria: string
  qualidade: "LEGIVEL" | "ILEGIVEL" | "PENDENTE_ANALISE"
  metadados: Record<string, unknown>
}

type DadoExtraidoRow = {
  campo: string
  valor: string | null
  confianca: number
}

const AI_MODEL = Deno.env.get("AI_MODEL") ?? "openai/gpt-4o"
const OPENROUTER_URL = "https://openrouter.ai/api/v1/chat/completions"
const ALL_DOCUMENT_TYPES = [
  "RG",
  "CNH",
  "CPF",
  "COMPROVANTE_RESIDENCIA",
  "TITULO_ELEITOR",
  "CTPS",
  "CADUNICO",
  "NIS_NIT",
  "LAUDO_MEDICO",
  "EXAME",
  "ATESTADO",
  "RECEITA",
  "CERTIDAO_NASCIMENTO",
  "CERTIDAO_CASAMENTO",
  "CERTIDAO_OBITO",
  "RG_FALECIDO",
  "CPF_FALECIDO",
  "PROCURACAO",
  "CONTRATO",
  "OUTRO",
] as const

const ALL_CATEGORIES = [
  "DADOS_PESSOAIS",
  "DOCUMENTOS_FAMILIA",
  "DOCUMENTOS_FALECIDO",
  "COMPROVANTE_RENDA",
  "DOCUMENTOS_MEDICOS",
  "DOCUMENTOS_TRABALHISTAS",
  "CONTRATOS",
  "OUTROS",
] as const

// Campos a extrair por tipo de documento
const CAMPOS_EXTRACAO: Record<string, string[]> = {
  RG: ["nome_completo", "cpf", "data_nascimento", "naturalidade", "uf_naturalidade", "rg_numero", "orgao_expedidor"],
  CNH: ["nome_completo", "cpf", "data_nascimento", "endereco_completo", "cnh_numero", "validade"],
  CPF: ["cpf", "nome_completo"],
  COMPROVANTE_RESIDENCIA: ["logradouro", "numero", "complemento", "bairro", "cidade", "uf", "cep", "endereco_completo", "nome_completo", "cpf"],
  CTPS: ["nome_completo", "cpf", "data_nascimento", "ctps_numero", "serie"],
  CERTIDAO_NASCIMENTO: ["nome_completo", "data_nascimento", "nome_mae", "nome_pai", "cartorio", "registro"],
  LAUDO_MEDICO: ["cid", "diagnostico", "data_laudo", "medico", "crm"],
  ATESTADO: ["conteudo_texto", "data_atestado", "medico"],
  RECEITA: ["medicamento", "posologia", "data_receita", "medico"],
  CERTIDAO_OBITO: ["nome_falecido", "data_obito", "cartorio"],
  TITULO_ELEITOR: ["nome_completo", "cpf", "titulo_numero", "zona", "secao"],
  EXAME: ["conteudo_texto", "data_exame", "medico", "tipo_exame"],
  CERTIDAO_CASAMENTO: ["nome_conjuge1", "nome_conjuge2", "data_casamento", "cartorio"],
}

const CORS_HEADERS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
}

function json(data: unknown, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { "Content-Type": "application/json", ...CORS_HEADERS },
  })
}

function getEnv(name: string) {
  const value = Deno.env.get(name)
  if (!value) {
    throw new Error(`Variavel de ambiente ausente: ${name}`)
  }
  return value
}

function extractJsonObject(content: string) {
  const cleaned = content.replace(/```json/gi, "").replace(/```/g, "").trim()
  const start = cleaned.indexOf("{")
  const end = cleaned.lastIndexOf("}")
  if (start === -1 || end === -1) {
    throw new Error("Resposta da IA nao retornou JSON valido")
  }
  return JSON.parse(cleaned.slice(start, end + 1))
}

function inferCategory(tipoDocumento: string) {
  const map: Record<string, (typeof ALL_CATEGORIES)[number]> = {
    RG: "DADOS_PESSOAIS",
    CNH: "DADOS_PESSOAIS",
    CPF: "DADOS_PESSOAIS",
    COMPROVANTE_RESIDENCIA: "DADOS_PESSOAIS",
    TITULO_ELEITOR: "DADOS_PESSOAIS",
    CTPS: "DOCUMENTOS_TRABALHISTAS",
    CADUNICO: "COMPROVANTE_RENDA",
    NIS_NIT: "DOCUMENTOS_TRABALHISTAS",
    LAUDO_MEDICO: "DOCUMENTOS_MEDICOS",
    EXAME: "DOCUMENTOS_MEDICOS",
    ATESTADO: "DOCUMENTOS_MEDICOS",
    RECEITA: "DOCUMENTOS_MEDICOS",
    CERTIDAO_NASCIMENTO: "DOCUMENTOS_FAMILIA",
    CERTIDAO_CASAMENTO: "DOCUMENTOS_FAMILIA",
    CERTIDAO_OBITO: "DOCUMENTOS_FALECIDO",
    RG_FALECIDO: "DOCUMENTOS_FALECIDO",
    CPF_FALECIDO: "DOCUMENTOS_FALECIDO",
    PROCURACAO: "CONTRATOS",
    CONTRATO: "CONTRATOS",
    OUTRO: "OUTROS",
  }

  return map[tipoDocumento] ?? "OUTROS"
}

async function arrayBufferToBase64(file: Blob) {
  const buffer = await file.arrayBuffer()
  const bytes = new Uint8Array(buffer)
  let binary = ""
  for (const byte of bytes) {
    binary += String.fromCharCode(byte)
  }
  return btoa(binary)
}

function buildExtractionPrompt(tipoDocumento: string, campos: string[]): string {
  const camposJson = campos.map((c) => `"${c}"`).join(", ")

  // Instrucoes especificas por tipo para ajudar a IA a encontrar dados em lugares nao-obvios
  const instrucoesPorTipo: Record<string, string> = {
    RG: [
      "Este e um documento de identidade (RG) brasileiro. Pode ser a frente ou o verso.",
      "CAMPO CPF: Procure atentamente o numero de CPF no documento. No RG antigo (modelo cartesiano), o CPF geralmente esta impresso no verso, junto com naturalidade e data de nascimento. No RG novo (RG digital/CIN), o CPF pode aparecer na frente como 'Numero de Registro Identificador' (RNE) ou no verso. O CPF tem formato XXX.XXX.XXX-XX com 11 digitos.",
      "Frente do RG geralmente contem: nome, foto, rg_numero, orgao_expedidor, data de expedicao.",
      "Verso do RG geralmente contem: CPF, data_nascimento, naturalidade, uf_naturalidade, filiacao (nome_pai, nome_mae).",
      "BUSQUE O CPF COM ATENCAO ESPECIAL - ele quase sempre esta presente no RG.",
    ].join(" "),
    CNH: [
      "Esta e uma Carteira Nacional de Habilitacao (CNH) brasileira.",
      "CAMPO CPF: Na CNH, o CPF aparece como 'Registro Identificador' (REG IDENT) ou 'Numero do Registro' na parte superior. E um numero de 11 digitos no formato XXX.XXX.XXX-XX. Procure na area de dados pessoais da CNH.",
      "CAMPO NOME: Geralmente na parte superior sob a foto.",
      "CAMPO CPF: Pode estar rotulado como 'Registro Identificador', 'Reg. Ident.', 'CPF' ou apenas um numero de 11 digitos na parte de identificacao do documento.",
    ].join(" "),
    CPF: [
      "Este e um comprovante de cadastro de CPF (pode ser cartao, boleto ou print do site da Receita Federal).",
      "Extraia o numero do CPF e o nome do titular se visivel.",
    ].join(" "),
    COMPROVANTE_RESIDENCIA: [
      "Este e um comprovante de residencia (conta de luz, agua, gas, telefone, internet, etc.).",
      "Extraia o endereco completo: logradouro, numero, complemento, bairro, cidade, UF e CEP.",
      "O nome do titular e o CPF podem aparecer no comprovante - extraia se visivel.",
    ].join(" "),
    CTPS: [
      "Esta e uma Carteira de Trabalho e Previdencia Social (CTPS).",
      "CAMPO CPF: O CPF do trabalhador geralmente aparece na pagina de identificacao da CTPS. Procure por um numero de 11 digitos.",
    ].join(" "),
    TITULO_ELEITOR: [
      "Este e um titulo de eleitor brasileiro.",
      "CAMPO CPF: O CPF pode aparecer no titulo de eleitor. Procure na parte de dados pessoais.",
    ].join(" "),
    DOCUMENTO_GENERICO: [
      "Este e um documento brasileiro com dados pessoais.",
      "Procure por: nome completo, CPF (numero de 11 digitos formato XXX.XXX.XXX-XX), data de nascimento.",
      "Extraia qualquer dado pessoal legivel que encontrar.",
    ].join(" "),
  }

  const instrucoes = instrucoesPorTipo[tipoDocumento]

  return [
    `Voce e um especialista em extracao de dados de documentos com atencao especial a numeros de CPF.`,
    `Tipo do documento: ${tipoDocumento}.`,
    instrucoes ? `Informacoes especificas: ${instrucoes}` : "",
    `Campos a extrair: ${camposJson}.`,
    `Alem disso, inclua um campo "confianca_geral" com um valor numerico de 0.0 a 1.0.`,
    "Regras para confianca_geral: 1.0 = tudo legivel, 0.7-0.9 = maioria legivel, 0.5-0.6 = parcialmente legivel, 0.0-0.4 = quase ilegivel.",
    "Regras IMPORTANTES:",
    "- Para CPF: sempre use o formato XXX.XXX.XXX-XX (11 digitos com pontos e traco).",
    "- Para datas: sempre use DD/MM/AAAA.",
    "- Se um campo nao for encontrado, use null. NUNCA invente dados.",
    "- O CPF e um numero de 11 digitos. Se encontrar um numero que parece CPF em qualquer parte do documento, extraia-o.",
    "- Retorne APENAS o JSON valido, sem texto adicional antes ou depois.",
    `Formato: {"campo1":"valor1","campo2":"valor2",...,"confianca_geral":0.95}`,
  ].filter(Boolean).join(" ")
}

async function classificarDocumento(params: {
  base64: string
  mimetype: string
  tiposEsperados: string[]
}) {
  const prompt = [
    "Analise este documento brasileiro.",
    `Escolha o tipo mais provavel entre: ${params.tiposEsperados.join(", ")}.`,
    `Se nenhum tipo fizer sentido, responda OUTRO. Tipos permitidos: ${ALL_DOCUMENT_TYPES.join(", ")}.`,
    `Categorias permitidas: ${ALL_CATEGORIES.join(", ")}.`,
    "IMPORTANTE: Se o documento for o VERSO de um RG, CNH ou outro documento de identidade, classifique-o com o mesmo tipo (RG, CNH, etc). O verso de um RG deve ser classificado como RG.",
    "IMPORTANTE: Documentos que contenham dados pessoais como nome, CPF, data de nascimento, naturalidade, filiação devem ser classificados como RG ou CNH mesmo que seja apenas o verso.",
    "Avalie a qualidade como LEGIVEL se o texto estiver legivel (mesmo que parcialmente), ILEGIVEL se estiver totalmente ilegivel ou borrado, ou PENDENTE_ANALISE se nao tiver certeza.",
    'Retorne apenas JSON valido no formato: {"tipo":"RG","categoria":"DADOS_PESSOAIS","qualidade":"LEGIVEL","metadados":{}}',
  ].join(" ")

  const response = await fetch(OPENROUTER_URL, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "Authorization": `Bearer ${getEnv("OPENROUTER_API_KEY")}`,
      "HTTP-Referer": getEnv("SUPABASE_URL"),
      "X-Title": "D&F Gestao - Analise Documentos",
    },
    body: JSON.stringify({
      model: AI_MODEL,
      temperature: 0,
      max_tokens: 1000,
      messages: [
        {
          role: "user",
          content: [
            { type: "text", text: prompt },
            {
              type: "image_url",
              image_url: {
                url: `data:${params.mimetype};base64,${params.base64}`,
              },
            },
          ],
        },
      ],
    }),
  })

  if (!response.ok) {
    const errorBody = await response.text()
    console.error(`[classificarDocumento] OpenRouter erro ${response.status}:`, errorBody)
    throw new Error(`Falha ao consultar OpenRouter: ${response.status} - ${errorBody.slice(0, 200)}`)
  }

  const payload = await response.json()
  const content = payload?.choices?.[0]?.message?.content
  if (typeof content !== "string") {
    console.error("[classificarDocumento] Resposta sem conteudo:", JSON.stringify(payload).slice(0, 300))
    throw new Error("OpenRouter retornou resposta sem conteudo de classificacao")
  }

  const parsed = extractJsonObject(content) as Partial<Classificacao>
  const tipo = ALL_DOCUMENT_TYPES.includes((parsed.tipo ?? "") as (typeof ALL_DOCUMENT_TYPES)[number])
    ? parsed.tipo!
    : "OUTRO"
  const categoria = ALL_CATEGORIES.includes((parsed.categoria ?? "") as (typeof ALL_CATEGORIES)[number])
    ? parsed.categoria!
    : inferCategory(tipo)
  const qualidade = parsed.qualidade === "LEGIVEL" || parsed.qualidade === "ILEGIVEL" || parsed.qualidade === "PENDENTE_ANALISE"
    ? parsed.qualidade
    : "PENDENTE_ANALISE"

  return {
    tipo,
    categoria,
    qualidade,
    metadados: parsed.metadados && typeof parsed.metadados === "object" ? parsed.metadados : {},
  } satisfies Classificacao
}

async function extrairDadosDocumento(params: {
  base64: string
  mimetype: string
  tipoDocumento: string
  campos: string[]
}): Promise<{ dados: DadoExtraidoRow[]; confiancaGeral: number }> {
  const prompt = buildExtractionPrompt(params.tipoDocumento, params.campos)

  const response = await fetch(OPENROUTER_URL, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "Authorization": `Bearer ${getEnv("OPENROUTER_API_KEY")}`,
      "HTTP-Referer": getEnv("SUPABASE_URL"),
      "X-Title": "D&F Gestao - Extracao Dados",
    },
    body: JSON.stringify({
      model: AI_MODEL,
      temperature: 0,
      max_tokens: 2000,
      messages: [
        {
          role: "user",
          content: [
            { type: "text", text: prompt },
            {
              type: "image_url",
              image_url: {
                url: `data:${params.mimetype};base64,${params.base64}`,
              },
            },
          ],
        },
      ],
    }),
  })

  if (!response.ok) {
    const errorBody = await response.text()
    console.error(`[extrairDadosDocumento] OpenRouter erro ${response.status}:`, errorBody)
    throw new Error(`Falha ao consultar OpenRouter para extracao: ${response.status} - ${errorBody.slice(0, 200)}`)
  }

  const payload = await response.json()
  const content = payload?.choices?.[0]?.message?.content
  if (typeof content !== "string") {
    throw new Error("OpenRouter retornou resposta sem conteudo de extracao")
  }

  const parsed = extractJsonObject(content) as Record<string, unknown>

  const confiancaGeral = typeof parsed.confianca_geral === "number"
    ? parsed.confianca_geral
    : 0.5

  const dados: DadoExtraidoRow[] = []
  for (const campo of params.campos) {
    const valor = parsed[campo]
    if (valor !== undefined && valor !== null) {
      dados.push({
        campo,
        valor: String(valor),
        confianca: confiancaGeral,
      })
    }
  }

  return { dados, confiancaGeral }
}

async function salvarDadosExtraidos(
  supabase: ReturnType<typeof createClient>,
  processoId: string,
  clienteId: string,
  documentoId: string,
  tipoDocumento: string,
  dados: DadoExtraidoRow[],
) {
  if (dados.length === 0) return

  const campos = dados.map((d) => ({
    campo: d.campo,
    valor: d.valor,
    confianca: d.confianca,
  }))

  const { data, error } = await supabase.rpc("insert_dados_extraidos", {
    p_processo_id: processoId,
    p_cliente_id: clienteId,
    p_documento_origem_id: documentoId,
    p_tipo_documento_origem: tipoDocumento,
    p_campos: campos,
  })

  if (error) {
    console.error("Erro ao salvar dados extraidos via RPC:", JSON.stringify(error))
    throw new Error(`Erro ao salvar dados extraidos: ${error.message}`)
  }

  if (data?.success === false) {
    console.error("Erro no insert RPC:", JSON.stringify(data))
    throw new Error(`Erro ao salvar dados extraidos: ${data.error}`)
  }
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: CORS_HEADERS })
  }

  if (req.method !== "POST") {
    return json({ error: "Metodo nao permitido" }, 405)
  }

  try {
    const { processo_id } = await req.json()
    if (!processo_id) {
      return json({ error: "processo_id e obrigatorio" }, 400)
    }

    const supabase = createClient(
      getEnv("SUPABASE_URL"),
      getEnv("SUPABASE_SERVICE_ROLE_KEY"),
      { auth: { persistSession: false, autoRefreshToken: false } },
    )

    const { data: processo, error: processoError } = await supabase
      .from("processos_gestao_escritorio_filizola")
      .select("id, tipo_beneficio, fase_kanban, cliente_id")
      .eq("id", processo_id)
      .single()

    if (processoError || !processo) {
      throw processoError ?? new Error("Processo nao encontrado")
    }

    const clienteId = processo.cliente_id

    const { data: exigencias, error: exigenciasError } = await supabase
      .from("exigencias_doc_gestao_escritorio_filizola")
      .select("tipo_documento, obrigatorio, ordem_exibicao")
      .eq("tipo_beneficio", processo.tipo_beneficio)
      .eq("ativo", true)
      .order("ordem_exibicao", { ascending: true })

    if (exigenciasError) {
      throw exigenciasError
    }

    const { data: documentos, error: documentosError } = await supabase
      .from("documentos_gestao_escritorio_filizola")
      .select("id, processo_id, tipo_documento, categoria_documento, storage_path, mimetype")
      .eq("processo_id", processo_id)

    if (documentosError) {
      throw documentosError
    }

    if (!documentos?.length) {
      return json({ error: "Nenhum documento encontrado para o processo" }, 404)
    }

    const tiposEsperados = Array.from(
      new Set([...(exigencias ?? []).map((item: ExigenciaRow) => item.tipo_documento), ...ALL_DOCUMENT_TYPES]),
    )

    const resultados = []
    const dadosExtraidosTotal: { documento_id: string; tipo: string; campos_extraidos: number }[] = []

    for (const documento of documentos as DocumentoRow[]) {
      const { data: fileData, error: downloadError } = await supabase.storage
        .from("documentos_processuais")
        .download(documento.storage_path)

      if (downloadError || !fileData) {
        throw downloadError ?? new Error(`Falha ao baixar ${documento.storage_path}`)
      }

      const base64 = await arrayBufferToBase64(fileData)
      const mimetype = documento.mimetype ?? "application/octet-stream"

      // 1. Classificar documento
      const classificacao = await classificarDocumento({
        base64,
        mimetype,
        tiposEsperados,
      })

      const { error: updateError } = await supabase
        .from("documentos_gestao_escritorio_filizola")
        .update({
          tipo_documento: classificacao.tipo,
          categoria_documento: classificacao.categoria,
          qualidade_documento: classificacao.qualidade,
          metadados_ia: classificacao.metadados,
          classificado_por_ia: true,
        })
        .eq("id", documento.id)

      if (updateError) {
        throw updateError
      }

      resultados.push({
        documento_id: documento.id,
        tipo_documento: classificacao.tipo,
        categoria_documento: classificacao.categoria,
        qualidade_documento: classificacao.qualidade,
      })

      // 2. Extrair dados se documento for legivel e tiver cliente vinculado
      if (classificacao.qualidade === "LEGIVEL" && clienteId) {
        const campos = CAMPOS_EXTRACAO[classificacao.tipo]
        // Se o tipo tiver campos mapeados, usar especificos. Senao, usar campos genericos
        const camposParaExtrair = campos ?? ["nome_completo", "cpf", "data_nascimento"]

        try {
          const { dados, confiancaGeral } = await extrairDadosDocumento({
            base64,
            mimetype,
            tipoDocumento: campos ? classificacao.tipo : "DOCUMENTO_GENERICO",
            campos: camposParaExtrair,
          })

          // Se confianca geral < 0.5, marcar documento como ilegivel
          if (confiancaGeral < 0.5 && classificacao.qualidade === "LEGIVEL") {
            await supabase
              .from("documentos_gestao_escritorio_filizola")
              .update({ qualidade_documento: "ILEGIVEL" })
              .eq("id", documento.id)

            resultados[resultos.length - 1].qualidade_documento = "ILEGIVEL"
          } else {
            await salvarDadosExtraidos(
              supabase,
              processo_id,
              clienteId,
              documento.id,
              classificacao.tipo,
              dados,
            )
          }

          dadosExtraidosTotal.push({
            documento_id: documento.id,
            tipo: classificacao.tipo,
            campos_extraidos: dados.length,
          })
        } catch (extracaoError) {
          const msg = extracaoError instanceof Error ? extracaoError.message : String(extracaoError)
          // Erro de insert no banco = problema critico, propagar
          if (msg.startsWith("Erro ao salvar dados extraidos")) {
            throw extracaoError
          }
          console.error(`Erro na extracao do documento ${documento.id}:`, msg)
          // Nao falhar toda a analise por erro de extracao da IA
        }
      }
    }

    // Extrair variaveis customizadas do template ativo para este tipo de beneficio
    try {
      const { data: modeloAtivo } = await supabase
        .from("modelos_dantas_filizola")
        .select("variaveis_customizadas")
        .eq("categoria", "peticoes")
        .eq("tipo_beneficio", tipoBeneficio)
        .eq("ativo", true)
        .maybeSingle()

      const variaveisCustom = (modeloAtivo?.variaveis_customizadas as string[]) ?? []
      if (variaveisCustom.length > 0 && clienteId) {
        // Buscar campos ja extraidos para nao duplicar
        const { data: camposJaExtraidos } = await supabase
          .from("dados_extraidos_gestao_escritorio_filizola")
          .select("campo")
          .eq("processo_id", processo_id)

        const camposExistentes = new Set(
          (camposJaExtraidos ?? []).map((d: { campo: string }) => d.campo),
        )

        const variaveisParaExtrair = variaveisCustom.filter(
          (v: string) => !camposExistentes.has(v),
        )

        if (variaveisParaExtrair.length > 0) {
          // Buscar um documento legivel para extrair as variaveis customizadas
          const docLegivel = resultados.find(
            (r: { qualidade_documento: string }) => r.qualidade_documento === "LEGIVEL",
          )
          if (docLegivel) {
            const docRow = (documentos as DocumentoRow[]).find(
              (d: DocumentoRow) => d.id === docLegivel.documento_id,
            )
            if (docRow) {
              const { data: fileData } = await supabase.storage
                .from("documentos_processuais")
                .download(docRow.storage_path)
              if (fileData) {
                const base64 = await arrayBufferToBase64(fileData)
                const mimetype = docRow.mimetype ?? "application/octet-stream"
                const { dados: dadosCustom, confiancaGeral: confCustom } =
                  await extrairDadosDocumento({
                    base64,
                    mimetype,
                    tipoDocumento: "DOCUMENTO_GENERICO",
                    campos: variaveisParaExtrair,
                  })
                if (dadosCustom.length > 0 && confCustom >= 0.5) {
                  await salvarDadosExtraidos(
                    supabase,
                    processo_id,
                    clienteId,
                    docRow.id,
                    "DOCUMENTO_GENERICO",
                    dadosCustom,
                  )
                }
              }
            }
          }
        }
      }
    } catch (customVarError) {
      console.error("Erro ao extrair variaveis customizadas:", customVarError)
      // Nao falhar toda a analise por erro de variaveis customizadas
    }

    // Recalcular checklist apos possiveis mudancas de qualidade
    const documentosLegiveis = new Set(
      resultados
        .filter((item) => item.qualidade_documento === "LEGIVEL")
        .map((item) => item.tipo_documento),
    )

    const documentosIlegiveis = new Set(
      resultados
        .filter((item) => item.qualidade_documento === "ILEGIVEL")
        .map((item) => item.tipo_documento),
    )

    // Buscar dados extraidos para considerar campos extraidos de outros documentos
    const { data: todosDadosExtraidos } = await supabase
      .from("dados_extraidos_gestao_escritorio_filizola")
      .select("campo, valor")
      .eq("processo_id", processo_id)

    const camposExtraidos = new Set(
      (todosDadosExtraidos ?? [])
        .filter((d: { campo: string; valor: string | null }) => d.valor && d.valor !== "null")
        .map((d: { campo: string }) => d.campo),
    )

    // Mapeamento: tipo de documento exigido -> campo extraido que satisfaz a exigencia
    // Ex: se a exigencia e "CPF" e o campo "cpf" foi extraido de um RG, marca como ENTREGUE
    const CAMPO_SATISFAZ_EXIGENCIA: Record<string, string[]> = {
      CPF: ["cpf"],
    }

    const checklist = (exigencias ?? []).map((exigencia: ExigenciaRow) => {
      let status = "FALTANDO"

      if (documentosLegiveis.has(exigencia.tipo_documento)) {
        status = "ENTREGUE"
      } else if (documentosIlegiveis.has(exigencia.tipo_documento)) {
        status = "ILEGIVEL"
      } else {
        // Verificar se os dados foram extraidos de outro documento
        const camposNecessarios = CAMPO_SATISFAZ_EXIGENCIA[exigencia.tipo_documento]
        if (camposNecessarios && camposNecessarios.every((campo) => camposExtraidos.has(campo))) {
          status = "ENTREGUE"
        }
      }

      return {
        documento: exigencia.tipo_documento,
        obrigatorio: exigencia.obrigatorio,
        ordem: exigencia.ordem_exibicao,
        status,
      }
    })

    const temPendencia = checklist.some((item) => item.status !== "ENTREGUE" && item.obrigatorio)

    let novaFase = processo.fase_kanban

    if (temPendencia) {
      const { error: faseError } = await supabase
        .from("processos_gestao_escritorio_filizola")
        .update({ fase_kanban: "DOC_PENDENTE" })
        .eq("id", processo_id)

      if (faseError) {
        throw faseError
      }
      novaFase = "DOC_PENDENTE"
    } else {
      const { error: faseError } = await supabase
        .from("processos_gestao_escritorio_filizola")
        .update({ fase_kanban: "APROVACAO_GESTOR" })
        .eq("id", processo_id)

      if (faseError) {
        throw faseError
      }
      novaFase = "APROVACAO_GESTOR"
    }

    return json({
      processo_id,
      fase_atualizada_para: novaFase,
      documentos_analisados: resultados.length,
      tem_pendencia: temPendencia,
      checklist,
      resultados,
      dados_extraidos: dadosExtraidosTotal,
    })
  } catch (error) {
    const message = error instanceof Error ? error.message : typeof error === "string" ? error : JSON.stringify(error)
    console.error("[analisar-documentos] Erro na analise:", message)
    if (error instanceof Error && error.stack) {
      console.error("[analisar-documentos] Stack:", error.stack)
    }
    return json({ error: message }, 500)
  }
})
