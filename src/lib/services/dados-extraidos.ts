import { supabase } from '@/lib/supabase/client'
import type { DadoExtraido, Cliente, Processo } from '@/lib/types/database'
import { getTipoBeneficioLabel } from '@/lib/types/database'

// ============================================
// Busca de Dados Extraídos
// ============================================

export async function buscarDadosExtraidosPorProcesso(processoId: string) {
    const { data, error } = await supabase
        .from('dados_extraidos_gestao_escritorio_filizola')
        .select('*')
        .eq('processo_id', processoId)
        .order('campo', { ascending: true })

    return { dados: data as DadoExtraido[], error }
}

export async function buscarDadosExtraidosPorCliente(clienteId: string) {
    const { data, error } = await supabase
        .from('dados_extraidos_gestao_escritorio_filizola')
        .select('*')
        .eq('cliente_id', clienteId)
        .order('criado_em', { ascending: false })

    return { dados: data as DadoExtraido[], error }
}

// ============================================
// Atualização e Exclusão
// ============================================

export async function atualizarDadoExtraido(id: string, valor: string) {
    const { data, error } = await supabase
        .from('dados_extraidos_gestao_escritorio_filizola')
        .update({ valor, status: 'corrigido' })
        .eq('id', id)
        .select()
        .single()

    return { dado: data as DadoExtraido | null, error }
}

export async function confirmarDadoExtraido(id: string) {
    const { data, error } = await supabase
        .from('dados_extraidos_gestao_escritorio_filizola')
        .update({ status: 'confirmado' })
        .eq('id', id)
        .select()
        .single()

    return { dado: data as DadoExtraido | null, error }
}

export async function deletarDadosExtraidosPorProcesso(processoId: string) {
    const { error } = await supabase
        .from('dados_extraidos_gestao_escritorio_filizola')
        .delete()
        .eq('processo_id', processoId)

    return { error }
}

export async function deletarDadosExtraidosPorDocumento(documentoId: string) {
    const { error } = await supabase
        .from('dados_extraidos_gestao_escritorio_filizola')
        .delete()
        .eq('documento_origem_id', documentoId)

    return { error }
}

// ============================================
// Montar dados para petição (consolida dados extraídos + cliente + processo)
// ============================================

export async function montarDadosParaPeticao(processoId: string, clienteId: string): Promise<Record<string, string>> {
    // Buscar processo com cliente
    const { data: processo } = await supabase
        .from('processos_gestao_escritorio_filizola')
        .select('*, cliente:clientes_gestao_escritorio_filizola(*)')
        .eq('id', processoId)
        .single()

    if (!processo) return {}

    const cliente = processo.cliente as unknown as Cliente

    // Buscar dados extraídos
    const { dados: dadosExtraidos } = await buscarDadosExtraidosPorProcesso(processoId)

    // Montar mapa de campo -> valor a partir dos dados extraídos
    const mapaExtraidos: Record<string, string> = {}
    if (dadosExtraidos) {
        for (const dado of dadosExtraidos) {
            if (dado.valor && dado.valor !== 'null') {
                mapaExtraidos[dado.campo] = dado.valor
            }
        }
    }

    // Montar endereço a partir de dados extraídos ou do cliente
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

    // Adicionar variáveis extras dos dados extraídos (laudo, certidão, etc.)
    if (mapaExtraidos['diagnostico']) variaveis['diagnostico'] = mapaExtraidos['diagnostico']
    if (mapaExtraidos['cid']) variaveis['cid'] = mapaExtraidos['cid']
    if (mapaExtraidos['medico']) variaveis['medico'] = mapaExtraidos['medico']
    if (mapaExtraidos['crm']) variaveis['crm'] = mapaExtraidos['crm']
    if (mapaExtraidos['cartorio']) variaveis['cartorio'] = mapaExtraidos['cartorio']
    if (mapaExtraidos['nome_mae']) variaveis['nome_mae'] = mapaExtraidos['nome_mae']
    if (mapaExtraidos['nome_pai']) variaveis['nome_pai'] = mapaExtraidos['nome_pai']
    if (mapaExtraidos['nome_falecido']) variaveis['nome_falecido'] = mapaExtraidos['nome_falecido']
    if (mapaExtraidos['data_obito']) variaveis['data_obito'] = mapaExtraidos['data_obito']
    if (mapaExtraidos['medicamento']) variaveis['medicamento'] = mapaExtraidos['medicamento']
    if (mapaExtraidos['posologia']) variaveis['posologia'] = mapaExtraidos['posologia']
    if (mapaExtraidos['conteudo_texto']) variaveis['conteudo_texto'] = mapaExtraidos['conteudo_texto']
    if (mapaExtraidos['naturalidade']) variaveis['naturalidade'] = mapaExtraidos['naturalidade']
    if (mapaExtraidos['rg_numero']) variaveis['rg_numero'] = mapaExtraidos['rg_numero']
    if (mapaExtraidos['orgao_expedidor']) variaveis['orgao_expedidor'] = mapaExtraidos['orgao_expedidor']

    return variaveis
}
