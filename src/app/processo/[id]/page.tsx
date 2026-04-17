"use client"

import Image from "next/image"
import { use, useCallback, useEffect, useMemo, useRef, useState } from "react"
import Link from "next/link"
import DashboardLayout from "@/components/layout/dashboard-layout"
import { Button } from "@/components/ui/button"
import { Badge } from "@/components/ui/badge"
import { buscarProcessoPorId } from "@/lib/services/processos"
import {
    analisarDocumentos,
    buscarDocumentosPorProcesso,
    deletarDocumento,
    getUrlDocumento,
    getBatchSignedUrls,
    uploadDocumento,
} from "@/lib/services/documentos"
import { moverProcessoFase } from "@/lib/services/processos"
import {
    buscarModeloPorBeneficio,
    gerarPeticao,
    buscarPeticoesPorProcesso,
    getUrlPeticaoGerada,
    salvarPeticaoEditada,
} from "@/lib/services/peticoes"
import {
    buscarDadosExtraidosPorProcesso,
    atualizarDadoExtraido,
} from "@/lib/services/dados-extraidos"
import { supabase } from "@/lib/supabase/client"
import type { Documento, ExigenciaDoc, Processo, ModeloPeticao, PeticaoGerada, DadoExtraido, FaseKanban } from "@/lib/types/database"
import {
    FASE_KANBAN_LABELS,
    FASE_KANBAN_COLORS,
    getTipoBeneficioLabel,
    getTipoDocumentoLabel,
    CAMPO_LABELS,
} from "@/lib/types/database"
import {
    ArrowLeft,
    CheckCircle2,
    FileImage,
    FileText,
    Loader2,
    Trash2,
    TriangleAlert,
    UploadCloud,
    Sparkles,
    Download,
    AlertCircle,
    Pencil,
    Check,
    X,
    Database,
    ChevronDown,
    ChevronUp,
} from "lucide-react"
import ComentariosProcesso from "@/components/comentarios-processo"

type DocumentoComPreview = Documento & {
    previewUrl?: string | null
}

type ChecklistItem = {
    documento: string
    obrigatorio: boolean
    ordem: number
    status: "ENTREGUE" | "FALTANDO" | "ILEGIVEL"
}

// Mapeamento: tipo de documento exigido -> campos extraídos que satisfazem a exigência
const CAMPO_SATISFAZ_EXIGENCIA: Record<string, string[]> = {
    CPF: ["cpf"],
}

function CollapsibleSection({
    title,
    icon,
    defaultOpen = true,
    children,
    badge,
    headerRight,
}: {
    title: string
    icon?: React.ReactNode
    defaultOpen?: boolean
    children: React.ReactNode
    badge?: string
    headerRight?: React.ReactNode
}) {
    const [isOpen, setIsOpen] = useState(defaultOpen)

    return (
        <div className="rounded-xl border border-[#333333] bg-[#171717] overflow-hidden">
            <button
                onClick={() => setIsOpen(!isOpen)}
                className="w-full flex items-center justify-between p-5 hover:bg-[#1F1F1F]/50 transition-colors"
            >
                <div className="flex items-center gap-3">
                    {icon}
                    <h2 className="text-sm font-bold uppercase tracking-wider text-[#A3A3A3]">
                        {title}
                    </h2>
                    {badge && (
                        <span className="text-xs text-[#A3A3A3]">{badge}</span>
                    )}
                </div>
                <div className="flex items-center gap-2">
                    {headerRight}
                    {isOpen ? (
                        <ChevronUp className="h-4 w-4 text-[#A3A3A3]" />
                    ) : (
                        <ChevronDown className="h-4 w-4 text-[#A3A3A3]" />
                    )}
                </div>
            </button>
            {isOpen && (
                <div className="px-5 pb-5 border-t border-[#333333]">
                    {children}
                </div>
            )}
        </div>
    )
}

function getChecklistFromData(
    exigencias: ExigenciaDoc[],
    documentos: Documento[],
    dadosExtraidos: DadoExtraido[],
): ChecklistItem[] {
    const entregues = new Set(
        documentos
            .filter((item) => item.qualidade_documento === "LEGIVEL")
            .map((item) => item.tipo_documento)
    )

    const ilegiveis = new Set(
        documentos
            .filter((item) => item.qualidade_documento === "ILEGIVEL")
            .map((item) => item.tipo_documento)
    )

    const camposExtraidos = new Set(
        dadosExtraidos
            .filter((d) => d.valor && d.valor !== "null")
            .map((d) => d.campo),
    )

    return exigencias
        .map((item) => {
            let status: ChecklistItem["status"] = "FALTANDO"

            if (entregues.has(item.tipo_documento)) {
                status = "ENTREGUE"
            } else if (ilegiveis.has(item.tipo_documento)) {
                status = "ILEGIVEL"
            } else {
                // Verificar se os dados foram extraídos de outro documento
                const camposNecessarios = CAMPO_SATISFAZ_EXIGENCIA[item.tipo_documento]
                if (camposNecessarios && camposNecessarios.every((campo) => camposExtraidos.has(campo))) {
                    status = "ENTREGUE"
                }
            }

            return {
                documento: item.tipo_documento,
                obrigatorio: item.obrigatorio,
                ordem: item.ordem_exibicao,
                status,
            }
        })
        .sort((a, b) => a.ordem - b.ordem)
}

