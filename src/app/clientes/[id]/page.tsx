"use client"

import { use, useState, useEffect } from "react"
import DashboardLayout from "@/components/layout/dashboard-layout"
import Link from "next/link"
import { ArrowLeft, Phone, Mail, MapPin, Calendar, FileText, Clock, Edit, Trash2, Loader2, Download, Sparkles, ChevronDown, ChevronUp } from "lucide-react"
import { buscarClientePorId, deletarCliente } from "@/lib/services/clientes"
import { buscarProcessosPorCliente } from "@/lib/services/processos"
import { buscarDocumentosPorProcesso } from "@/lib/services/documentos"
import { buscarPeticoesPorCliente, getUrlPeticaoGerada } from "@/lib/services/peticoes"
import type { Cliente, Processo, Documento, PeticaoGerada } from "@/lib/types/database"
import { FASE_KANBAN_LABELS, FASE_KANBAN_COLORS, getTipoBeneficioLabel, getTipoDocumentoLabel } from "@/lib/types/database"
import { calcularIdade } from "@/lib/utils/calculo-idade"
import ComentariosCliente from "@/components/comentarios-cliente"

interface DocumentoComProcesso extends Documento {
    processo_id: string
}

function CollapsibleSection({
    title,
    icon,
    defaultOpen = true,
    children,
    badge,
}: {
    title: string
    icon: React.ReactNode
    defaultOpen?: boolean
    children: React.ReactNode
    badge?: string
}) {
    const [isOpen, setIsOpen] = useState(defaultOpen)

    return (
        <div className="bg-[#171717] border border-[#333333] rounded-xl overflow-hidden">
            <button
                onClick={() => setIsOpen(!isOpen)}
                className="w-full flex items-center justify-between p-5 hover:bg-[#1F1F1F]/50 transition-colors"
            >
                <div className="flex items-center gap-3">
                    <div className="h-8 w-8 rounded-lg bg-[#FACC15]/10 flex items-center justify-center">
                        {icon}
                    </div>
                    <h2 className="text-sm font-bold text-white">{title}</h2>
                    {badge && (
                        <span className="px-2 py-0.5 rounded-full bg-[#FACC15]/10 text-[#FACC15] text-[10px] font-bold border border-[#FACC15]/20">
                            {badge}
                        </span>
                    )}
                </div>
                {isOpen ? (
                    <ChevronUp className="h-4 w-4 text-[#A3A3A3]" />
                ) : (
                    <ChevronDown className="h-4 w-4 text-[#A3A3A3]" />
                )}
            </button>
            {isOpen && (
                <div className="px-5 pb-5 border-t border-[#333333]">
                    {children}
                </div>
            )}
        </div>
    )
}

