"use client"

import { use, useState, useEffect, useCallback } from "react"
import Link from "next/link"
import DashboardLayout from "@/components/layout/dashboard-layout"
import { Badge } from "@/components/ui/badge"
import { FolderSection } from "@/components/folder-section"
import { agruparDocumentosPorPasta } from "@/lib/services/pastas-documentos"
import { buscarClientePorId } from "@/lib/services/clientes"
import { buscarProcessosPorCliente } from "@/lib/services/processos"
import { buscarDocumentosPorProcesso, getUrlDocumento } from "@/lib/services/documentos"
import { buscarPeticoesPorCliente, getUrlPeticaoGerada } from "@/lib/services/peticoes"
import type { Cliente, Processo, Documento, Agrupamento, PeticaoGerada } from "@/lib/types/database"
import { getTipoBeneficioLabel, getTipoDocumentoLabel } from "@/lib/types/database"
import { ArrowLeft, Loader2, Download, FileText, FileImage, Sparkles, Pencil, Check } from "lucide-react"

function isPreviewable(mimetype: string | null): boolean {
    if (!mimetype) return false
    return mimetype.startsWith('image/') || mimetype === 'application/pdf'
}

function DocumentoItem({
    doc,
    onOpenFile,
    onDownload,
}: {
    doc: Documento
    onOpenFile: () => void | Promise<void>
    onDownload: () => void | Promise<void>
}) {
    const podeVisualizar = isPreviewable(doc.mimetype)

    return (
        <div className="ml-8 rounded-xl border border-[#333333] bg-[#0A0A0A] p-4">
            <div className="mb-3 flex items-center justify-between gap-3">
                <div className="flex-1 min-w-0">
                    <p className="text-sm font-semibold text-white truncate">{getTipoDocumentoLabel(doc.tipo_documento)}</p>
                    <p className="text-xs text-[#A3A3A3] truncate">{doc.nome_arquivo_original || doc.storage_path}</p>
                </div>
                <Badge className="bg-[#1F1F1F] text-white border border-[#333333] shrink-0">
                    {doc.qualidade_documento}
                </Badge>
            </div>

            <div className="flex gap-2">
                {podeVisualizar && (
                    <button
                        type="button"
                        onClick={onOpenFile}
                        className="flex-1 flex items-center justify-center gap-2 rounded-lg border border-[#333333] bg-[#171717] px-4 py-3 text-sm text-white hover:border-[#FACC15]/30 cursor-pointer"
                    >
                        {doc.mimetype?.includes("pdf") ? <FileText className="h-4 w-4 text-[#FACC15]" /> : <FileImage className="h-4 w-4 text-[#FACC15]" />}
                        Abrir arquivo
                    </button>
                )}
                <button
                    type="button"
                    onClick={onDownload}
                    className="flex-1 flex items-center justify-center gap-2 rounded-lg border border-[#333333] bg-[#171717] px-4 py-3 text-sm text-white hover:border-[#FACC15]/30 cursor-pointer"
                >
                    <Download className="h-4 w-4 text-[#FACC15]" />
                    Baixar
                </button>
            </div>
        </div>
    )
}

