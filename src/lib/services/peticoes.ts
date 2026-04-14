import { supabase } from '@/lib/supabase/client'
import type { ModeloPeticao, PeticaoGerada, TipoBeneficio } from '@/lib/types/database'
import { getTipoBeneficioLabel } from '@/lib/types/database'
import { montarDadosParaPeticao } from '@/lib/services/dados-extraidos'
import { jsPDF } from 'jspdf'

// ============================================
// Variáveis disponíveis para substituição
// ============================================

export const VARIAVEIS_DISPONIVEIS: Record<string, string> = {
    nome: 'Nome completo',
    cpf: 'CPF',
    data_nascimento: 'Data de nascimento',
    endereco: 'Endereço completo',
    telefone: 'Telefone',
    email: 'E-mail',
    tipo_beneficio: 'Tipo de benefício',
    numero_processo: 'Número do processo',
    data_atual: 'Data atual',
    der: 'DER (se houver)',
    diagnostico: 'Diagnóstico (laudo)',
    cid: 'CID (laudo)',
    medico: 'Médico (laudo/atestado)',
    crm: 'CRM do médico',
    cartorio: 'Cartório (certidão)',
    nome_mae: 'Nome da mãe (certidão)',
    nome_pai: 'Nome do pai (certidão)',
    nome_falecido: 'Nome do falecido',
    data_obito: 'Data do óbito',
    medicamento: 'Medicamento (receita)',
    posologia: 'Posologia (receita)',
    conteudo_texto: 'Conteúdo (atestado/exame)',
    naturalidade: 'Naturalidade',
    rg_numero: 'Número do RG',
    orgao_expedidor: 'Órgão expedidor',
}

// ============================================
// Helpers
// ============================================

function substituirVariaveis(template: string, variaveis: Record<string, string>): string {
    let resultado = template
    for (const [chave, valor] of Object.entries(variaveis)) {
        resultado = resultado.replaceAll(`{{${chave}}}`, valor)
    }
    return resultado
}

// ============================================
// CRUD Modelos de Petição
// ============================================

export async function buscarModelosPeticao() {
    const { data, error } = await supabase
        .from('modelos_dantas_filizola')
        .select('*')
        .eq('categoria', 'peticoes')
        .order('ordem_exibicao', { ascending: true })

    return { modelos: data as ModeloPeticao[], error }
}

export async function buscarModeloPorBeneficio(tipoBeneficio: TipoBeneficio) {
    const { data, error } = await supabase
        .from('modelos_dantas_filizola')
        .select('*')
        .eq('categoria', 'peticoes')
        .eq('tipo_beneficio', tipoBeneficio)
        .eq('ativo', true)
        .maybeSingle()

    return { modelo: data as ModeloPeticao | null, error }
}

export async function salvarModeloPeticao(params: {
    tipoBeneficio: TipoBeneficio
    conteudo: string
}) {
    // Desativar template anterior do mesmo tipo de benefício
    await supabase
        .from('modelos_dantas_filizola')
        .update({ ativo: false })
        .eq('categoria', 'peticoes')
        .eq('tipo_beneficio', params.tipoBeneficio)

    // Verificar se já existe um modelo para este benefício (reativar com novo conteúdo)
    const { data: existente } = await supabase
        .from('modelos_dantas_filizola')
        .select('id')
        .eq('categoria', 'peticoes')
        .eq('tipo_beneficio', params.tipoBeneficio)
        .maybeSingle()

    if (existente) {
        // Atualizar existente
        const { data: modelo, error } = await supabase
            .from('modelos_dantas_filizola')
            .update({
                conteudo_template: params.conteudo,
                nome_original: `Template ${params.tipoBeneficio}`,
                nome_arquivo: `template_${params.tipoBeneficio}`,
                ativo: true,
            })
            .eq('id', existente.id)
            .select()
            .single()

        return { modelo: modelo as ModeloPeticao, error }
    }

    // Buscar ordem atual
    const { count } = await supabase
        .from('modelos_dantas_filizola')
        .select('id', { count: 'exact', head: true })
        .eq('categoria', 'peticoes')

    const ordem = (count ?? 0) + 1

    // Criar novo
    const { data: modelo, error } = await supabase
        .from('modelos_dantas_filizola')
        .insert({
            categoria: 'peticoes',
            tipo_beneficio: params.tipoBeneficio,
            nome_arquivo: `template_${params.tipoBeneficio}`,
            nome_original: `Template ${params.tipoBeneficio}`,
            storage_path: '',
            public_url: '',
            conteudo_template: params.conteudo,
            ativo: true,
            ordem_exibicao: ordem,
        })
        .select()
        .single()

    return { modelo: modelo as ModeloPeticao, error }
}

