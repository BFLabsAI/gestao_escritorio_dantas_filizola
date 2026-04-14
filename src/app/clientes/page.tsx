"use client"

import { useState, useEffect } from "react"
import DashboardLayout from "@/components/layout/dashboard-layout"
import Link from "next/link"
import { Search, Filter, Plus, Phone, Mail, FileText, CheckCircle2, Loader2, Trash2 } from "lucide-react"
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription } from "@/components/ui/dialog"
import { buscarClientes, criarCliente, deletarCliente } from "@/lib/services/clientes"
import type { Cliente } from "@/lib/types/database"

const STATUS_OPCOES = [
    { value: "ativo", label: "Ativo" },
    { value: "pendente", label: "Pendente" },
    { value: "inativo", label: "Inativo" },
]

export default function ClientesPage() {
    const [clientes, setClientes] = useState<Cliente[]>([])
    const [carregando, setCarregando] = useState(true)
    const [dialogOpen, setDialogOpen] = useState(false)
    const [isSuccess, setIsSuccess] = useState(false)
    const [form, setForm] = useState({ nome: "", cpf: "", telefone: "", email: "" })
    const [errors, setErrors] = useState<Record<string, string>>({})
    const [busca, setBusca] = useState("")
    const [filtrosAtivos, setFiltrosAtivos] = useState<string[]>([])
    const [showFiltros, setShowFiltros] = useState(false)
    const [deletandoId, setDeletandoId] = useState<string | null>(null)

    const carregarClientes = async () => {
        setCarregando(true)
        try {
            const { clientes: data } = await buscarClientes()
            if (data) setClientes(data)
        } catch (error) {
            console.error("Erro ao buscar clientes:", error)
        } finally {
            setCarregando(false)
        }
    }

    useEffect(() => {
        carregarClientes()
    }, [])

    const toggleFiltro = (status: string) => {
        setFiltrosAtivos((prev) =>
            prev.includes(status) ? prev.filter((s) => s !== status) : [...prev, status]
        )
    }

    const clientesFiltrados = clientes.filter((c) => {
        const matchBusca =
            busca === "" ||
            c.nome_completo.toLowerCase().includes(busca.toLowerCase()) ||
            c.cpf.includes(busca) ||
            (c.email && c.email.toLowerCase().includes(busca.toLowerCase())) ||
            (c.telefone && c.telefone.includes(busca))
        return matchBusca
    })

    const validarForm = () => {
        const novosErros: Record<string, string> = {}
        if (!form.nome.trim()) novosErros.nome = "Nome e obrigatorio"
        if (!form.cpf.trim() || form.cpf.replace(/\D/g, "").length < 11) novosErros.cpf = "CPF invalido"
        if (!form.telefone.trim()) novosErros.telefone = "Telefone e obrigatorio"
        setErrors(novosErros)
        return Object.keys(novosErros).length === 0
    }

    const handleSubmit = async () => {
        if (!validarForm()) return

        try {
            await criarCliente({
                nome_completo: form.nome,
                cpf: form.cpf,
                telefone: form.telefone,
                email: form.email,
            })

            setForm({ nome: "", cpf: "", telefone: "", email: "" })
            setErrors({})
            setDialogOpen(false)
            setIsSuccess(true)
            setTimeout(() => setIsSuccess(false), 3000)

            await carregarClientes()
        } catch (error) {
            console.error("Erro ao criar cliente:", error)
        }
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

    const handleDeleteCliente = async (event: React.MouseEvent<HTMLButtonElement>, id: string) => {
        event.preventDefault()
        event.stopPropagation()

        const confirmar = window.confirm("Apagar este lead/cliente? Essa ação é usada para testes e não pode ser desfeita.")
        if (!confirmar) return

        setDeletandoId(id)
        const { error } = await deletarCliente(id)

        if (error) {
            window.alert(`Erro ao apagar cliente: ${error.message}`)
            setDeletandoId(null)
            return
        }

        await carregarClientes()
        setDeletandoId(null)
    }

    return (
        <DashboardLayout>
            <div className="flex flex-col gap-8 px-12 py-10 w-full max-w-full">
                {/* Header Section */}
                <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
                    <div>
                        <h2 className="text-3xl font-black text-white tracking-tight">Clientes</h2>
                        <p className="text-[#A3A3A3] mt-1">Gerencie todos os clientes do escritorio.</p>
                    </div>
                    <div className="flex gap-3">
                        <div className="relative flex items-center">
                            <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-[#A3A3A3] pointer-events-none" />
                            <input
                                type="search"
                                placeholder="Buscar cliente..."
                                value={busca}
                                onChange={(e) => setBusca(e.target.value)}
                                className="h-10 w-64 rounded-lg border border-[#333333] bg-[#1F1F1F] pl-10 pr-4 text-sm outline-none focus:border-[#FACC15] focus:ring-1 focus:ring-[#FACC15] transition-all text-white placeholder:text-[#A3A3A3]"
                            />
                        </div>
                        <div className="relative">
                            <button
                                onClick={() => setShowFiltros(!showFiltros)}
                                className={`flex items-center gap-2 px-4 py-2 rounded-lg text-sm font-medium transition-colors ${
                                    filtrosAtivos.length > 0
                                        ? "bg-[#FACC15]/10 border border-[#FACC15]/30 text-[#FACC15]"
                                        : "bg-[#1F1F1F] border border-[#333333] text-[#A3A3A3] hover:text-white hover:border-[#FACC15]/50"
                                }`}
                            >
                                <Filter className="h-4 w-4" />
                                Filtros
                                {filtrosAtivos.length > 0 && (
                                    <span className="ml-1 h-5 w-5 rounded-full bg-[#FACC15] text-black text-[10px] font-bold flex items-center justify-center">
                                        {filtrosAtivos.length}
                                    </span>
                                )}
                            </button>

                            {showFiltros && (
                                <div className="absolute right-0 top-full mt-2 z-50 bg-[#171717] border border-[#333333] rounded-xl p-4 shadow-2xl w-56">
                                    <div className="flex items-center justify-between mb-3">
                                        <span className="text-xs font-bold text-white uppercase tracking-widest">Filtrar por Status</span>
                                        {filtrosAtivos.length > 0 && (
                                            <button onClick={() => setFiltrosAtivos([])} className="text-[10px] text-red-400 hover:text-red-300 font-bold uppercase">
                                                Limpar
                                            </button>
                                        )}
                                    </div>
                                    <div className="flex flex-col gap-1.5">
                                        {STATUS_OPCOES.map((opcao) => (
                                            <button
                                                key={opcao.value}
                                                onClick={() => toggleFiltro(opcao.value)}
                                                className={`flex items-center gap-3 px-3 py-2 rounded-lg text-left text-xs font-medium transition-all ${
                                                    filtrosAtivos.includes(opcao.value)
                                                        ? "bg-[#FACC15]/10 text-[#FACC15] border border-[#FACC15]/20"
                                                        : "text-[#A3A3A3] hover:bg-[#1F1F1F] hover:text-white"
                                                }`}
                                            >
                                                <span className={`h-2 w-2 rounded-full border ${filtrosAtivos.includes(opcao.value) ? "bg-[#FACC15] border-[#FACC15]" : "border-[#525252]"}`} />
                                                {opcao.label}
                                            </button>
                                        ))}
                                    </div>
                                </div>
                            )}
                        </div>
                        <button
                            onClick={() => setDialogOpen(true)}
                            className="flex items-center justify-center gap-2 rounded-lg bg-[#FACC15] hover:bg-[#EAB308] transition-colors px-6 py-2.5 text-black font-bold text-sm shadow-[0_0_15px_rgba(250,204,21,0.15)]"
                        >
                            <Plus className="h-4 w-4" />
                            Novo Cliente
                        </button>
                    </div>
                </div>

                {/* Success Toast */}
                {isSuccess && (
                    <div className="flex items-center gap-2 bg-green-500/10 text-green-400 px-4 py-2 rounded-lg border border-green-500/20 animate-in fade-in">
                        <CheckCircle2 className="h-5 w-5" />
                        <span className="text-sm font-bold uppercase tracking-tight">Cliente cadastrado com sucesso!</span>
                    </div>
                )}

                {/* Stats Cards */}
                <div className="grid gap-4 md:grid-cols-3">
                    <div className="bg-[#171717] border border-[#333333] p-6 rounded-xl">
                        <div className="flex items-center gap-3">
                            <div className="h-10 w-10 rounded-lg bg-[#FACC15]/10 flex items-center justify-center">
                                <span className="material-symbols-outlined text-[#FACC15]">group</span>
                            </div>
                            <div>
                                <p className="text-[#A3A3A3] text-sm">Total de Clientes</p>
                                <p className="text-2xl font-bold text-white">{clientesFiltrados.length}</p>
                            </div>
                        </div>
                    </div>
                    <div className="bg-[#171717] border border-[#333333] p-6 rounded-xl">
                        <div className="flex items-center gap-3">
                            <div className="h-10 w-10 rounded-lg bg-green-500/10 flex items-center justify-center">
                                <span className="material-symbols-outlined text-green-400">check_circle</span>
                            </div>
                            <div>
                                <p className="text-[#A3A3A3] text-sm">Clientes Ativos</p>
                                <p className="text-2xl font-bold text-white">{clientesFiltrados.length}</p>
                            </div>
                        </div>
                    </div>
                    <div className="bg-[#171717] border border-[#333333] p-6 rounded-xl">
                        <div className="flex items-center gap-3">
                            <div className="h-10 w-10 rounded-lg bg-yellow-500/10 flex items-center justify-center">
                                <span className="material-symbols-outlined text-yellow-400">pending</span>
                            </div>
                            <div>
                                <p className="text-[#A3A3A3] text-sm">Pendentes</p>
                                <p className="text-2xl font-bold text-white">{clientesFiltrados.length}</p>
                            </div>
                        </div>
                    </div>
                </div>

                {/* Loading Spinner */}
                {carregando && (
                    <div className="flex flex-col items-center justify-center py-20 gap-4">
                        <Loader2 className="h-10 w-10 text-[#FACC15] animate-spin" />
                        <p className="text-[#A3A3A3] text-sm">Carregando clientes...</p>
                    </div>
                )}

                {/* Empty State */}
                {!carregando && clientesFiltrados.length === 0 && (
                    <div className="flex flex-col items-center justify-center py-20 gap-4">
                        <FileText className="h-10 w-10 text-[#525252]" />
                        <p className="text-[#A3A3A3] text-sm">Nenhum cliente encontrado</p>
                    </div>
                )}

                {/* Clientes Grid */}
                {!carregando && clientesFiltrados.length > 0 && (
                    <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
                        {clientesFiltrados.map((cliente) => (
                            <Link
                                key={cliente.id}
                                href={`/clientes/${cliente.id}`}
                                className="bg-[#171717] border border-[#333333] rounded-xl p-6 hover:border-[#FACC15]/30 transition-all group cursor-pointer"
                            >
                                <div className="flex items-start justify-between mb-4">
                                    <div className="flex items-center gap-3">
                                        <div className="h-12 w-12 rounded-full bg-[#262626] flex items-center justify-center text-lg font-bold text-[#FACC15] border border-[#333333]">
                                            {cliente.nome_completo.split(' ').map(n => n[0]).join('').slice(0, 2)}
                                        </div>
                                        <div>
                                            <h3 className="font-bold text-white group-hover:text-[#FACC15] transition-colors">{cliente.nome_completo}</h3>
                                            <p className="text-xs text-[#A3A3A3] font-mono">{cliente.cpf}</p>
                                        </div>
                                    </div>
                                    <span className="px-2 py-1 rounded text-[10px] font-bold uppercase border bg-green-500/10 text-green-400 border-green-500/20">
                                        Ativo
                                    </span>
                                </div>

                                <div className="mb-4 flex justify-end">
                                    <button
                                        onClick={(event) => handleDeleteCliente(event, cliente.id)}
                                        disabled={deletandoId === cliente.id}
                                        className="inline-flex items-center gap-2 rounded-lg bg-red-500/10 px-3 py-1.5 text-[10px] font-bold uppercase tracking-wider text-red-400 transition-colors hover:bg-red-500/20 disabled:opacity-50"
                                    >
                                        {deletandoId === cliente.id ? <Loader2 className="h-3.5 w-3.5 animate-spin" /> : <Trash2 className="h-3.5 w-3.5" />}
                                        Apagar
                                    </button>
                                </div>

                                <div className="space-y-2 mb-4">
                                    <div className="flex items-center gap-2 text-sm text-[#A3A3A3]">
                                        <Phone className="h-4 w-4" />
                                        <span>{cliente.telefone || "---"}</span>
                                    </div>
                                    <div className="flex items-center gap-2 text-sm text-[#A3A3A3]">
                                        <Mail className="h-4 w-4" />
                                        <span className="truncate">{cliente.email || "---"}</span>
                                    </div>
                                </div>

                                <div className="flex items-center justify-between pt-4 border-t border-[#333333]">
                                    <div className="flex items-center gap-2">
                                        <FileText className="h-4 w-4 text-[#A3A3A3]" />
                                        <span className="text-sm text-[#A3A3A3]">
                                            <span className="text-white font-bold">&mdash;</span> processo(s)
                                        </span>
                                    </div>
                                    <span className="text-xs text-[#A3A3A3]">
                                        Cadastrado em: {cliente.criado_em ? new Date(cliente.criado_em).toLocaleDateString('pt-BR') : "---"}
                                    </span>
                                </div>
                            </Link>
                        ))}
                    </div>
                )}
            </div>

            {/* Dialog Novo Cliente */}
            <Dialog open={dialogOpen} onOpenChange={setDialogOpen}>
                <DialogContent className="bg-[#171717] border-[#333333] text-white sm:max-w-lg">
                    <DialogHeader>
                        <DialogTitle className="text-xl font-black text-white uppercase tracking-tight">Novo Cliente</DialogTitle>
                        <DialogDescription className="text-[#A3A3A3] text-sm">Preencha os dados do novo cliente.</DialogDescription>
                    </DialogHeader>

                    <div className="space-y-4 mt-4">
                        <div>
                            <label className="text-[10px] font-black uppercase text-[#A3A3A3] tracking-widest block mb-1.5">Nome Completo</label>
                            <input
                                type="text"
                                value={form.nome}
                                onChange={(e) => setForm({ ...form, nome: e.target.value })}
                                placeholder="NOME DO CLIENTE"
                                className={`w-full h-11 rounded-lg bg-[#1F1F1F] border px-4 text-sm outline-none focus:ring-1 transition-all text-white placeholder:text-[#525252] ${errors.nome ? "border-red-500 focus:border-red-500 focus:ring-red-500" : "border-[#333333] focus:border-[#FACC15] focus:ring-[#FACC15]"}`}
                            />
                            {errors.nome && <p className="text-red-400 text-[10px] font-bold mt-1">{errors.nome}</p>}
                        </div>

                        <div className="grid grid-cols-2 gap-4">
                            <div>
                                <label className="text-[10px] font-black uppercase text-[#A3A3A3] tracking-widest block mb-1.5">CPF</label>
                                <input
                                    type="text"
                                    value={form.cpf}
                                    onChange={(e) => setForm({ ...form, cpf: formatarCPF(e.target.value) })}
                                    placeholder="000.000.000-00"
                                    className={`w-full h-11 rounded-lg bg-[#1F1F1F] border px-4 text-sm outline-none focus:ring-1 transition-all text-white font-mono placeholder:text-[#525252] ${errors.cpf ? "border-red-500 focus:border-red-500 focus:ring-red-500" : "border-[#333333] focus:border-[#FACC15] focus:ring-[#FACC15]"}`}
                                />
                                {errors.cpf && <p className="text-red-400 text-[10px] font-bold mt-1">{errors.cpf}</p>}
                            </div>
                            <div>
                                <label className="text-[10px] font-black uppercase text-[#A3A3A3] tracking-widest block mb-1.5">Telefone</label>
                                <input
                                    type="text"
                                    value={form.telefone}
                                    onChange={(e) => setForm({ ...form, telefone: formatarTelefone(e.target.value) })}
                                    placeholder="(00) 00000-0000"
                                    className={`w-full h-11 rounded-lg bg-[#1F1F1F] border px-4 text-sm outline-none focus:ring-1 transition-all text-white font-mono placeholder:text-[#525252] ${errors.telefone ? "border-red-500 focus:border-red-500 focus:ring-red-500" : "border-[#333333] focus:border-[#FACC15] focus:ring-[#FACC15]"}`}
                                />
                                {errors.telefone && <p className="text-red-400 text-[10px] font-bold mt-1">{errors.telefone}</p>}
                            </div>
                        </div>

                        <div>
                            <label className="text-[10px] font-black uppercase text-[#A3A3A3] tracking-widest block mb-1.5">Email (opcional)</label>
                            <input
                                type="email"
                                value={form.email}
                                onChange={(e) => setForm({ ...form, email: e.target.value })}
                                placeholder="email@exemplo.com"
                                className="w-full h-11 rounded-lg bg-[#1F1F1F] border border-[#333333] px-4 text-sm outline-none focus:border-[#FACC15] focus:ring-1 focus:ring-[#FACC15] transition-all text-white placeholder:text-[#525252]"
                            />
                        </div>
                    </div>

                    <div className="flex justify-end gap-3 mt-6">
                        <button
                            onClick={() => { setDialogOpen(false); setForm({ nome: "", cpf: "", telefone: "", email: "" }); setErrors({}) }}
                            className="px-6 py-2.5 rounded-lg bg-[#1F1F1F] border border-[#333333] text-sm font-medium text-[#A3A3A3] hover:text-white hover:border-[#FACC15]/50 transition-colors"
                        >
                            Cancelar
                        </button>
                        <button
                            onClick={handleSubmit}
                            className="flex items-center gap-2 rounded-lg bg-[#FACC15] hover:bg-[#EAB308] transition-colors px-6 py-2.5 text-black font-bold text-sm shadow-[0_0_15px_rgba(250,204,21,0.15)]"
                        >
                            <Plus className="h-4 w-4" />
                            Cadastrar Cliente
                        </button>
                    </div>
                </DialogContent>
            </Dialog>
        </DashboardLayout>
    )
}
