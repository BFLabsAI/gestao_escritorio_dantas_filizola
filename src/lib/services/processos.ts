import { supabase } from '@/lib/supabase/client'
import type { Processo, FaseKanban, TipoBeneficio } from '@/lib/types/database'

export async function buscarProcessos(filtros?: {
    busca?: string
    fases?: FaseKanban[]
    urgencia?: boolean
    cliente_id?: string
}) {
    let query = supabase
        .from('processos_gestao_escritorio_filizola')
        .select(`
            *,
            cliente:clientes_gestao_escritorio_filizola(id, nome_completo, cpf, telefone, email)
        `)
        .order('criado_em', { ascending: false })

    if (filtros?.fases?.length) {
        query = query.in('fase_kanban', filtros.fases)
    }

    if (filtros?.urgencia !== undefined) {
        query = query.eq('urgencia', filtros.urgencia)
    }

    if (filtros?.cliente_id) {
        query = query.eq('cliente_id', filtros.cliente_id)
    }

    if (filtros?.busca) {
        query = query.or(`cliente.nome_completo.ilike.%${filtros.busca}%,numero_processo.ilike.%${filtros.busca}%`)
    }

    const { data, error } = await query
    return { processos: data as Processo[], error }
}

export async function buscarProcessoPorId(id: string) {
    const { data, error } = await supabase
        .from('processos_gestao_escritorio_filizola')
        .select(`
            *,
            cliente:clientes_gestao_escritorio_filizola(id, nome_completo, cpf, telefone, email)
        `)
        .eq('id', id)
        .single()

    return { processo: data as Processo, error }
}

export async function criarProcesso(processo: {
    numero_processo?: string
    cliente_id: string
    tipo_beneficio: TipoBeneficio
    observacoes?: string
}) {
    const { data, error } = await supabase
        .from('processos_gestao_escritorio_filizola')
        .insert(processo)
        .select(`
            *,
            cliente:clientes_gestao_escritorio_filizola(id, nome_completo, cpf, telefone, email)
        `)
        .single()

    return { processo: data, error }
}

export async function moverProcessoFase(processoId: string, novaFase: FaseKanban) {
    const { data, error } = await supabase
        .from('processos_gestao_escritorio_filizola')
        .update({ fase_kanban: novaFase })
        .eq('id', processoId)
        .select(`
            *,
            cliente:clientes_gestao_escritorio_filizola(id, nome_completo, cpf, telefone, email)
        `)
        .single()

    return { processo: data as Processo, error }
}

export async function buscarProcessosPorCliente(clienteId: string) {
    const { data, error } = await supabase
        .from('processos_gestao_escritorio_filizola')
        .select('*')
        .eq('cliente_id', clienteId)
        .order('criado_em', { ascending: false })

    return { processos: data as Processo[], error }
}

export async function deletarProcesso(id: string) {
    // 1. Buscar documentos do processo para apagar do Storage
    const { data: documentos, error: erroDocs } = await supabase
        .from('documentos_gestao_escritorio_filizola')
        .select('id, storage_path')
        .eq('processo_id', id)

    if (!erroDocs && documentos && documentos.length > 0) {
        // 2. Apagar arquivos do Supabase Storage
        const storagePaths = documentos.map((d) => d.storage_path).filter(Boolean)
        if (storagePaths.length > 0) {
            await supabase.storage.from('documentos_processuais').remove(storagePaths)
        }

        // 3. Apagar registros dos documentos do banco
        await supabase
            .from('documentos_gestao_escritorio_filizola')
            .delete()
            .eq('processo_id', id)
    }

    // 4. Apagar o processo
    const { error } = await supabase
        .from('processos_gestao_escritorio_filizola')
        .delete()
        .eq('id', id)

    return { error }
}
