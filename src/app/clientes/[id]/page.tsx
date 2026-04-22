"use client"

import { use, useState, useEffect } from "react"
import DashboardLayout from "@/components/layout/dashboard-layout"
import Link from "next/link"
import { ArrowLeft, Phone, Mail, FileText, Clock, Edit, Trash2, Loader2, ChevronDown, ChevronUp, ChevronRight, Save } from "lucide-react"
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription, DialogFooter } from "@/components/ui/dialog"
import { Switch } from "@/components/ui/switch"
import { buscarClientePorId, deletarCliente, atualizarCliente } from "@/lib/services/clientes"
import { buscarProcessosPorCliente } from "@/lib/services/processos"
import { buscarDocumentosPorProcesso } from "@/lib/services/documentos"
import type { Cliente, Processo, Documento, Sexo } from "@/lib/types/database"
import { FASE_KANBAN_LABELS, FASE_KANBAN_COLORS, getTipoBeneficioLabel } from "@/lib/types/database"
import ComentariosCliente from "@/components/comentarios-cliente"

interface DocumentoComProcesso extends Documento {
    processo_id: string
}

interface ProcessoDocumentos {
    processo: Processo
    totalDocumentos: number
}

function agruparDocumentosPorProcesso(
    documentos: DocumentoComProcesso[],
    processos: Processo[],
): ProcessoDocumentos[] {
    return processos
        .map((processo) => {
            const docsDoProcesso = documentos.filter((d) => d.processo_id === processo.id)
            return { processo, totalDocumentos: docsDoProcesso.length }
        })
        .filter((p) => p.totalDocumentos > 0)
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

const formatarCPF = (value: string) => {
    const nums = value.replace(/\D/g, "").slice(0, 11)
    if (nums.length <= 3) return nums
    if (nums.length <= 6) return `${nums.slice(0, 3)}.${nums.slice(3)}`
    if (nums.length <= 9) return `${nums.slice(0, 3)}.${nums.slice(3, 6)}.${nums.slice(6)}`
    return `${nums.slice(0, 3)}.${nums.slice(3, 6)}.${nums.slice(6, 9)}-${nums.slice(9)}`
}

const formatarTelefone = (value: string) => {
    const nums = value.replace(/\D/g, "").slice(0, 11)
    if (nums.length <= 2) return nums.length ? `(${nums}` : ""
    if (nums.length <= 7) return `(${nums.slice(0, 2)}) ${nums.slice(2)}`
    return `(${nums.slice(0, 2)}) ${nums.slice(2, 7)}-${nums.slice(7)}`
}

const formatarCEP = (value: string) => {
    const nums = value.replace(/\D/g, "").slice(0, 8)
    if (nums.length <= 5) return nums
    return `${nums.slice(0, 5)}-${nums.slice(5)}`
}

export default function ClienteDetalhePage({ params }: { params: Promise<{ id: string }> }) {
    const resolvedParams = use(params)
    const [cliente, setCliente] = useState<Cliente | null>(null)
    const [processos, setProcessos] = useState<Processo[]>([])
    const [documentos, setDocumentos] = useState<DocumentoComProcesso[]>([])
    const [loading, setLoading] = useState(true)
    const [deletando, setDeletando] = useState(false)
    const [error, setError] = useState<string | null>(null)

    // Edit modal state
    const [editDialogOpen, setEditDialogOpen] = useState(false)
    const [salvando, setSalvando] = useState(false)
    const [editErrors, setEditErrors] = useState<Record<string, string>>({})
    const [editForm, setEditForm] = useState({
        nome_completo: "",
        cpf: "",
        telefone: "",
        email: "",
        sexo: "nao_informado" as Sexo,
    })

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

    const openEditDialog = () => {
        if (!cliente) return
        setEditForm({
            nome_completo: cliente.nome_completo,
            cpf: cliente.cpf,
            telefone: cliente.telefone || "",
            email: cliente.email || "",
            sexo: cliente.sexo,
        })
        setEditErrors({})
        setEditDialogOpen(true)
    }

    const validarForm = () => {
        const novosErros: Record<string, string> = {}
        if (!editForm.nome_completo.trim()) novosErros.nome_completo = "Nome e obrigatorio"
        if (!editForm.cpf.trim() || editForm.cpf.replace(/\D/g, "").length < 11) novosErros.cpf = "CPF invalido"
        if (editForm.email.trim() && !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(editForm.email)) novosErros.email = "E-mail invalido"
        setEditErrors(novosErros)
        return Object.keys(novosErros).length === 0
    }

    const handleEditSubmit = async () => {
        if (!cliente || !validarForm()) return

        setSalvando(true)

        const { error: erro } = await atualizarCliente(cliente.id, {
            nome_completo: editForm.nome_completo,
            cpf: editForm.cpf,
            telefone: editForm.telefone || null,
            email: editForm.email || null,
            sexo: editForm.sexo,
        })

        setSalvando(false)

        if (erro) {
            window.alert(`Erro ao salvar: ${erro.message}`)
            return
        }

        setCliente(prev => prev ? {
            ...prev,
            nome_completo: editForm.nome_completo,
            cpf: editForm.cpf,
            telefone: editForm.telefone || null,
            email: editForm.email || null,
            sexo: editForm.sexo,
        } : null)
        setEditDialogOpen(false)
    }

    const handleToggleAtivo = async (checked: boolean) => {
        if (!cliente) return
        const { error: erro } = await atualizarCliente(cliente.id, { ativo: checked })
        if (!erro) {
            setCliente(prev => prev ? { ...prev, ativo: checked } : null)
        } else {
            window.alert(`Erro ao alterar status: ${erro.message}`)
        }
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
                            <button
                                onClick={openEditDialog}
                                className="flex items-center gap-2 px-4 py-2 bg-[#1F1F1F] border border-[#333333] rounded-lg text-sm font-medium text-[#A3A3A3] hover:text-white hover:border-[#FACC15]/50 transition-colors"
                            >
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
                        {/* Status Card com Toggle */}
                        <div className="bg-[#171717] border border-[#333333] rounded-xl p-6">
                            <div className="flex items-center justify-between">
                                <div>
                                    <h3 className="text-sm font-bold text-[#A3A3A3] uppercase tracking-wider">Status</h3>
                                    <p className={`text-sm mt-1 ${cliente.ativo ? 'text-green-400' : 'text-red-400'}`}>
                                        {cliente.ativo ? 'Cliente ativo' : 'Cliente inativo'}
                                    </p>
                                </div>
                                <Switch
                                    checked={cliente.ativo}
                                    onCheckedChange={handleToggleAtivo}
                                    className="data-[state=checked]:bg-green-500 data-[state=unchecked]:bg-red-500/50"
                                />
                            </div>
                        </div>

                        {/* Documentos por Pasta */}
                        <CollapsibleSection
                            title="Documentos"
                            badge={String(documentos.length)}
                            icon={<span className="material-symbols-outlined text-[#FACC15] text-sm">folder</span>}
                            defaultOpen={true}
                        >
                            <div className="pt-4">
                                {documentos.length === 0 ? (
                                    <p className="text-[#A3A3A3] text-sm py-2">Nenhum documento encontrado.</p>
                                ) : (
                                    <div className="space-y-2">
                                        {agruparDocumentosPorProcesso(documentos, processos).map(({ processo, totalDocumentos }) => (
                                            <Link
                                                key={processo.id}
                                                href={`/clientes/${resolvedParams.id}/documentos`}
                                                className="flex items-center justify-between p-3 bg-[#0A0A0A] rounded-lg border border-[#333333] hover:border-[#FACC15]/30 transition-colors group"
                                            >
                                                <div className="flex items-center gap-3 min-w-0">
                                                    <span className="material-symbols-outlined text-[#FACC15] text-lg shrink-0">folder</span>
                                                    <div className="min-w-0">
                                                        <p className="text-sm text-white truncate group-hover:text-[#FACC15] transition-colors">
                                                            {getTipoBeneficioLabel(processo.tipo_beneficio)}
                                                        </p>
                                                        <p className="text-[10px] text-[#A3A3A3]">{totalDocumentos} documento(s)</p>
                                                    </div>
                                                </div>
                                                <ChevronRight className="h-4 w-4 text-[#525252] shrink-0" />
                                            </Link>
                                        ))}
                                    </div>
                                )}
                                {documentos.length > 0 && (
                                    <Link
                                        href={`/clientes/${resolvedParams.id}/documentos`}
                                        className="mt-3 flex items-center justify-center gap-2 p-2.5 rounded-lg bg-[#FACC15]/10 text-[#FACC15] text-xs font-bold hover:bg-[#FACC15]/20 transition-colors"
                                    >
                                        <FileText className="h-3.5 w-3.5" />
                                        Ver todos os documentos
                                    </Link>
                                )}
                            </div>
                        </CollapsibleSection>
                    </div>
                </div>
            </div>

            {/* Edit Dialog */}
            <Dialog open={editDialogOpen} onOpenChange={setEditDialogOpen}>
                <DialogContent className="bg-[#171717] border-[#333333] text-white sm:max-w-lg max-h-[90vh] overflow-y-auto">
                    <DialogHeader>
                        <DialogTitle className="text-xl font-black text-white uppercase tracking-tight">Editar Cliente</DialogTitle>
                        <DialogDescription className="text-[#A3A3A3] text-sm">Atualize os dados do cliente.</DialogDescription>
                    </DialogHeader>

                    <div className="space-y-4 mt-4">
                        {/* Nome */}
                        <div>
                            <label className="text-[10px] font-black uppercase text-[#A3A3A3] tracking-widest block mb-1.5">Nome Completo</label>
                            <input
                                type="text"
                                value={editForm.nome_completo}
                                onChange={(e) => setEditForm({ ...editForm, nome_completo: e.target.value })}
                                className={`w-full h-11 rounded-lg bg-[#1F1F1F] border px-4 text-sm outline-none focus:ring-1 transition-all text-white placeholder:text-[#525252] ${editErrors.nome_completo ? "border-red-500 focus:border-red-500 focus:ring-red-500" : "border-[#333333] focus:border-[#FACC15] focus:ring-[#FACC15]"}`}
                            />
                            {editErrors.nome_completo && <p className="text-red-400 text-[10px] font-bold mt-1">{editErrors.nome_completo}</p>}
                        </div>

                        {/* CPF */}
                        <div className="grid grid-cols-2 gap-4">
                            <div>
                                <label className="text-[10px] font-black uppercase text-[#A3A3A3] tracking-widest block mb-1.5">CPF</label>
                                <input
                                    type="text"
                                    value={editForm.cpf}
                                    onChange={(e) => setEditForm({ ...editForm, cpf: formatarCPF(e.target.value) })}
                                    className={`w-full h-11 rounded-lg bg-[#1F1F1F] border px-4 text-sm outline-none focus:ring-1 transition-all text-white font-mono placeholder:text-[#525252] ${editErrors.cpf ? "border-red-500 focus:border-red-500 focus:ring-red-500" : "border-[#333333] focus:border-[#FACC15] focus:ring-[#FACC15]"}`}
                                />
                                {editErrors.cpf && <p className="text-red-400 text-[10px] font-bold mt-1">{editErrors.cpf}</p>}
                            </div>
                            <div>
                                <label className="text-[10px] font-black uppercase text-[#A3A3A3] tracking-widest block mb-1.5">Telefone</label>
                                <input
                                    type="text"
                                    value={editForm.telefone}
                                    onChange={(e) => setEditForm({ ...editForm, telefone: formatarTelefone(e.target.value) })}
                                    placeholder="(00) 00000-0000"
                                    className="w-full h-11 rounded-lg bg-[#1F1F1F] border border-[#333333] px-4 text-sm outline-none focus:border-[#FACC15] focus:ring-1 focus:ring-[#FACC15] transition-all text-white font-mono placeholder:text-[#525252]"
                                />
                            </div>
                        </div>

                        {/* Email */}
                        <div>
                            <label className="text-[10px] font-black uppercase text-[#A3A3A3] tracking-widest block mb-1.5">E-mail</label>
                            <input
                                type="email"
                                value={editForm.email}
                                onChange={(e) => setEditForm({ ...editForm, email: e.target.value })}
                                placeholder="email@exemplo.com"
                                className={`w-full h-11 rounded-lg bg-[#1F1F1F] border px-4 text-sm outline-none focus:ring-1 transition-all text-white placeholder:text-[#525252] ${editErrors.email ? "border-red-500 focus:border-red-500 focus:ring-red-500" : "border-[#333333] focus:border-[#FACC15] focus:ring-[#FACC15]"}`}
                            />
                            {editErrors.email && <p className="text-red-400 text-[10px] font-bold mt-1">{editErrors.email}</p>}
                        </div>

                        {/* Sexo */}
                        <div>
                            <label className="text-[10px] font-black uppercase text-[#A3A3A3] tracking-widest block mb-1.5">Sexo</label>
                            <select
                                value={editForm.sexo}
                                onChange={(e) => setEditForm({ ...editForm, sexo: e.target.value as Sexo })}
                                className="w-full h-11 rounded-lg bg-[#1F1F1F] border border-[#333333] px-4 text-sm outline-none focus:border-[#FACC15] focus:ring-1 focus:ring-[#FACC15] transition-all text-white appearance-none cursor-pointer"
                            >
                                <option value="nao_informado">Nao informado</option>
                                <option value="masculino">Masculino</option>
                                <option value="feminino">Feminino</option>
                            </select>
                        </div>

                    </div>

                    <DialogFooter className="mt-6">
                        <button
                            onClick={() => setEditDialogOpen(false)}
                            className="px-6 py-2.5 rounded-lg bg-[#1F1F1F] border border-[#333333] text-sm font-medium text-[#A3A3A3] hover:text-white hover:border-[#FACC15]/50 transition-colors"
                        >
                            Cancelar
                        </button>
                        <button
                            onClick={handleEditSubmit}
                            disabled={salvando}
                            className="flex items-center gap-2 rounded-lg bg-[#FACC15] hover:bg-[#EAB308] transition-colors px-6 py-2.5 text-black font-bold text-sm shadow-[0_0_15px_rgba(250,204,21,0.15)] disabled:opacity-50"
                        >
                            {salvando ? <Loader2 className="h-4 w-4 animate-spin" /> : <Save className="h-4 w-4" />}
                            Salvar
                        </button>
                    </DialogFooter>
                </DialogContent>
            </Dialog>
        </DashboardLayout>
    )
}