function PeticaoItem({ peticao }: { peticao: PeticaoGerada }) {
    const [editando, setEditando] = useState(false)
    const [conteudo, setConteudo] = useState('')
    const [salvando, setSalvando] = useState(false)

    return (
        <div className="ml-8">
            <div
                key={peticao.id}
                className="rounded-xl border border-[#333333] bg-[#0A0A0A] p-4"
            >
                <div className="flex items-center justify-between gap-3 mb-3">
                    <div className="flex items-center gap-3 min-w-0">
                        <Sparkles className="h-4 w-4 text-[#FACC15] shrink-0" />
                        <div className="min-w-0">
                            <p className="text-sm font-semibold text-white truncate">
                                Petição - {getTipoBeneficioLabel(peticao.tipo_beneficio)}
                            </p>
                            <p className="text-[10px] text-[#A3A3A3]">
                                Gerada em {new Date(peticao.criado_em).toLocaleString("pt-BR")}
                            </p>
                        </div>
                    </div>
                    <span className={`h-2 w-2 rounded-full shrink-0 ${
                        peticao.status_geracao === 'concluido' ? 'bg-green-500'
                            : peticao.status_geracao === 'erro' ? 'bg-red-500' : 'bg-yellow-500'
                    }`} />
                </div>

                {editando ? (
                    <div className="space-y-3">
                        <textarea
                            value={conteudo}
                            onChange={(e) => setConteudo(e.target.value)}
                            className="w-full h-48 bg-[#171717] border border-[#333333] rounded-lg p-3 text-sm text-white font-mono resize-y focus:outline-none focus:border-[#FACC15]/50"
                        />
                        <div className="flex items-center gap-2 justify-end">
                            <button
                                onClick={() => { setEditando(false); setConteudo('') }}
                                className="px-3 py-1.5 rounded-lg bg-[#1F1F1F] border border-[#333333] text-[#A3A3A3] hover:text-white text-xs"
                            >
                                Cancelar
                            </button>
                            <button
                                onClick={async () => {
                                    if (!conteudo.trim()) return
                                    setSalvando(true)
                                    const { salvarPeticaoEditada } = await import('@/lib/services/peticoes')
                                    await salvarPeticaoEditada({
                                        peticaoId: peticao.id,
                                        conteudoEditado: conteudo.trim(),
                                        nomeCliente: 'cliente',
                                    })
                                    setEditando(false)
                                    setSalvando(false)
                                }}
                                disabled={salvando || !conteudo.trim()}
                                className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-[#FACC15] hover:bg-[#EAB308] disabled:opacity-50 text-black font-bold text-xs"
                            >
                                {salvando ? <Loader2 className="h-3 w-3 animate-spin" /> : <Check className="h-3 w-3" />}
                                Salvar
                            </button>
                        </div>
                    </div>
                ) : (
                    <div className="flex gap-2">
                        <button
                            onClick={() => { setEditando(true); setConteudo(peticao.conteudo_gerado || '') }}
                            className="flex-1 flex items-center justify-center gap-2 rounded-lg border border-[#333333] bg-[#171717] px-4 py-3 text-sm text-white hover:border-[#FACC15]/30 cursor-pointer"
                        >
                            <Pencil className="h-4 w-4 text-[#FACC15]" />
                            Editar petição
                        </button>
                        {peticao.storage_path && (
                            <button
                                onClick={async () => {
                                    const { url } = await getUrlPeticaoGerada(peticao.storage_path!)
                                    if (!url) return
                                    const response = await fetch(url)
                                    const blob = await response.blob()
                                    const blobUrl = URL.createObjectURL(blob)
                                    const link = document.createElement('a')
                                    link.href = blobUrl
                                    link.download = `peticao_${peticao.tipo_beneficio}.pdf`
                                    document.body.appendChild(link)
                                    link.click()
                                    document.body.removeChild(link)
                                    URL.revokeObjectURL(blobUrl)
                                }}
                                className="flex-1 flex items-center justify-center gap-2 rounded-lg border border-[#333333] bg-[#171717] px-4 py-3 text-sm text-white hover:border-[#FACC15]/30 cursor-pointer"
                            >
                                <Download className="h-4 w-4 text-[#FACC15]" />
                                Baixar PDF
                            </button>
                        )}
                    </div>
                )}
            </div>
        </div>
    )
}

export default function ClienteDocumentosPage({ params }: { params: Promise<{ id: string }> }) {
    const resolvedParams = use(params)
    const [cliente, setCliente] = useState<Cliente | null>(null)
    const [processos, setProcessos] = useState<Processo[]>([])
    const [documentos, setDocumentos] = useState<Documento[]>([])
    const [peticoes, setPeticoes] = useState<PeticaoGerada[]>([])
    const [loading, setLoading] = useState(true)

    const carregarDados = useCallback(async () => {
        try {
            const id = resolvedParams.id

            const { cliente: clienteData } = await buscarClientePorId(id)
            if (clienteData) setCliente(clienteData)

            const [processosRes, peticoesRes] = await Promise.all([
                buscarProcessosPorCliente(id),
                buscarPeticoesPorCliente(id),
            ])

            if (processosRes.processos) {
                setProcessos(processosRes.processos)

                const todosDocumentos: Documento[] = []
                for (const processo of processosRes.processos) {
                    const { documentos: docsData } = await buscarDocumentosPorProcesso(processo.id)
                    if (docsData) {
                        todosDocumentos.push(...docsData)
                    }
                }
                setDocumentos(todosDocumentos)
            }

            if (peticoesRes.peticoes) {
                setPeticoes(peticoesRes.peticoes)
            }
        } finally {
            setLoading(false)
        }
    }, [resolvedParams.id])

    useEffect(() => {
        void carregarDados()
    }, [carregarDados])

    async function handleOpenFile(doc: Documento) {
        const { url } = await getUrlDocumento(doc.storage_path)
        if (!url) return
        try {
            const response = await fetch(url)
            const blob = await response.blob()
            if (isPreviewable(doc.mimetype)) {
                const blobUrl = URL.createObjectURL(blob)
                window.open(blobUrl, "_blank", "noopener,noreferrer")
            } else {
                const blobUrl = URL.createObjectURL(blob)
                const link = document.createElement('a')
                link.href = blobUrl
                link.download = doc.nome_arquivo_original || doc.storage_path.split('/').pop() || 'documento'
                document.body.appendChild(link)
                link.click()
                document.body.removeChild(link)
                URL.revokeObjectURL(blobUrl)
            }
        } catch {
            // erro silencioso
        }
    }

    async function handleDownload(doc: Documento) {
        const { url } = await getUrlDocumento(doc.storage_path)
        if (!url) return
        try {
            const response = await fetch(url)
            const blob = await response.blob()
            const blobUrl = URL.createObjectURL(blob)
            const link = document.createElement('a')
            link.href = blobUrl
            link.download = doc.nome_arquivo_original || doc.storage_path.split('/').pop() || 'documento'
            document.body.appendChild(link)
            link.click()
            document.body.removeChild(link)
            URL.revokeObjectURL(blobUrl)
        } catch {
            // erro silencioso
        }
    }

    // Agrupar documentos por processo
    const processosComDocs = processos
        .map((processo) => {
            const docsDoProcesso = documentos.filter((d) => d.processo_id === processo.id)
            const peticoesDoProcesso = peticoes.filter((p) => p.processo_id === processo.id)
            if (docsDoProcesso.length === 0 && peticoesDoProcesso.length === 0) return null
            return {
                processo,
                documentos: docsDoProcesso,
                peticoes: peticoesDoProcesso,
                agrupamentos: agruparDocumentosPorPasta(docsDoProcesso),
            }
        })
        .filter((p): p is { processo: Processo; documentos: Documento[]; peticoes: PeticaoGerada[]; agrupamentos: Agrupamento[] } => p !== null)

    if (loading) {
        return (
            <DashboardLayout>
                <div className="flex items-center justify-center h-[60vh] w-full">
                    <div className="flex flex-col items-center gap-4">
                        <Loader2 className="h-10 w-10 text-[#FACC15] animate-spin" />
                        <p className="text-[#A3A3A3] text-lg font-medium">Carregando documentos...</p>
                    </div>
                </div>
            </DashboardLayout>
        )
    }

    const totalItens = documentos.length + peticoes.length

    return (
        <DashboardLayout>
            <div className="flex flex-col gap-8 px-12 py-10 w-full max-w-full">
                {/* Header */}
                <div className="flex flex-col gap-4">
                    <Link
                        href={`/clientes/${resolvedParams.id}`}
                        className="flex items-center gap-2 text-[#A3A3A3] hover:text-[#FACC15] transition-colors w-fit"
                    >
                        <ArrowLeft className="h-4 w-4" />
                        <span className="text-sm font-medium">Voltar para o cliente</span>
                    </Link>

                    <div className="flex items-center gap-4">
                        <div className="h-12 w-12 rounded-full bg-[#262626] flex items-center justify-center text-xl font-bold text-[#FACC15] border-2 border-[#FACC15]/30">
                            {cliente?.nome_completo?.split(" ").map((n) => n[0]).join("").slice(0, 2).toUpperCase() ?? "??"}
                        </div>
                        <div>
                            <h1 className="text-2xl font-black text-white">Documentos</h1>
                            <p className="text-[#A3A3A3]">{cliente?.nome_completo} - {totalItens} arquivo(s)</p>
                        </div>
                    </div>
                </div>

                {/* Documentos por Processo */}
                {totalItens === 0 ? (
                    <div className="rounded-xl border border-dashed border-[#333333] bg-[#0A0A0A] p-10 text-center">
                        <FileText className="mx-auto mb-3 h-8 w-8 text-[#525252]" />
                        <p className="text-sm text-[#A3A3A3]">Nenhum documento encontrado.</p>
                    </div>
                ) : (
                    <div className="space-y-8">
                        {processosComDocs.map(({ processo, agrupamentos, peticoes: peticoesDoProcesso }) => (
                            <div key={processo.id} className="rounded-xl border border-[#333333] bg-[#171717] overflow-hidden">
                                {/* Header do processo */}
                                <div className="p-5 border-b border-[#333333] flex items-center justify-between">
                                    <Link
                                        href={`/processo/${processo.id}`}
                                        className="flex items-center gap-3 hover:opacity-80 transition-opacity"
                                    >
                                        <span className="material-symbols-outlined text-[#FACC15]" style={{ fontSize: '20px' }}>folder</span>
                                        <div>
                                            <p className="text-sm font-bold text-white">{getTipoBeneficioLabel(processo.tipo_beneficio)}</p>
                                            <p className="text-xs text-[#A3A3A3]">{processo.numero_processo || processo.id}</p>
                                        </div>
                                    </Link>
                                    <div className="flex items-center gap-3">
                                        <span className="text-[10px] text-[#A3A3A3]">
                                            {agrupamentos.reduce((acc, g) => acc + g.documentos.length + g.subpastas.reduce((a, s) => a + s.documentos.length, 0), 0) + peticoesDoProcesso.length} item(s)
                                        </span>
                                        <Link
                                            href={`/processo/${processo.id}`}
                                            className="text-xs text-[#FACC15] hover:underline"
                                        >
                                            Ver processo
                                        </Link>
                                    </div>
                                </div>

                                {/* Pastas de documentos */}
                                <div className="p-5 space-y-1">
                                    {agrupamentos.map((grupo) => (
                                        <FolderSection
                                            key={grupo.pasta.id}
                                            nome={grupo.pasta.nome}
                                            badge={String(grupo.documentos.length + grupo.subpastas.reduce((acc, s) => acc + s.documentos.length, 0))}
                                            defaultOpen={true}
                                        >
                                            {grupo.documentos.map((doc) => (
                                                <DocumentoItem
                                                    key={doc.id}
                                                    doc={doc}
                                                    onOpenFile={() => handleOpenFile(doc)}
                                                    onDownload={() => handleDownload(doc)}
                                                />
                                            ))}
                                            {grupo.subpastas.map((sub) => (
                                                <FolderSection
                                                    key={sub.pasta.id}
                                                    nome={sub.pasta.nome}
                                                    subfolder
                                                    badge={String(sub.documentos.length)}
                                                    defaultOpen={true}
                                                >
                                                    {sub.documentos.map((doc) => (
                                                        <DocumentoItem
                                                            key={doc.id}
                                                            doc={doc}
                                                            onOpenFile={() => handleOpenFile(doc)}
                                                            onDownload={() => handleDownload(doc)}
                                                        />
                                                    ))}
                                                </FolderSection>
                                            ))}
                                        </FolderSection>
                                    ))}

                                    {/* Petições dentro da pasta do processo */}
                                    {peticoesDoProcesso.length > 0 && (
                                        <FolderSection
                                            nome="Petições geradas"
                                            badge={String(peticoesDoProcesso.length)}
                                            defaultOpen={true}
                                        >
                                            {peticoesDoProcesso.map((peticao) => (
                                                <PeticaoItem key={peticao.id} peticao={peticao} />
                                            ))}
                                        </FolderSection>
                                    )}
                                </div>
                            </div>
                        ))}
                    </div>
                )}
            </div>
        </DashboardLayout>
    )
}
