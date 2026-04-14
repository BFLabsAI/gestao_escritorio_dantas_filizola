import { supabase } from '@/lib/supabase/client'
import type { Documento, TipoDocumento, CategoriaDocumento } from '@/lib/types/database'

export async function buscarDocumentosPorProcesso(processoId: string) {
    const { data, error } = await supabase
        .from('documentos_gestao_escritorio_filizola')
        .select('*')
        .eq('processo_id', processoId)
        .order('criado_em', { ascending: false })

    return { documentos: data as Documento[], error }
}

function sanitizeFilename(name: string): string {
    return name
        .normalize('NFD')
        .replace(/[\u0300-\u036f]/g, '')
        .replace(/[^a-zA-Z0-9._-]/g, '_')
}

export async function uploadDocumento(params: {
    processoId: string
    clienteId: string
    tipo_documento: TipoDocumento
    categoria_documento: CategoriaDocumento
    arquivo: File
}) {
    const timestamp = Date.now()
    const safeName = sanitizeFilename(params.arquivo.name)
    const storagePath = `clientes/${params.clienteId}/processos/${params.processoId}/originais/${timestamp}_${safeName}`

    const { error: uploadError } = await supabase.storage
        .from('documentos_processuais')
        .upload(storagePath, params.arquivo, {
            cacheControl: '3600',
            upsert: false,
        })

    if (uploadError) return { documento: null, error: uploadError }

    const { data: documento, error } = await supabase
        .from('documentos_gestao_escritorio_filizola')
        .insert({
            processo_id: params.processoId,
            tipo_documento: params.tipo_documento,
            categoria_documento: params.categoria_documento,
            storage_path: storagePath,
            nome_arquivo_original: params.arquivo.name,
            tamanho_bytes: params.arquivo.size,
            mimetype: params.arquivo.type,
        })
        .select()
        .single()

    return { documento: documento as Documento, error }
}

export async function analisarDocumentos(processoId: string) {
    const { data, error } = await supabase.functions.invoke('analisar-documentos', {
        body: { processo_id: processoId },
    })

    if (error) {
        return { resultado: null, error }
    }

    return { resultado: data, error: null }
}

export async function deletarDocumento(documentoId: string, storagePath: string) {
    const { error: storageError } = await supabase.storage
        .from('documentos_processuais')
        .remove([storagePath])

    if (storageError) return { error: storageError }

    const { error } = await supabase
        .from('documentos_gestao_escritorio_filizola')
        .delete()
        .eq('id', documentoId)

    return { error }
}

export async function getUrlDocumento(storagePath: string, expiresIn = 60 * 30) {
    const { data, error } = await supabase.storage
        .from('documentos_processuais')
        .createSignedUrl(storagePath, expiresIn)

    return { url: data?.signedUrl ?? null, error }
}

// Gera signed URLs para múltiplos documentos em paralelo
export async function getBatchSignedUrls(storagePaths: string[]): Promise<Map<string, string>> {
    const mapa = new Map<string, string>()
    if (storagePaths.length === 0) return mapa

    await Promise.all(
        storagePaths.map(async (path) => {
            const { url } = await getUrlDocumento(path)
            if (url) mapa.set(path, url)
        })
    )

    return mapa
}
