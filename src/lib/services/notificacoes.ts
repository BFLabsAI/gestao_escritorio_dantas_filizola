import { supabase } from '@/lib/supabase/client'
import type { Notificacao } from '@/lib/types/database'

export async function buscarNotificacoes(params?: {
    processoId?: string
    statusEnvio?: string
    limite?: number
}) {
    let query = supabase
        .from('notificacoes_gestao_escritorio_filizola')
        .select('*')
        .order('criado_em', { ascending: false })

    if (params?.processoId) {
        query = query.eq('processo_id', params.processoId)
    }

    if (params?.statusEnvio) {
        query = query.eq('status_envio', params.statusEnvio)
    }

    if (params?.limite) {
        query = query.limit(params.limite)
    }

    const { data, error } = await query
    return { notificacoes: data as Notificacao[], error }
}
