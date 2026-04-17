import { supabase } from '@/lib/supabase/client'

export interface ComentarioCliente {
    id: string
    cliente_id: string
    usuario_id: string
    conteudo: string
    criado_em: string
    atualizado_em: string
    autor_nome?: string
}

export async function buscarComentariosCliente(clienteId: string) {
    const { data, error } = await supabase
        .from('comentarios_clientes_gestao_escritorio_filizola')
        .select('*')
        .eq('cliente_id', clienteId)
        .order('criado_em', { ascending: true })

    return { comentarios: data as ComentarioCliente[], error }
}

export async function criarComentario(clienteId: string, conteudo: string, usuarioId: string) {
    const { data, error } = await supabase
        .from('comentarios_clientes_gestao_escritorio_filizola')
        .insert({
            cliente_id: clienteId,
            usuario_id: usuarioId,
            conteudo,
        })
        .select()
        .single()

    return { comentario: data as ComentarioCliente | null, error }
}

export async function deletarComentario(id: string) {
    const { error } = await supabase
        .from('comentarios_clientes_gestao_escritorio_filizola')
        .delete()
        .eq('id', id)

    return { error }
}

export async function buscarUsuarioAtual() {
    const { data: { user } } = await supabase.auth.getUser()
    return user
}

// --- Comentários por Processo (Chat da equipe) ---

export interface ComentarioProcesso {
    id: string
    processo_id: string
    usuario_id: string
    conteudo: string
    criado_em: string
    atualizado_em: string
}

export async function buscarComentariosProcesso(processoId: string) {
    const { data, error } = await supabase
        .from('comentarios_processos_gestao_escritorio_filizola')
        .select('*')
        .eq('processo_id', processoId)
        .order('criado_em', { ascending: true })

    return { comentarios: data as ComentarioProcesso[], error }
}

export async function criarComentarioProcesso(processoId: string, conteudo: string, usuarioId: string) {
    const { data, error } = await supabase
        .from('comentarios_processos_gestao_escritorio_filizola')
        .insert({
            processo_id: processoId,
            usuario_id: usuarioId,
            conteudo,
        })
        .select()
        .single()

    return { comentario: data as ComentarioProcesso | null, error }
}

export async function deletarComentarioProcesso(id: string) {
    const { error } = await supabase
        .from('comentarios_processos_gestao_escritorio_filizola')
        .delete()
        .eq('id', id)

    return { error }
}