export default function ClienteDetalhePage({ params }: { params: Promise<{ id: string }> }) {
    const resolvedParams = use(params)
    const [cliente, setCliente] = useState<Cliente | null>(null)
    const [processos, setProcessos] = useState<Processo[]>([])
    const [documentos, setDocumentos] = useState<DocumentoComProcesso[]>([])
    const [peticoes, setPeticoes] = useState<PeticaoGerada[]>([])
    const [loading, setLoading] = useState(true)
    const [deletando, setDeletando] = useState(false)
    const [error, setError] = useState<string | null>(null)

    useEffect(() => {
        async function carregarDados() {
            try {
                const id = resolvedParams.id

                const { cliente: clienteData, error: clienteErro } = await buscarClientePorId(id)
                if (clienteErro || !clienteData) {
                    setError("Cliente nao encontrado.")
                    setLoading(false)
                    return
                }
                setCliente(clienteData)

                const { processos: processosData, error: processosErro } = await buscarProcessosPorCliente(id)
                if (!processosErro && processosData) {
                    setProcessos(processosData)

                    const todosDocumentos: DocumentoComProcesso[] = []
                    for (const processo of processosData) {
                        const { documentos: docsData } = await buscarDocumentosPorProcesso(processo.id)
                        if (docsData) {
                            todosDocumentos.push(...docsData)
                        }
                    }
                    setDocumentos(todosDocumentos)
                }

                const { peticoes: peticoesData } = await buscarPeticoesPorCliente(id)
                if (peticoesData) {
                    setPeticoes(peticoesData)
                }
            } catch {
                setError("Erro ao carregar dados do cliente.")
            } finally {
                setLoading(false)
            }
        }

        carregarDados()
    }, [resolvedParams.id])

    const handleDeleteCliente = async () => {
        if (!cliente) return
        const confirmar = window.confirm("Apagar este cliente? Todos os processos e documentos associados tambem serao apagados.")
        if (!confirmar) return

        setDeletando(true)
        const { error: erro } = await deletarCliente(cliente.id)

        if (erro) {
            window.alert(`Erro ao apagar cliente: ${erro.message}`)
            setDeletando(false)
            return
        }

        window.location.href = '/clientes'
    }

    if (loading) {
        return (
            <DashboardLayout>
                <div className="flex items-center justify-center h-[60vh] w-full">
                    <div className="flex flex-col items-center gap-4">
                        <Loader2 className="h-10 w-10 text-[#FACC15] animate-spin" />
                        <p className="text-[#A3A3A3] text-lg font-medium">Carregando dados do cliente...</p>
                    </div>
                </div>
            </DashboardLayout>
        )
    }

    if (error || !cliente) {
        return (
            <DashboardLayout>
                <div className="flex flex-col gap-8 px-12 py-10 w-full max-w-full">
                    <Link
                        href="/clientes"
                        className="flex items-center gap-2 text-[#A3A3A3] hover:text-[#FACC15] transition-colors w-fit"
                    >
                        <ArrowLeft className="h-4 w-4" />
                        <span className="text-sm font-medium">Voltar para Clientes</span>
                    </Link>
                    <div className="bg-[#171717] border border-[#333333] rounded-xl p-8 text-center">
                        <p className="text-red-400 text-lg font-bold">{error || "Cliente nao encontrado."}</p>
                    </div>
                </div>
            </DashboardLayout>
        )
    }

    const initials = cliente.nome_completo
        .split(" ")
        .map((n) => n[0])
        .join("")
        .slice(0, 2)
        .toUpperCase()

    const enderecoCompleto = [
        cliente.endereco?.logradouro,
        cliente.endereco?.numero,
        cliente.endereco?.complemento,
    ]
        .filter(Boolean)
        .join(", ")

    const bairroCidadeUf = [
        cliente.endereco?.bairro,
        cliente.endereco?.cidade,
        cliente.endereco?.uf ? `/${cliente.endereco?.uf}` : "",
    ]
        .filter(Boolean)
        .join(" - ")

    return (
        <DashboardLayout>
            <div className="flex flex-col gap-8 px-12 py-10 w-full max-w-full">
                {/* Header */}
                <div className="flex flex-col gap-4">
                    <Link
                        href="/clientes"
                        className="flex items-center gap-2 text-[#A3A3A3] hover:text-[#FACC15] transition-colors w-fit"
                    >
                        <ArrowLeft className="h-4 w-4" />
                        <span className="text-sm font-medium">Voltar para Clientes</span>
                    </Link>

                    <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
                        <div className="flex items-center gap-4">
                            <div className="h-16 w-16 rounded-full bg-[#262626] flex items-center justify-center text-2xl font-bold text-[#FACC15] border-2 border-[#FACC15]/30">
                                {initials}
                            </div>
                            <div>
                                <h1 className="text-3xl font-black text-white">{cliente.nome_completo}</h1>
                                <p className="text-[#A3A3A3] font-mono">{cliente.cpf}</p>
                            </div>
                        </div>
                        <div className="flex gap-3">
                            <button className="flex items-center gap-2 px-4 py-2 bg-[#1F1F1F] border border-[#333333] rounded-lg text-sm font-medium text-[#A3A3A3] hover:text-white hover:border-[#FACC15]/50 transition-colors">
                                <Edit className="h-4 w-4" />
                                Editar
                            </button>
                            <button
                                onClick={handleDeleteCliente}
                                disabled={deletando}
                                className="flex items-center gap-2 px-4 py-2 bg-red-500/10 border border-red-500/20 rounded-lg text-sm font-medium text-red-400 hover:bg-red-500/20 disabled:opacity-50 transition-colors"
                            >
                                {deletando ? <Loader2 className="h-4 w-4 animate-spin" /> : <Trash2 className="h-4 w-4" />}
                                Excluir
                            </button>
                        </div>
                    </div>
                </div>

                <div className="grid gap-6 lg:grid-cols-3">
                    {/* Coluna principal */}
                    <div className="lg:col-span-2 space-y-6">
                        {/* Dados Pessoais */}
                        <CollapsibleSection
                            title="Dados Pessoais"
                            badge={cliente.sexo === 'masculino' ? 'Masc.' : cliente.sexo === 'feminino' ? 'Fem.' : undefined}
                            icon={<span className="material-symbols-outlined text-[#FACC15] text-sm">person</span>}
                            defaultOpen={true}
                        >
                            <div className="pt-4 grid gap-4 md:grid-cols-2">
                                <div className="space-y-4">
                                    <div className="flex items-start gap-3">
                                        <Phone className="h-5 w-5 text-[#A3A3A3] mt-0.5" />
                                        <div>
                                            <p className="text-xs text-[#A3A3A3] uppercase tracking-wider">Telefone</p>
                                            <p className="text-white font-medium">{cliente.telefone || "—"}</p>
                                        </div>
                                    </div>
                                    <div className="flex items-start gap-3">
                                        <Mail className="h-5 w-5 text-[#A3A3A3] mt-0.5" />
                                        <div>
                                            <p className="text-xs text-[#A3A3A3] uppercase tracking-wider">E-mail</p>
                                            <p className="text-white font-medium">{cliente.email || "—"}</p>
                                        </div>
                                    </div>
                                </div>

                                <div className="space-y-4">
                                    <div className="flex items-start gap-3">
                                        <Calendar className="h-5 w-5 text-[#A3A3A3] mt-0.5" />
                                        <div>
                                            <p className="text-xs text-[#A3A3A3] uppercase tracking-wider">Data de Nascimento</p>
                                            <p className="text-white font-medium">
                                                {cliente.data_nascimento
                                                    ? new Date(cliente.data_nascimento).toLocaleDateString("pt-BR")
                                                    : "—"}
                                            </p>
                                            {cliente.data_nascimento && (() => {
                                                const idade = calcularIdade(cliente.data_nascimento)
                                                return idade ? (
                                                    <p className="text-xs text-[#FACC15] font-medium mt-0.5">
                                                        {idade.textoFormatado}
                                                    </p>
                                                ) : null
                                            })()}
                                        </div>
                                    </div>
                                    <div className="flex items-start gap-3">
                                        <FileText className="h-5 w-5 text-[#A3A3A3] mt-0.5" />
                                        <div>
                                            <p className="text-xs text-[#A3A3A3] uppercase tracking-wider">Sexo</p>
                                            <p className="text-white font-medium">
                                                {cliente.sexo === 'masculino' ? 'Masculino' : cliente.sexo === 'feminino' ? 'Feminino' : 'Nao informado'}
                                            </p>
                                        </div>
                                    </div>
                                    <div className="flex items-start gap-3">
                                        <Clock className="h-5 w-5 text-[#A3A3A3] mt-0.5" />
                                        <div>
                                            <p className="text-xs text-[#A3A3A3] uppercase tracking-wider">Cliente desde</p>
                                            <p className="text-white font-medium">
                                                {new Date(cliente.criado_em).toLocaleDateString("pt-BR")}
                                            </p>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </CollapsibleSection>

                        {/* Endereço */}
                        <CollapsibleSection
                            title="Endereço"
                            icon={<span className="material-symbols-outlined text-[#FACC15] text-sm">location_on</span>}
                            defaultOpen={false}
                        >
                            <div className="pt-4">
                                {cliente.endereco ? (
                                    <div className="flex items-start gap-3">
                                        <MapPin className="h-5 w-5 text-[#A3A3A3] mt-0.5" />
                                        <div>
                                            <p className="text-white font-medium">{enderecoCompleto || "—"}</p>
                                            <p className="text-[#A3A3A3]">{bairroCidadeUf || "—"}</p>
                                            {cliente.endereco.cep && (
                                                <p className="text-[#A3A3A3]">CEP: {cliente.endereco.cep}</p>
                                            )}
                                        </div>
                                    </div>
                                ) : (
                                    <div className="flex items-start gap-3">
                                        <MapPin className="h-5 w-5 text-[#A3A3A3] mt-0.5" />
                                        <div>
                                            <p className="text-[#A3A3A3]">Endereco nao cadastrado</p>
                                        </div>
                                    </div>
                                )}
                            </div>
                        </CollapsibleSection>

                        {/* Processos */}
                        <CollapsibleSection
                            title="Processos"
                            badge={String(processos.length)}
                            icon={<span className="material-symbols-outlined text-[#FACC15] text-sm">balance</span>}
                            defaultOpen={true}
                        >
                            <div className="pt-4 space-y-3">
                                {processos.length === 0 ? (
                                    <p className="text-[#A3A3A3] text-sm py-2">Nenhum processo encontrado.</p>
                                ) : (
                                    processos.map((processo) => (
                                        <Link
                                            key={processo.id}
                                            href={`/processo/${processo.id}`}
                                            className="flex items-center justify-between p-4 bg-[#0A0A0A] border border-[#333333] rounded-lg hover:border-[#FACC15]/30 transition-colors group"
                                        >
                                            <div className="flex items-center gap-4">
                                                <div className="h-10 w-10 rounded-lg bg-[#FACC15]/10 flex items-center justify-center">
                                                    <FileText className="h-5 w-5 text-[#FACC15]" />
                                                </div>
                                                <div>
                                                    <p className="font-bold text-white group-hover:text-[#FACC15] transition-colors">
                                                        {getTipoBeneficioLabel(processo.tipo_beneficio)}
                                                    </p>
                                                    <p className="text-xs text-[#A3A3A3]">
                                                        {processo.numero_processo || processo.id}
                                                    </p>
                                                </div>
                                            </div>
                                            <div className="text-right">
                                                <span
                                                    className={`px-3 py-1 rounded text-xs font-bold border ${
                                                        FASE_KANBAN_COLORS[processo.fase_kanban] ||
                                                        "bg-[#FACC15]/10 text-[#FACC15] border-[#FACC15]/20"
                                                    }`}
                                                >
                                                    {FASE_KANBAN_LABELS[processo.fase_kanban] || processo.fase_kanban}
                                                </span>
                                                <p className="text-xs text-[#A3A3A3] mt-1">
                                                    Aberto em {new Date(processo.criado_em).toLocaleDateString("pt-BR")}
                                                </p>
                                            </div>
                                        </Link>
                                    ))
                                )}
                            </div>
                        </CollapsibleSection>

                        {/* Comentários */}
                        <div className="bg-[#171717] border border-[#333333] rounded-xl p-5">
                            <h2 className="text-sm font-bold text-[#A3A3A3] uppercase tracking-wider mb-4">
                                Comentários
                            </h2>
                            <ComentariosCliente clienteId={resolvedParams.id} />
                        </div>
                    </div>

                    {/* Sidebar */}
                    <div className="space-y-6">
                        {/* Status Card */}
                        <div className="bg-[#171717] border border-[#333333] rounded-xl p-6">
                            <h3 className="text-sm font-bold text-[#A3A3A3] uppercase tracking-wider mb-3">Status</h3>
                            <div className="flex items-center gap-2">
                                <span className="h-3 w-3 rounded-full bg-green-500 animate-pulse" />
                                <span className="text-lg font-bold text-green-400">Ativo</span>
                            </div>
                        </div>

                        {/* Documentos */}
                        <CollapsibleSection
                            title="Documentos"
                            badge={String(documentos.length)}
                            icon={<span className="material-symbols-outlined text-[#FACC15] text-sm">folder</span>}
                            defaultOpen={true}
                        >
                            <div className="pt-4 space-y-3">
                                {documentos.length === 0 ? (
                                    <p className="text-[#A3A3A3] text-sm py-2">Nenhum documento encontrado.</p>
                                ) : (
                                    documentos.map((doc) => {
                                        const qualidadeDotColor =
                                            doc.qualidade_documento === "LEGIVEL"
                                                ? "bg-green-500"
                                                : doc.qualidade_documento === "PENDENTE_ANALISE"
                                                  ? "bg-yellow-500"
                                                  : "bg-red-500"

                                        const qualidadeIcon =
                                            doc.qualidade_documento === "LEGIVEL" ? (
                                                <span className="material-symbols-outlined text-green-500 text-lg">
                                                    check_circle
                                                </span>
                                            ) : doc.qualidade_documento === "PENDENTE_ANALISE" ? (
                                                <span className="material-symbols-outlined text-yellow-500 text-lg">
                                                    pending
                                                </span>
                                            ) : (
                                                <span className="material-symbols-outlined text-red-500 text-lg">
                                                    cancel
                                                </span>
                                            )

                                        return (
                                            <div
                                                key={doc.id}
                                                className="flex items-center justify-between p-3 bg-[#0A0A0A] rounded-lg border border-[#333333]"
                                            >
                                                <div className="flex items-center gap-3">
                                                    <span className={`h-2 w-2 rounded-full ${qualidadeDotColor}`} />
                                                    <span className="text-sm text-white">
                                                        {getTipoDocumentoLabel(doc.tipo_documento)}
                                                    </span>
                                                </div>
                                                {qualidadeIcon}
                                            </div>
                                        )
                                    })
                                )}
                            </div>
                        </CollapsibleSection>

                        {/* Observações */}
                        <CollapsibleSection
                            title="Observações"
                            icon={<span className="material-symbols-outlined text-[#FACC15] text-sm">sticky_note_2</span>}
                            defaultOpen={false}
                        >
                            <div className="pt-4">
                                <p className="text-sm text-[#A3A3A3] leading-relaxed italic">
                                    Nenhuma observacao registrada.
                                </p>
                            </div>
                        </CollapsibleSection>

                        {/* Petições */}
                        <CollapsibleSection
                            title="Petições"
                            badge={String(peticoes.length)}
                            icon={<Sparkles className="h-4 w-4 text-[#FACC15]" />}
                            defaultOpen={true}
                        >
                            <div className="pt-4 space-y-3">
                                {peticoes.length === 0 ? (
                                    <p className="text-[#A3A3A3] text-sm py-2">Nenhuma petição gerada.</p>
                                ) : (
                                    peticoes.map((peticao) => (
                                        <div
                                            key={peticao.id}
                                            className="flex items-center justify-between p-3 bg-[#0A0A0A] rounded-lg border border-[#333333] group hover:border-[#FACC15]/20 transition-all"
                                        >
                                            <div className="flex items-center gap-3 min-w-0">
                                                <Sparkles className="h-4 w-4 text-[#FACC15] shrink-0" />
                                                <div className="min-w-0">
                                                    <p className="text-sm text-white truncate">
                                                        {getTipoBeneficioLabel(peticao.tipo_beneficio)}
                                                    </p>
                                                    <p className="text-[10px] text-[#A3A3A3]">
                                                        {new Date(peticao.criado_em).toLocaleDateString("pt-BR")}
                                                    </p>
                                                </div>
                                            </div>
                                            {peticao.storage_path && (
                                                <button
                                                    onClick={async () => {
                                                        const { url } = await getUrlPeticaoGerada(peticao.storage_path!)
                                                        if (!url) return
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
                                                            // erro silencioso no download
                                                        }
                                                    }}
                                                    className="p-1.5 rounded bg-transparent hover:bg-[#1F1F1F] text-[#A3A3A3] hover:text-white transition-all"
                                                    title="Baixar petição"
                                                >
                                                    <Download className="h-3.5 w-3.5" />
                                                </button>
                                            )}
                                        </div>
                                    ))
                                )}
                            </div>
                        </CollapsibleSection>
                    </div>
                </div>
            </div>
        </DashboardLayout>
    )
}