export default function ProcessoAuditPage({ params }: { params: Promise<{ id: string }> }) {
    const resolvedParams = use(params)
    const [processo, setProcesso] = useState<Processo | null>(null)
    const [documentos, setDocumentos] = useState<DocumentoComPreview[]>([])
    const [exigencias, setExigencias] = useState<ExigenciaDoc[]>([])
    const [checklist, setChecklist] = useState<ChecklistItem[]>([])
    const [loading, setLoading] = useState(true)
    const [uploading, setUploading] = useState(false)
    const [analisando, setAnalisando] = useState(false)
    const [erro, setErro] = useState("")
    const [modeloPeticao, setModeloPeticao] = useState<ModeloPeticao | null>(null)
    const [peticoesGeradas, setPeticoesGeradas] = useState<PeticaoGerada[]>([])
    const [gerandoPeticao, setGerandoPeticao] = useState(false)
    const [dadosExtraidos, setDadosExtraidos] = useState<DadoExtraido[]>([])
    const [editandoDado, setEditandoDado] = useState<string | null>(null)
    const [valorEditado, setValorEditado] = useState("")
    const [salvandoDado, setSalvandoDado] = useState(false)
    const fileInputRef = useRef<HTMLInputElement>(null)
    const [editandoPeticao, setEditandoPeticao] = useState<string | null>(null)
    const [conteudoPeticaoEditada, setConteudoPeticaoEditada] = useState('')
    const [salvandoPeticao, setSalvandoPeticao] = useState(false)
    const [mudandoFase, setMudandoFase] = useState(false)

    const carregarProcesso = useCallback(async () => {
        setLoading(true)
        setErro("")

        try {
            // Fase 1: Buscar processo
            const { processo: processoData, error: processoError } = await buscarProcessoPorId(resolvedParams.id)

            if (processoError || !processoData) {
                setErro("Processo não encontrado.")
                return
            }

            setProcesso(processoData)

            // Fase 2: Todas as chamadas independentes em paralelo (1 round-trip)
            const [
                { documentos: documentosData },
                exigenciasResponse,
                { modelo: modeloData },
                { peticoes: peticoesData },
                { dados: dadosData },
            ] = await Promise.all([
                buscarDocumentosPorProcesso(resolvedParams.id),
                supabase
                    .from("exigencias_doc_gestao_escritorio_filizola")
                    .select("*")
                    .eq("tipo_beneficio", processoData.tipo_beneficio)
                    .eq("ativo", true)
                    .order("ordem_exibicao", { ascending: true }),
                buscarModeloPorBeneficio(processoData.tipo_beneficio),
                buscarPeticoesPorProcesso(resolvedParams.id),
                buscarDadosExtraidosPorProcesso(resolvedParams.id),
            ])

            const exigenciasData = (exigenciasResponse.data ?? []) as ExigenciaDoc[]
            const documentosBase = (documentosData ?? []) as Documento[]

            // Fase 3: Batch de signed URLs (1 chamada paralela para todas as imagens)
            const imagePaths = documentosBase
                .filter((d) => d.mimetype?.startsWith("image/"))
                .map((d) => d.storage_path)

            const urlMap = imagePaths.length > 0 ? await getBatchSignedUrls(imagePaths) : new Map<string, string>()

            const documentosComPreview: DocumentoComPreview[] = documentosBase.map((doc) => ({
                ...doc,
                previewUrl: doc.mimetype?.startsWith("image/") ? (urlMap.get(doc.storage_path) ?? null) : null,
            }))

            setDocumentos(documentosComPreview)
            setExigencias(exigenciasData)
            setChecklist(getChecklistFromData(exigenciasData, documentosBase, dadosData ?? []))
            setModeloPeticao(modeloData)
            setPeticoesGeradas(peticoesData ?? [])
            setDadosExtraidos(dadosData ?? [])
        } finally {
            setLoading(false)
        }
    }, [resolvedParams.id])

    useEffect(() => {
        void carregarProcesso()
    }, [carregarProcesso])

    const faltantesObrigatorios = useMemo(
        () => checklist.filter((item) => item.obrigatorio && item.status !== "ENTREGUE"),
        [checklist]
    )

    // Agrupar dados extraídos por campo (último valor de cada campo)
    const dadosAgrupados = useMemo(() => {
        const mapa: Record<string, DadoExtraido> = {}
        for (const dado of dadosExtraidos) {
            // Se já existe, manter o que tem maior confiança ou que foi corrigido
            const existente = mapa[dado.campo]
            if (!existente ||
                dado.status === 'corrigido' ||
                (dado.confianca !== null && (existente.confianca === null || dado.confianca > existente.confianca))) {
                mapa[dado.campo] = dado
            }
        }
        return Object.values(mapa).sort((a, b) => a.campo.localeCompare(b.campo))
    }, [dadosExtraidos])

    async function executarAnalise() {
        if (!processo) return

        setAnalisando(true)
        setErro("")

        try {
            const { resultado, error } = await analisarDocumentos(processo.id)

            if (error) {
                setErro(`Erro na análise IA: ${error.message}`)
                return
            }

            if (resultado?.error) {
                setErro(`Erro na análise IA: ${resultado.error}`)
                return
            }

            if (resultado?.checklist) {
                setChecklist(resultado.checklist as ChecklistItem[])
            }

            await carregarProcesso()
        } finally {
            setAnalisando(false)
        }
    }

    async function handleUploadClick() {
        if (!processo?.cliente_id || uploading) return
        fileInputRef.current?.click()
    }

    async function handleFileChange(e: React.ChangeEvent<HTMLInputElement>) {
        const files = e.target.files
        if (!files || files.length === 0) return

        setUploading(true)
        setErro("")

        for (const file of Array.from(files)) {
            const { error } = await uploadDocumento({
                processoId: processo!.id,
                clienteId: processo!.cliente_id,
                tipo_documento: "OUTRO",
                categoria_documento: "OUTROS",
                arquivo: file,
            })

            if (error) {
                setErro(`Erro ao enviar "${file.name}": ${error.message}`)
                setUploading(false)
                e.target.value = ''
                return
            }
        }

        e.target.value = ''
        await carregarProcesso()
        await executarAnalise()
        setUploading(false)
    }

    async function handleDeleteDocumento(docId: string, storagePath: string) {
        if (!processo) return
        if (!confirm('Tem certeza que deseja excluir este documento?')) return

        setErro("")
        const { error } = await deletarDocumento(docId, storagePath)

        if (error) {
            setErro(`Erro ao excluir documento: ${error.message}`)
            return
        }

        if (processo.fase_kanban === 'APROVACAO_GESTOR') {
            await moverProcessoFase(processo.id, 'DOC_PENDENTE')
        }

        await carregarProcesso()
    }

    async function handleMudarFase(novaFase: FaseKanban) {
        if (!processo || processo.fase_kanban === novaFase) return

        setMudandoFase(true)
        setErro("")

        const { error } = await moverProcessoFase(processo.id, novaFase)

        if (error) {
            setErro(`Erro ao mover fase: ${error.message}`)
        } else {
            await carregarProcesso()
        }

        setMudandoFase(false)
    }

    async function handleGerarPeticao() {
        if (!processo) return

        setGerandoPeticao(true)
        setErro("")

        const { peticao, error } = await gerarPeticao({
            processoId: processo.id,
            clienteId: processo.cliente_id,
        })

        if (error) {
            setErro(`Erro ao gerar petição: ${error.message}`)
        } else {
            await carregarProcesso()
        }

        setGerandoPeticao(false)
    }

    async function handleDownloadPeticao(storagePath: string) {
        const { url, error } = await getUrlPeticaoGerada(storagePath)
        if (error || !url) {
            setErro('Erro ao gerar link de download.')
            return
        }

        try {
            const response = await fetch(url)
            const blob = await response.blob()
            const blobUrl = URL.createObjectURL(blob)
            const link = document.createElement('a')
            link.href = blobUrl
            link.download = 'peticao.pdf'
            document.body.appendChild(link)
            link.click()
            document.body.removeChild(link)
            URL.revokeObjectURL(blobUrl)
        } catch {
            setErro('Erro ao baixar petição.')
        }
    }

    async function handleSalvarPeticaoEditada(peticaoId: string) {
        if (!processo?.cliente || !conteudoPeticaoEditada.trim()) return

        setSalvandoPeticao(true)
        setErro("")

        const cliente = processo.cliente as { nome_completo?: string }
        const { error } = await salvarPeticaoEditada({
            peticaoId,
            conteudoEditado: conteudoPeticaoEditada.trim(),
            nomeCliente: cliente?.nome_completo || 'cliente',
        })

        if (error) {
            setErro(`Erro ao salvar petição: ${error.message}`)
        } else {
            setEditandoPeticao(null)
            setConteudoPeticaoEditada('')
            await carregarProcesso()
        }

        setSalvandoPeticao(false)
    }

    function handleIniciarEdicao(dado: DadoExtraido) {
        setEditandoDado(dado.id)
        setValorEditado(dado.valor)
    }

    function handleCancelarEdicao() {
        setEditandoDado(null)
        setValorEditado("")
    }

    async function handleSalvarEdicao(dadoId: string) {
        setSalvandoDado(true)
        setErro("")

        const { error } = await atualizarDadoExtraido(dadoId, valorEditado)

        if (error) {
            setErro(`Erro ao salvar: ${error.message}`)
        } else {
            setEditandoDado(null)
            setValorEditado("")
            await carregarProcesso()
        }

        setSalvandoDado(false)
    }

    if (loading) {
        return (
            <DashboardLayout>
                <div className="flex h-[70vh] items-center justify-center">
                    <Loader2 className="h-8 w-8 animate-spin text-[#FACC15]" />
                </div>
            </DashboardLayout>
        )
    }

    if (!processo) {
        return (
            <DashboardLayout>
                <div className="px-12 py-10 text-red-400">{erro || "Processo não encontrado."}</div>
            </DashboardLayout>
        )
    }

    return (
        <DashboardLayout>
            <div className="flex flex-col gap-8 px-12 py-10 w-full max-w-7xl">
                <div className="flex flex-col gap-4">
                    <Link
                        href="/board"
                        className="flex items-center gap-2 text-[#A3A3A3] hover:text-[#FACC15] transition-colors w-fit"
                    >
                        <ArrowLeft className="h-4 w-4" />
                        <span className="text-sm font-medium">Voltar para Processos</span>
                    </Link>

                    <div className="flex flex-col lg:flex-row lg:items-start justify-between gap-6">
                        <div className="space-y-3">
                            <div className="flex items-center gap-3 flex-wrap">
                                <h1 className="text-3xl font-black text-white">
                                    {processo.cliente?.nome_completo || "Cliente não informado"}
                                </h1>
                                <Badge className="bg-[#FACC15]/10 text-[#FACC15] border border-[#FACC15]/20">
                                    {getTipoBeneficioLabel(processo.tipo_beneficio)}
                                </Badge>
                                <select
                                    value={processo.fase_kanban}
                                    onChange={(e) => handleMudarFase(e.target.value as FaseKanban)}
                                    disabled={mudandoFase}
                                    className={`px-3 py-1 rounded text-xs font-bold border cursor-pointer focus:outline-none focus:ring-1 focus:ring-[#FACC15]/50 disabled:opacity-50 ${FASE_KANBAN_COLORS[processo.fase_kanban] ?? 'bg-[#1F1F1F] text-white border-[#333333]'}`}
                                >
                                    {Object.entries(FASE_KANBAN_LABELS).map(([fase, label]) => (
                                        <option key={fase} value={fase} className="bg-[#0A0A0A] text-white">
                                            {label}
                                        </option>
                                    ))}
                                </select>
                            </div>
                            <div className="text-sm text-[#A3A3A3] space-y-1">
                                <p>CPF: {processo.cliente?.cpf || "—"}</p>
                                <p>Processo: {processo.numero_processo || processo.id}</p>
                                <p>Dias na fase: {processo.dias_na_fase}</p>
                            </div>
                        </div>

                        <div className="flex flex-wrap gap-3">
                            <button
                                type="button"
                                onClick={handleUploadClick}
                                className="inline-flex cursor-pointer items-center gap-2 rounded-lg bg-[#FACC15] px-4 py-2 text-sm font-bold text-black hover:bg-[#EAB308]"
                            >
                                {uploading ? <Loader2 className="h-4 w-4 animate-spin" /> : <UploadCloud className="h-4 w-4" />}
                                Enviar documentos
                            </button>
                            <input
                                ref={fileInputRef}
                                type="file"
                                multiple
                                accept="image/*,.pdf,.doc,.docx,.txt"
                                onChange={handleFileChange}
                                className="hidden"
                            />
                            <Button
                                type="button"
                                onClick={executarAnalise}
                                disabled={analisando || documentos.length === 0}
                                className="bg-[#1F1F1F] text-white border border-[#333333] hover:bg-[#262626]"
                            >
                                {analisando ? <Loader2 className="h-4 w-4 animate-spin" /> : <CheckCircle2 className="h-4 w-4" />}
                                Rodar análise IA
                            </Button>
                            <Button
                                type="button"
                                onClick={handleGerarPeticao}
                                disabled={gerandoPeticao || !modeloPeticao}
                                className="bg-[#FACC15]/10 text-[#FACC15] border border-[#FACC15]/30 hover:bg-[#FACC15]/20"
                            >
                                {gerandoPeticao ? <Loader2 className="h-4 w-4 animate-spin" /> : <Sparkles className="h-4 w-4" />}
                                Rodar Petição
                            </Button>
                        </div>
                    </div>
                </div>

                {erro && (
                    <div className="rounded-lg border border-red-500/20 bg-red-500/10 px-4 py-3 text-sm text-red-400">
                        {erro}
                    </div>
                )}

                <div className="grid gap-6 xl:grid-cols-[1.1fr_0.9fr]">
                    <div className="space-y-6">
                        {/* Checklist de Conformidade */}
                        <CollapsibleSection
                            title="Checklist de conformidade"
                            icon={<CheckCircle2 className="h-4 w-4 text-[#FACC15]" />}
                            badge={faltantesObrigatorios.length === 0 ? "Sem pendencias obrigatorias" : `${faltantesObrigatorios.length} pendencia(s) obrigatoria(s)`}
                            defaultOpen={true}
                        >
                            <div className="pt-4 space-y-3">
                                {checklist.length === 0 ? (
                                    <p className="text-sm text-[#A3A3A3]">Nenhuma exigência configurada para este benefício.</p>
                                ) : (
                                    checklist.map((item) => (
                                        <div
                                            key={`${item.documento}-${item.ordem}`}
                                            className="flex items-center justify-between rounded-lg border border-[#333333] bg-[#0A0A0A] px-4 py-3"
                                        >
                                            <div className="flex items-center gap-3">
                                                {item.status === "ENTREGUE" ? (
                                                    <CheckCircle2 className="h-4 w-4 text-green-400" />
                                                ) : (
                                                    <TriangleAlert className={`h-4 w-4 ${item.status === "ILEGIVEL" ? "text-yellow-400" : "text-red-400"}`} />
                                                )}
                                                <div>
                                                    <p className="text-sm text-white">{getTipoDocumentoLabel(item.documento)}</p>
                                                    {!item.obrigatorio && (
                                                        <p className="text-xs text-[#A3A3A3]">Opcional</p>
                                                    )}
                                                </div>
                                            </div>
                                            <Badge
                                                className={
                                                    item.status === "ENTREGUE"
                                                        ? "bg-green-500/10 text-green-400 border border-green-500/20"
                                                        : item.status === "ILEGIVEL"
                                                          ? "bg-yellow-500/10 text-yellow-400 border border-yellow-500/20"
                                                          : "bg-red-500/10 text-red-400 border border-red-500/20"
                                                }
                                            >
                                                {item.status}
                                            </Badge>
                                        </div>
                                    ))
                                )}
                            </div>
                        </CollapsibleSection>

                        {/* Metadados da Configuração */}
                        <CollapsibleSection
                            title="Metadados da configuração"
                            defaultOpen={false}
                        >
                            <div className="pt-4 grid gap-3 md:grid-cols-2">
                                {exigencias.map((item) => (
                                    <div key={item.id} className="rounded-lg border border-[#333333] bg-[#0A0A0A] p-4">
                                        <p className="text-sm font-semibold text-white">{getTipoDocumentoLabel(item.tipo_documento)}</p>
                                        <p className="mt-1 text-xs text-[#A3A3A3]">{item.descricao || "Sem descrição adicional."}</p>
                                    </div>
                                ))}
                            </div>
                        </CollapsibleSection>

                        {/* Dados Extraídos pela IA */}
                        <CollapsibleSection
                            title="Dados Extraídos pela IA"
                            icon={<div className="h-6 w-6 rounded bg-cyan-500/10 flex items-center justify-center"><Database className="text-cyan-400 h-3.5 w-3.5" /></div>}
                            badge={`${dadosAgrupados.length} campo(s)`}
                            defaultOpen={true}
                        >
                            {dadosAgrupados.length === 0 ? (
                                <div className="pt-4 rounded-lg border border-dashed border-[#333333] bg-[#0A0A0A] p-6 text-center">
                                    <Database className="mx-auto mb-2 h-6 w-6 text-[#525252]" />
                                    <p className="text-sm text-[#525252]">
                                        Nenhum dado extraído ainda.
                                    </p>
                                    <p className="text-xs text-[#525252] mt-1">
                                        Envie documentos e rode a análise IA para extrair dados automaticamente.
                                    </p>
                                </div>
                            ) : (
                                <div className="pt-4 space-y-2">
                                    {dadosAgrupados.map((dado) => (
                                        <div
                                            key={dado.id}
                                            className="flex items-center justify-between rounded-lg border border-[#333333] bg-[#0A0A0A] px-4 py-3 group"
                                        >
                                            <div className="flex items-center gap-3 min-w-0 flex-1">
                                                <span className={`h-2 w-2 rounded-full shrink-0 ${
                                                    dado.status === 'corrigido'
                                                        ? 'bg-yellow-400'
                                                        : dado.status === 'confirmado'
                                                          ? 'bg-green-400'
                                                          : dado.confianca !== null && dado.confianca >= 0.7
                                                            ? 'bg-blue-400'
                                                            : 'bg-orange-400'
                                                }`} />
                                                <div className="min-w-0 flex-1">
                                                    <p className="text-xs text-[#525252]">
                                                        {CAMPO_LABELS[dado.campo] || dado.campo}
                                                        <span className="ml-2 text-[10px] text-[#333333]">
                                                            ({getTipoDocumentoLabel(dado.tipo_documento_origem)})
                                                        </span>
                                                    </p>
                                                    {editandoDado === dado.id ? (
                                                        <div className="flex items-center gap-2 mt-1">
                                                            <input
                                                                type="text"
                                                                value={valorEditado}
                                                                onChange={(e) => setValorEditado(e.target.value)}
                                                                onKeyDown={(e) => {
                                                                    if (e.key === 'Enter') handleSalvarEdicao(dado.id)
                                                                    if (e.key === 'Escape') handleCancelarEdicao()
                                                                }}
                                                                className="flex-1 bg-[#171717] border border-[#FACC15]/30 rounded px-2 py-1 text-sm text-white focus:outline-none"
                                                                autoFocus
                                                            />
                                                            <button
                                                                onClick={() => handleSalvarEdicao(dado.id)}
                                                                disabled={salvandoDado}
                                                                className="p-1 rounded bg-green-500/10 text-green-400 hover:bg-green-500/20"
                                                            >
                                                                {salvandoDado ? <Loader2 className="h-3 w-3 animate-spin" /> : <Check className="h-3 w-3" />}
                                                            </button>
                                                            <button
                                                                onClick={handleCancelarEdicao}
                                                                className="p-1 rounded bg-[#333333] text-[#A3A3A3] hover:text-white"
                                                            >
                                                                <X className="h-3 w-3" />
                                                            </button>
                                                        </div>
                                                    ) : (
                                                        <p className="text-sm text-white truncate">{dado.valor}</p>
                                                    )}
                                                </div>
                                            </div>
                                            {editandoDado !== dado.id && (
                                                <div className="flex items-center gap-2 shrink-0 ml-3">
                                                    {dado.confianca !== null && (
                                                        <span className={`text-[10px] font-mono ${
                                                            dado.confianca >= 0.7 ? 'text-green-400' : 'text-orange-400'
                                                        }`}>
                                                            {(dado.confianca * 100).toFixed(0)}%
                                                        </span>
                                                    )}
                                                    {dado.status === 'corrigido' && (
                                                        <span className="text-[10px] text-yellow-400">Corrigido</span>
                                                    )}
                                                    <button
                                                        onClick={() => handleIniciarEdicao(dado)}
                                                        className="opacity-0 group-hover:opacity-100 transition-opacity p-1 rounded bg-[#1F1F1F] text-[#A3A3A3] hover:text-white"
                                                        title="Editar"
                                                    >
                                                        <Pencil className="h-3 w-3" />
                                                    </button>
                                                </div>
                                            )}
                                        </div>
                                    ))}
                                </div>
                            )}
                        </CollapsibleSection>
                    </div>

                    {/* Documentos Enviados */}
                    <CollapsibleSection
                        title="Documentos enviados"
                        badge={`${documentos.length} arquivo(s)`}
                        defaultOpen={true}
                    >
                        <div className="pt-4 space-y-4">
                            {documentos.length === 0 ? (
                                <div className="rounded-xl border border-dashed border-[#333333] bg-[#0A0A0A] p-10 text-center">
                                    <UploadCloud className="mx-auto mb-3 h-8 w-8 text-[#FACC15]" />
                                    <p className="text-sm text-[#A3A3A3]">Nenhum documento enviado ainda.</p>
                                </div>
                            ) : (
                                documentos.map((doc) => (
                                    <div key={doc.id} className="rounded-xl border border-[#333333] bg-[#0A0A0A] p-4">
                                        <div className="mb-3 flex items-center justify-between gap-3">
                                            <div className="flex-1 min-w-0">
                                                <p className="text-sm font-semibold text-white truncate">{getTipoDocumentoLabel(doc.tipo_documento)}</p>
                                                <p className="text-xs text-[#A3A3A3] truncate">{doc.nome_arquivo_original || doc.storage_path}</p>
                                            </div>
                                            <div className="flex items-center gap-2 shrink-0">
                                                <Badge className="bg-[#1F1F1F] text-white border border-[#333333]">
                                                    {doc.qualidade_documento}
                                                </Badge>
                                                <button
                                                    type="button"
                                                    onClick={() => handleDeleteDocumento(doc.id, doc.storage_path)}
                                                    className="h-7 w-7 rounded flex items-center justify-center bg-red-500/10 border border-red-500/20 text-red-400 hover:bg-red-500/20 transition-colors"
                                                    title="Excluir documento"
                                                >
                                                    <Trash2 className="h-3.5 w-3.5" />
                                                </button>
                                            </div>
                                        </div>

                                        {doc.previewUrl ? (
                                            <div className="block overflow-hidden rounded-lg border border-[#333333]">
                                                <Image
                                                    src={doc.previewUrl}
                                                    alt={doc.nome_arquivo_original || doc.tipo_documento}
                                                    width={1200}
                                                    height={900}
                                                    className="max-h-72 w-full object-cover"
                                                />
                                            </div>
                                        ) : (
                                            <button
                                                type="button"
                                                onClick={async () => {
                                                    const { url } = await getUrlDocumento(doc.storage_path)
                                                    if (!url) return
                                                    try {
                                                        const response = await fetch(url)
                                                        const blob = await response.blob()
                                                        const blobUrl = URL.createObjectURL(blob)
                                                        window.open(blobUrl, "_blank", "noopener,noreferrer")
                                                    } catch {
                                                        setErro('Erro ao abrir documento.')
                                                    }
                                                }}
                                                className="flex items-center gap-3 rounded-lg border border-[#333333] bg-[#171717] px-4 py-3 text-sm text-white hover:border-[#FACC15]/30 w-full text-left cursor-pointer"
                                            >
                                                {doc.mimetype?.includes("pdf") ? <FileText className="h-4 w-4 text-[#FACC15]" /> : <FileImage className="h-4 w-4 text-[#FACC15]" />}
                                                Abrir arquivo
                                            </button>
                                        )}
                                    </div>
                                ))
                            )}
                        </div>
                    </CollapsibleSection>

                    {/* Chat */}
                    <CollapsibleSection
                        title="Chat"
                        icon={<span className="material-symbols-outlined text-[#FACC15] text-sm">chat</span>}
                        defaultOpen={true}
                    >
                        <div className="pt-4">
                            <ComentariosProcesso processoId={resolvedParams.id} />
                        </div>
                    </CollapsibleSection>
                </div>

                {/* Seção de Petições */}
                <div className="rounded-xl border border-[#333333] bg-[#171717] p-6">
                    <div className="flex items-center justify-between mb-4">
                        <div className="flex items-center gap-3">
                            <div className="h-8 w-8 rounded-lg bg-[#FACC15]/10 flex items-center justify-center">
                                <Sparkles className="text-[#FACC15] h-4 w-4" />
                            </div>
                            <h2 className="text-sm font-bold uppercase tracking-wider text-[#A3A3A3]">
                                Petições
                            </h2>
                        </div>
                        {modeloPeticao && (
                            <button
                                onClick={handleGerarPeticao}
                                disabled={gerandoPeticao}
                                className="flex items-center gap-2 px-4 py-2 rounded-lg bg-[#FACC15] hover:bg-[#EAB308] disabled:opacity-50 transition-colors text-black font-bold text-sm"
                            >
                                {gerandoPeticao ? (
                                    <Loader2 className="h-4 w-4 animate-spin" />
                                ) : (
                                    <Sparkles className="h-4 w-4" />
                                )}
                                Gerar Petição (PDF)
                            </button>
                        )}
                    </div>

                    {!modeloPeticao ? (
                        <div className="rounded-lg border border-dashed border-[#333333] bg-[#0A0A0A] p-6 text-center">
                            <AlertCircle className="mx-auto mb-2 h-6 w-6 text-[#A3A3A3]" />
                            <p className="text-sm text-[#A3A3A3]">
                                Nenhum template de petição configurado para{" "}
                                <span className="text-white font-medium">
                                    {getTipoBeneficioLabel(processo.tipo_beneficio)}
                                </span>
                                .
                            </p>
                            <a
                                href="/peticoes"
                                className="inline-flex items-center gap-1 mt-2 text-xs text-[#FACC15] hover:underline"
                            >
                                <FileText className="h-3 w-3" />
                                Configurar templates
                            </a>
                        </div>
                    ) : (
                        <div className="space-y-4">
                            <div className="flex items-center gap-2 p-3 bg-[#0A0A0A] rounded-lg border border-[#333333]">
                                <CheckCircle2 className="h-4 w-4 text-green-400 shrink-0" />
                                <p className="text-xs text-[#A3A3A3]">
                                    Template: <span className="text-white">{modeloPeticao.conteudo_template ? 'Texto configurado' : modeloPeticao.nome_original}</span>
                                    {" · "}Dados extraídos:{" "}
                                    <span className="text-white">{dadosAgrupados.length} campo(s)</span>
                                </p>
                            </div>

                            {peticoesGeradas.length === 0 ? (
                                <p className="text-xs text-[#525252] py-2">
                                    Nenhuma petição gerada ainda.
                                </p>
                            ) : (
                                <div className="space-y-2">
                                    {peticoesGeradas.map((peticao) => (
                                        <div key={peticao.id}>
                                            <div
                                                className="flex items-center justify-between p-3 bg-[#0A0A0A] rounded-lg border border-[#333333] group hover:border-[#FACC15]/20 transition-all"
                                            >
                                                <div className="flex items-center gap-3 min-w-0">
                                                    <span className={`h-2 w-2 rounded-full shrink-0 ${
                                                        peticao.status_geracao === 'concluido'
                                                            ? 'bg-green-500'
                                                            : peticao.status_geracao === 'erro'
                                                              ? 'bg-red-500'
                                                              : 'bg-yellow-500'
                                                    }`} />
                                                    <div className="min-w-0">
                                                        <p className="text-sm text-white truncate">
                                                            Petição - {getTipoBeneficioLabel(peticao.tipo_beneficio)}
                                                        </p>
                                                        <p className="text-[10px] text-[#A3A3A3]">
                                                            Gerada em {new Date(peticao.criado_em).toLocaleString("pt-BR")}
                                                        </p>
                                                    </div>
                                                </div>
                                                <div className="flex items-center gap-2 shrink-0">
                                                    <button
                                                        onClick={() => {
                                                            setEditandoPeticao(peticao.id)
                                                            setConteudoPeticaoEditada(peticao.conteudo_gerado || '')
                                                        }}
                                                        className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-[#1F1F1F] border border-[#333333] text-[#A3A3A3] hover:text-white hover:border-[#FACC15]/30 transition-colors text-xs"
                                                    >
                                                        <Pencil className="h-3 w-3" />
                                                        Editar
                                                    </button>
                                                    {peticao.storage_path && (
                                                        <button
                                                            onClick={() => handleDownloadPeticao(peticao.storage_path!)}
                                                            className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-[#1F1F1F] border border-[#333333] text-[#A3A3A3] hover:text-white hover:border-[#FACC15]/30 transition-colors text-xs"
                                                        >
                                                            <Download className="h-3 w-3" />
                                                            Baixar PDF
                                                        </button>
                                                    )}
                                                </div>
                                            </div>

                                            {/* Editor de petição */}
                                            {editandoPeticao === peticao.id && (
                                                <div className="mt-2 p-4 bg-[#0A0A0A] rounded-lg border border-[#FACC15]/30 space-y-3">
                                                    <div className="flex items-center justify-between">
                                                        <p className="text-xs font-bold uppercase tracking-wider text-[#FACC15]">
                                                            Editando petição
                                                        </p>
                                                        <button
                                                            onClick={() => {
                                                                setEditandoPeticao(null)
                                                                setConteudoPeticaoEditada('')
                                                            }}
                                                            className="p-1 rounded hover:bg-[#333333] text-[#A3A3A3] hover:text-white transition-colors"
                                                        >
                                                            <X className="h-4 w-4" />
                                                        </button>
                                                    </div>
                                                    <textarea
                                                        value={conteudoPeticaoEditada}
                                                        onChange={(e) => setConteudoPeticaoEditada(e.target.value)}
                                                        className="w-full h-80 bg-[#171717] border border-[#333333] rounded-lg p-4 text-sm text-white font-mono resize-y focus:outline-none focus:border-[#FACC15]/50"
                                                    />
                                                    <div className="flex items-center gap-2 justify-end">
                                                        <button
                                                            onClick={() => {
                                                                setEditandoPeticao(null)
                                                                setConteudoPeticaoEditada('')
                                                            }}
                                                            className="px-4 py-2 rounded-lg bg-[#1F1F1F] border border-[#333333] text-[#A3A3A3] hover:text-white text-sm transition-colors"
                                                        >
                                                            Cancelar
                                                        </button>
                                                        <button
                                                            onClick={() => handleSalvarPeticaoEditada(peticao.id)}
                                                            disabled={salvandoPeticao || !conteudoPeticaoEditada.trim()}
                                                            className="flex items-center gap-2 px-4 py-2 rounded-lg bg-[#FACC15] hover:bg-[#EAB308] disabled:opacity-50 transition-colors text-black font-bold text-sm"
                                                        >
                                                            {salvandoPeticao ? (
                                                                <Loader2 className="h-4 w-4 animate-spin" />
                                                            ) : (
                                                                <Check className="h-4 w-4" />
                                                            )}
                                                            Salvar e regenerar PDF
                                                        </button>
                                                    </div>
                                                </div>
                                            )}
                                        </div>
                                    ))}
                                </div>
                            )}
                        </div>
                    )}
                </div>
            </div>
        </DashboardLayout>
    )
}
