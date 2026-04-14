import { supabase } from '@/lib/supabase/client'
import type { HistoricoINSS, EventoInss } from '@/lib/types/database'

export async function buscarHistoricoInssPorProcesso(processoId: string) {
    const { data, error } = await supabase
        .from('historico_inss_gestao_escritorio_filizola')
        .select('*')
        .eq('processo_id', processoId)
        .order('data_evento_portal', { ascending: false, nullsFirst: false })
        .order('criado_em', { ascending: false })

    return { historico: data as HistoricoINSS[], error }
}

export async function criarEventoHistoricoInss(evento: {
    processo_id: string
    evento: EventoInss
    conteudo_texto?: string
    data_evento_portal?: string
    prazo_fatal?: string
    storage_print_path?: string
}) {
    const { data, error } = await supabase
        .from('historico_inss_gestao_escritorio_filizola')
        .insert(evento)
        .select()
        .single()

    return { evento: data as HistoricoINSS, error }
}