export async function uploadModeloPeticao(params: {
    tipoBeneficio: TipoBeneficio
    arquivo: File
}) {
    const timestamp = Date.now()
    const safeName = params.arquivo.name
        .normalize('NFD')
        .replace(/[\u0300-\u036f]/g, '')
        .replace(/[^a-zA-Z0-9._-]/g, '_')
    const storagePath = `peticoes/templates/${params.tipoBeneficio}/${timestamp}_${safeName}`

    // Desativar template anterior
    await supabase
        .from('modelos_dantas_filizola')
        .update({ ativo: false })
        .eq('categoria', 'peticoes')
        .eq('tipo_beneficio', params.tipoBeneficio)

    // Upload para o storage
    const { error: uploadError } = await supabase.storage
        .from('modelos_dantas_filizola')
        .upload(storagePath, params.arquivo, {
            cacheControl: '3600',
            upsert: false,
        })

    if (uploadError) return { modelo: null, error: uploadError }

    const { data: urlData } = supabase.storage
        .from('modelos_dantas_filizola')
        .getPublicUrl(storagePath)

    const { count } = await supabase
        .from('modelos_dantas_filizola')
        .select('id', { count: 'exact', head: true })
        .eq('categoria', 'peticoes')

    const ordem = (count ?? 0) + 1

    const { data: modelo, error } = await supabase
        .from('modelos_dantas_filizola')
        .insert({
            categoria: 'peticoes',
            tipo_beneficio: params.tipoBeneficio,
            nome_arquivo: safeName,
            nome_original: params.arquivo.name,
            storage_path: storagePath,
            public_url: urlData.publicUrl,
            mime_type: params.arquivo.type,
            tamanho_bytes: params.arquivo.size,
            extensao: params.arquivo.name.split('.').pop(),
            ativo: true,
            ordem_exibicao: ordem,
        })
        .select()
        .single()

    return { modelo: modelo as ModeloPeticao, error }
}

export async function deletarModeloPeticao(id: string) {
    const { data: modelo } = await supabase
        .from('modelos_dantas_filizola')
        .select('storage_path')
        .eq('id', id)
        .single()

    if (modelo?.storage_path) {
        await supabase.storage
            .from('modelos_dantas_filizola')
            .remove([modelo.storage_path])
    }

    const { error } = await supabase
        .from('modelos_dantas_filizola')
        .delete()
        .eq('id', id)

    return { error }
}

// ============================================
// Geração de Petições (PDF)
// ============================================

export function gerarPdf(conteudo: string, nomeCliente: string): Uint8Array {
    const doc = new jsPDF({
        orientation: 'portrait',
        unit: 'mm',
        format: 'a4',
    })

    const pageWidth = doc.internal.pageSize.getWidth()
    const margin = 20
    const maxWidth = pageWidth - margin * 2
    const lineHeight = 6
    let y = margin

    // Título
    doc.setFontSize(14)
    doc.setFont('helvetica', 'bold')
    doc.text('PETICAO', pageWidth / 2, y, { align: 'center' })
    y += 10

    // Linha separadora
    doc.setDrawColor(200, 200, 200)
    doc.line(margin, y, pageWidth - margin, y)
    y += 8

    // Conteúdo
    doc.setFontSize(12)
    doc.setFont('helvetica', 'normal')

    // Limpar caracteres especiais que o jsPDF não suporta nativamente
    const cleanedContent = conteudo
        .replace(/[\u2018\u2019]/g, "'")
        .replace(/[\u201C\u201D]/g, '"')
        .replace(/\u2013/g, '-')
        .replace(/\u2014/g, '--')
        .replace(/\u2026/g, '...')

    const paragraphs = cleanedContent.split('\n')

    for (const paragraph of paragraphs) {
        if (y > 270) {
            doc.addPage()
            y = margin
        }

        if (paragraph.trim() === '') {
            y += lineHeight
            continue
        }

        const lines = doc.splitTextToSize(paragraph, maxWidth)

        for (const line of lines) {
            if (y > 270) {
                doc.addPage()
                y = margin
            }
            doc.text(line, margin, y)
            y += lineHeight
        }
    }

    return new Uint8Array(doc.output('arraybuffer'))
}

