import { supabase } from '@/lib/supabase/client'
import type { Cliente, DadoExtraidoJsonb, DadosExtraidosProcesso } from '@/lib/types/database'
import { getTipoBeneficioLabel } from '@/lib/types/database'
import { calcularIdade } from '@/lib/utils/calculo-idade'

// ============================================
// Busca de Dados Extraídos (JSONB)
// ============================================

export async function buscarDadosExtraidosPorProcesso(processoId: string) {
    const { data, error } = await supabase
        .from('dados_extraidos_gestao_escritorio_filizola')
        .select('dados')
        .eq('processo_id', processoId)
        .maybeSingle()

    return {
        dados: (data?.dados as DadosExtraidosProcesso) || {},
        error: error as Error | null,
    }
}

// ============================================
// Atualização de Campos Individuais (JSONB)
// ============================================

export async function atualizarDadoExtraido(processoId: string, campo: string, valor: string) {
    // Buscar dados atuais para preservar metadados
    const { data: current } = await supabase
        .from('dados_extraidos_gestao_escritorio_filizola')
        .select('dados')
        .eq('processo_id', processoId)
        .maybeSingle()

    const dados = current?.dados as DadosExtraidosProcesso | undefined
    const existingField = dados?.[campo] as DadoExtraidoJsonb | undefined

    const updatedDados = {
        ...(dados || {}),
        [campo]: {
            valor,
            confianca: existingField?.confianca ?? null,
            status: 'corrigido' as const,
            documento_origem_id: existingField?.documento_origem_id ?? null,
            tipo_documento_origem: existingField?.tipo_documento_origem ?? 'OUTRO',
            criado_em: existingField?.criado_em ?? new Date().toISOString(),
        },
    }

    const { error } = await supabase
        .from('dados_extraidos_gestao_escritorio_filizola')
        .update({ dados: updatedDados })
        .eq('processo_id', processoId)

    return { error: error as Error | null }
}

// ============================================
// Upsert via RPC (usado pela Edge Function)
// ============================================

export async function upsertDadosExtraidos(
    processoId: string,
    clienteId: string,
    documentoOrigemId: string,
    tipoDocumento: string,
    campos: Record<string, { valor: string; confianca: number }>,
) {
    const dadosJsonb: Record<string, { valor: string; confianca: number }> = {}
    for (const [campo, info] of Object.entries(campos)) {
        dadosJsonb[campo] = { valor: info.valor, confianca: info.confianca }
    }

    const { error } = await supabase.rpc('upsert_dados_extraidos_jsonb', {
        p_processo_id: processoId,
        p_cliente_id: clienteId,
        p_documento_origem_id: documentoOrigemId,
        p_tipo_documento_origem: tipoDocumento,
        p_dados: dadosJsonb,
    })

    return { error: error as Error | null }
}

// ============================================
// Exclusão
// ============================================

export async function deletarDadosExtraidosPorProcesso(processoId: string) {
    const { error } = await supabase
        .from('dados_extraidos_gestao_escritorio_filizola')
        .delete()
        .eq('processo_id', processoId)

    return { error: error as Error | null }
}

export async function deletarDadosExtraidosPorDocumento(processoId: string, documentoId: string) {
    const { data: current } = await supabase
        .from('dados_extraidos_gestao_escritorio_filizola')
        .select('dados')
        .eq('processo_id', processoId)
        .maybeSingle()

    const dados = current?.dados as DadosExtraidosProcesso | undefined
    if (!dados) return { error: null as Error | null }

    // Remover campos onde documento_origem_id corresponde
    const filtrado = Object.fromEntries(
        Object.entries(dados).filter(
            ([_, value]) => value.documento_origem_id !== documentoId,
        ),
    )

    const { error } = await supabase
        .from('dados_extraidos_gestao_escritorio_filizola')
        .update({ dados: filtrado })
        .eq('processo_id', processoId)

    return { error: error as Error | null }
}

// ============================================
// Montar dados para petição (consolida dados extraídos + cliente + processo)
// ============================================

export async function montarDadosParaPeticao(processoId: string, clienteId: string): Promise<Record<string, string>> {
    const { data: processo } = await supabase
        .from('processos_gestao_escritorio_filizola')
        .select('*, cliente:clientes_gestao_escritorio_filizola(*)')
        .eq('id', processoId)
        .single()

    if (!processo) return {}

    const cliente = processo.cliente as unknown as Cliente

    // Buscar dados extraídos da tabela dedicada
    const { dados: dadosExtraidos } = await buscarDadosExtraidosPorProcesso(processoId)

    // Extrair valores planos do JSONB
    const mapaExtraidos: Record<string, string> = {}
    for (const [campo, info] of Object.entries(dadosExtraidos)) {
        if (info.valor && info.valor !== 'null') {
            mapaExtraidos[campo] = info.valor
        }
    }

    // Montar endereço
    const montarEndereco = () => {
        const logradouro = mapaExtraidos['logradouro'] || cliente.endereco?.logradouro || ''
        const numero = mapaExtraidos['numero'] || cliente.endereco?.numero || ''
        const complemento = mapaExtraidos['complemento'] || cliente.endereco?.complemento || ''
        const bairro = mapaExtraidos['bairro'] || cliente.endereco?.bairro || ''
        const cidade = mapaExtraidos['cidade'] || cliente.endereco?.cidade || ''
        const uf = mapaExtraidos['uf'] || cliente.endereco?.uf || ''

        if (mapaExtraidos['endereco_completo']) {
            return mapaExtraidos['endereco_completo']
        }

        const partes = [logradouro, numero, complemento, bairro, cidade, uf].filter(Boolean)
        return partes.join(', ')
    }

    const variaveis: Record<string, string> = {
        nome: mapaExtraidos['nome_completo'] || cliente.nome_completo || '',
        cpf: mapaExtraidos['cpf'] || cliente.cpf || '',
        data_nascimento: mapaExtraidos['data_nascimento']
            || (cliente.data_nascimento ? new Date(cliente.data_nascimento).toLocaleDateString('pt-BR') : ''),
        endereco: montarEndereco(),
        telefone: cliente.telefone || '',
        email: cliente.email || '',
        tipo_beneficio: getTipoBeneficioLabel(processo.tipo_beneficio),
        numero_processo: processo.numero_processo || processo.id,
        data_atual: new Date().toLocaleDateString('pt-BR'),
        der: processo.der ? new Date(processo.der).toLocaleDateString('pt-BR') : '',
    }

    // Adicionar todos os campos extras do JSONB automaticamente
    for (const [campo, valor] of Object.entries(mapaExtraidos)) {
        if (!variaveis[campo]) {
            variaveis[campo] = valor
        }
    }

    // Calcular idade
    const dataNasc = mapaExtraidos['data_nascimento']
        || (cliente.data_nascimento ? new Date(cliente.data_nascimento).toISOString() : null)
    if (dataNasc) {
        const idadeInfo = calcularIdade(dataNasc)
        if (idadeInfo) {
            variaveis['idade'] = idadeInfo.textoPeticao
            variaveis['idade_completa'] = idadeInfo.textoFormatado
        }
    }

    // Sexo do cliente
    if (cliente.sexo && cliente.sexo !== 'nao_informado') {
        variaveis['sexo'] = cliente.sexo === 'masculino' ? 'masculino' : 'feminino'
    }

    return variaveis
}
