import { supabase } from '@/lib/supabase/client'
import type { Cliente } from '@/lib/types/database'

export async function buscarClientes(busca?: string) {
    let query = supabase
        .from('clientes_gestao_escritorio_filizola')
        .select('*')
        .order('criado_em', { ascending: false })

    if (busca) {
        query = query.or(`nome_completo.ilike.%${busca}%,cpf.ilike.%${busca}%,email.ilike.%${busca}%,telefone.ilike.%${busca}%`)
    }

    const { data, error } = await query
    return { clientes: data as Cliente[], error }
}

export async function buscarClientePorId(id: string) {
    const { data, error } = await supabase
        .from('clientes_gestao_escritorio_filizola')
        .select('*')
        .eq('id', id)
        .single()

    return { cliente: data as Cliente, error }
}

export async function criarCliente(cliente: {
    nome_completo: string
    cpf: string
    telefone?: string
    email?: string
    data_nascimento?: string
    endereco?: Record<string, unknown>
}) {
    const { data, error } = await supabase
        .from('clientes_gestao_escritorio_filizola')
        .insert(cliente)
        .select()
        .single()

    return { cliente: data, error }
}

export async function atualizarCliente(id: string, campos: Partial<Cliente>) {
    const { data, error } = await supabase
        .from('clientes_gestao_escritorio_filizola')
        .update({ ...campos, atualizado_em: new Date().toISOString() })
        .eq('id', id)
        .select()
        .single()

    return { cliente: data, error }
}

export async function deletarCliente(id: string) {
    // 1. Buscar processos do cliente
    const { data: processos, error: erroProcessos } = await supabase
        .from('processos_gestao_escritorio_filizola')
        .select('id')
        .eq('cliente_id', id)

    if (!erroProcessos && processos && processos.length > 0) {
        const processoIds = processos.map((p) => p.id)

        // 2. Buscar documentos de todos os processos
        const { data: documentos } = await supabase
            .from('documentos_gestao_escritorio_filizola')
            .select('id, storage_path')
            .in('processo_id', processoIds)

        if (documentos && documentos.length > 0) {
            // 3. Apagar arquivos do Supabase Storage
            const storagePaths = documentos.map((d) => d.storage_path).filter(Boolean)
            if (storagePaths.length > 0) {
                await supabase.storage.from('documentos_processuais').remove(storagePaths)
            }

            // 4. Apagar registros dos documentos do banco
            await supabase
                .from('documentos_gestao_escritorio_filizola')
                .delete()
                .in('processo_id', processoIds)
        }

        // 5. Apagar os processos do banco
        await supabase
            .from('processos_gestao_escritorio_filizola')
            .delete()
            .eq('cliente_id', id)
    }

    // 6. Apagar o cliente
    const { error } = await supabase
        .from('clientes_gestao_escritorio_filizola')
        .delete()
        .eq('id', id)

    return { error }
}