export async function gerarPeticao(params: {
    processoId: string
    clienteId: string
    modeloId?: string
}) {
    // Buscar processo com cliente
    const { data: processo } = await supabase
        .from('processos_gestao_escritorio_filizola')
        .select('*, cliente:clientes_gestao_escritorio_filizola(*)')
        .eq('id', params.processoId)
        .single()

    if (!processo) {
        return { peticao: null, error: new Error('Processo não encontrado') }
    }

    const cliente = processo.cliente as { nome_completo?: string }

    // Buscar modelo - por ID ou por tipo de benefício
    let modelo: ModeloPeticao | null = null

    if (params.modeloId) {
        const { data } = await supabase
            .from('modelos_dantas_filizola')
            .select('*')
            .eq('id', params.modeloId)
            .single()
        modelo = data as ModeloPeticao | null
    }

    if (!modelo) {
        const { data } = await supabase
            .from('modelos_dantas_filizola')
            .select('*')
            .eq('categoria', 'peticoes')
            .eq('tipo_beneficio', processo.tipo_beneficio)
            .eq('ativo', true)
            .maybeSingle()
        modelo = data as ModeloPeticao | null
    }

    if (!modelo) {
        return { peticao: null, error: new Error('Nenhum template de petição configurado para este tipo de benefício') }
    }

    // Obter template: preferir conteudo_template, fallback para arquivo no storage
    let templateText = modelo.conteudo_template || ''

    if (!templateText && modelo.storage_path) {
        const { data: fileData, error: downloadError } = await supabase.storage
            .from('modelos_dantas_filizola')
            .download(modelo.storage_path)

        if (downloadError || !fileData) {
            return { peticao: null, error: downloadError ?? new Error('Erro ao baixar template') }
        }

        templateText = await fileData.text()
    }

    if (!templateText) {
        return { peticao: null, error: new Error('Template vazio') }
    }

    // Montar variáveis a partir de dados extraídos + cliente + processo
    const variaveis = await montarDadosParaPeticao(params.processoId, params.clienteId)

    // Substituir variáveis
    const conteudoGerado = substituirVariaveis(templateText, variaveis)

    // Gerar PDF
    const pdfBuffer = gerarPdf(conteudoGerado, cliente?.nome_completo || 'cliente')

    // Salvar PDF no storage
    const timestamp = Date.now()
    const storagePath = `peticoes/geradas/${params.clienteId}/${params.processoId}/${timestamp}.pdf`

    const blob = new Blob([pdfBuffer.buffer as ArrayBuffer], { type: 'application/pdf' })
    const { error: uploadError } = await supabase.storage
        .from('peticoes_geradas')
        .upload(storagePath, blob, {
            cacheControl: '3600',
            upsert: false,
        })

    if (uploadError) {
        return { peticao: null, error: uploadError }
    }

    // Inserir registro no banco
    const { data: peticao, error } = await supabase
        .from('peticoes_geradas_gestao_escritorio_filizola')
        .insert({
            processo_id: params.processoId,
            cliente_id: params.clienteId,
            modelo_id: modelo.id,
            tipo_beneficio: processo.tipo_beneficio,
            conteudo_gerado: conteudoGerado,
            variaveis_usadas: variaveis,
            storage_path: storagePath,
            status_geracao: 'concluido',
        })
        .select()
        .single()

    return { peticao: peticao as PeticaoGerada, error }
}

// ============================================
// Busca de Petições Geradas
// ============================================

export async function buscarPeticoesPorProcesso(processoId: string) {
    const { data, error } = await supabase
        .from('peticoes_geradas_gestao_escritorio_filizola')
        .select('*')
        .eq('processo_id', processoId)
        .order('criado_em', { ascending: false })

    return { peticoes: data as PeticaoGerada[], error }
}

export async function buscarPeticoesPorCliente(clienteId: string) {
    const { data, error } = await supabase
        .from('peticoes_geradas_gestao_escritorio_filizola')
        .select('*')
        .eq('cliente_id', clienteId)
        .order('criado_em', { ascending: false })

    return { peticoes: data as PeticaoGerada[], error }
}

export async function getUrlPeticaoGerada(storagePath: string) {
    const { data, error } = await supabase.storage
        .from('peticoes_geradas')
        .createSignedUrl(storagePath, 60 * 30)

    return { url: data?.signedUrl ?? null, error }
}

export async function salvarPeticaoEditada(params: {
    peticaoId: string
    conteudoEditado: string
    nomeCliente: string
}) {
    // Atualizar conteúdo no banco
    const { error: updateError } = await supabase
        .from('peticoes_geradas_gestao_escritorio_filizola')
        .update({ conteudo_gerado: params.conteudoEditado })
        .eq('id', params.peticaoId)

    if (updateError) {
        return { error: updateError }
    }

    // Buscar storage_path da petição
    const { data: peticao, error: fetchError } = await supabase
        .from('peticoes_geradas_gestao_escritorio_filizola')
        .select('storage_path')
        .eq('id', params.peticaoId)
        .single()

    if (fetchError || !peticao?.storage_path) {
        return { error: fetchError ?? new Error('Storage path não encontrado') }
    }

    // Regenerar PDF
    const pdfBuffer = gerarPdf(params.conteudoEditado, params.nomeCliente)
    const blob = new Blob([pdfBuffer.buffer as ArrayBuffer], { type: 'application/pdf' })

    // Fazer upload (upsert para sobrescrever o PDF anterior)
    const { error: uploadError } = await supabase.storage
        .from('peticoes_geradas')
        .upload(peticao.storage_path, blob, {
            cacheControl: '3600',
            upsert: true,
        })

    return { error: uploadError }
}
