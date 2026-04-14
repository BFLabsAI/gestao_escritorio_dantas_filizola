"use client"

import { useEffect, useState } from "react"
import DashboardLayout from "@/components/layout/dashboard-layout"
import Link from "next/link"
import { Search, Filter, Plus, Eye, Edit, FileText, Clock, X, Loader2, Trash2 } from "lucide-react"
import { buscarProcessos, deletarProcesso } from "@/lib/services/processos"
import type { Processo } from "@/lib/types/database"
import { FASE_KANBAN_LABELS, FASE_KANBAN_COLORS, getTipoBeneficioLabel } from "@/lib/types/database"

const FASES_DISPONIVEIS = Object.entries(FASE_KANBAN_LABELS).map(([value, label]) => ({ value, label }))

export default function ProcessosPage() {
    const [processos, setProcessos] = useState<Processo[]>([])
    const [carregando, setCarregando] = useState(true)
    const [busca, setBusca] = useState("")
    const [filtrosAtivos, setFiltrosAtivos] = useState<string[]>([])
    const [showFiltros, setShowFiltros] = useState(false)
    const [deletandoId, setDeletandoId] = useState<string | null>(null)

    const carregarProcessos = async () => {
        setCarregando(true)
        const { processos: data, error } = await buscarProcessos()
        if (!error && data) setProcessos(data)
        setCarregando(false)
    }

    useEffect(() => {
        const timer = window.setTimeout(() => {
            void carregarProcessos()
        }, 0)

        return () => window.clearTimeout(timer)
    }, [])

    async function handleDeleteProcesso(id: string) {
        const confirmar = window.confirm("Apagar este processo? Essa ação é usada para testes e não pode ser desfeita.")
        if (!confirmar) return

        setDeletandoId(id)
        const { error } = await deletarProcesso(id)

        if (error) {
            window.alert(`Erro ao apagar processo: ${error.message}`)
            setDeletandoId(null)
            return
        }

        await carregarProcessos()
        setDeletandoId(null)
    }

    const toggleFiltro = (fase: string) => {
        setFiltrosAtivos((prev) =>
            prev.includes(fase) ? prev.filter((f) => f !== fase) : [...prev, fase]
        )
    }

    const limparFiltros = () => setFiltrosAtivos([])

    const processosFiltrados = processos.filter((p) => {
        const matchBusca =
            busca === "" ||
            p.cliente?.nome_completo.toLowerCase().includes(busca.toLowerCase()) ||
            p.numero_processo?.toLowerCase().includes(busca.toLowerCase()) ||
            p.tipo_beneficio.toLowerCase().includes(busca.toLowerCase()) ||
            p.cliente?.cpf.includes(busca)
        const matchFiltro = filtrosAtivos.length === 0 || filtrosAtivos.includes(p.fase_kanban)
        return matchBusca && matchFiltro
    })

    const faseColor = (fase: string) => FASE_KANBAN_COLORS[fase as keyof typeof FASE_KANBAN_COLORS] || 'bg-gray-500/10 text-gray-400 border-gray-500/20'
    const faseLabel = (fase: string) => FASE_KANBAN_LABELS[fase as keyof typeof FASE_KANBAN_LABELS] || fase
    const beneficioLabel = (tipo: string) => getTipoBeneficioLabel(tipo)

    return (
        <DashboardLayout>
            <div className="flex flex-col gap-8 px-12 py-10 w-full max-w-full">
                {/* Header Section */}
                <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
                    <div>
                        <h2 className="text-3xl font-black text-white tracking-tight">Processos</h2>
                        <p className="text-[#A3A3A3] mt-1">Gerencie todos os processos do escritorio.</p>
                    </div>
                    <div className="flex gap-3">
                        <div className="relative flex items-center">
                            <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-[#A3A3A3] pointer-events-none" />
                            <input
                                type="search"
                                placeholder="Buscar processo..."
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
                                <div className="absolute right-0 top-full mt-2 z-50 bg-[#171717] border border-[#333333] rounded-xl p-4 shadow-2xl w-72">
                                    <div className="flex items-center justify-between mb-3">
                                        <span className="text-xs font-bold text-white uppercase tracking-widest">Filtrar por Fase</span>
                                        {filtrosAtivos.length > 0 && (
                                            <button onClick={limparFiltros} className="text-[10px] text-red-400 hover:text-red-300 font-bold uppercase">
                                                Limpar
                                            </button>
                                        )}
                                    </div>
                                    <div className="flex flex-col gap-1.5">
                                        {FASES_DISPONIVEIS.map((fase) => (
                                            <button
                                                key={fase.value}
                                                onClick={() => toggleFiltro(fase.value)}
                                                className={`flex items-center gap-3 px-3 py-2 rounded-lg text-left text-xs font-medium transition-all ${
                                                    filtrosAtivos.includes(fase.value)
                                                        ? "bg-[#FACC15]/10 text-[#FACC15] border border-[#FACC15]/20"
                                                        : "text-[#A3A3A3] hover:bg-[#1F1F1F] hover:text-white"
                                                }`}
                                            >
                                                <span className={`h-2 w-2 rounded-full border ${filtrosAtivos.includes(fase.value) ? "bg-[#FACC15] border-[#FACC15]" : "border-[#525252]"}`} />
                                                {fase.label}
                                            </button>
                                        ))}
                                    </div>
                                </div>
                            )}
                        </div>
                        <Link
                            href="/novo-processo"
                            className="flex items-center justify-center gap-2 rounded-lg bg-[#FACC15] hover:bg-[#EAB308] transition-colors px-6 py-2.5 text-black font-bold text-sm shadow-[0_0_15px_rgba(250,204,21,0.15)]"
                        >
                            <Plus className="h-4 w-4" />
                            Novo Processo
                        </Link>
                    </div>
                </div>

                {/* Filtros ativos (chips) */}
                {filtrosAtivos.length > 0 && (
                    <div className="flex items-center gap-2 flex-wrap">
                        <span className="text-[10px] font-bold text-[#A3A3A3] uppercase tracking-widest">Ativos:</span>
                        {filtrosAtivos.map((fase) => (
                            <button
                                key={fase}
                                onClick={() => toggleFiltro(fase)}
                                className="flex items-center gap-1.5 px-3 py-1 rounded-full bg-[#FACC15]/10 text-[#FACC15] border border-[#FACC15]/20 text-[10px] font-bold hover:bg-[#FACC15]/20 transition-colors"
                            >
                                {faseLabel(fase)}
                                <X className="h-3 w-3" />
                            </button>
                        ))}
                    </div>
                )}

                {/* Stats Cards */}
                <div className="grid gap-4 md:grid-cols-4">
                    <div className="bg-[#171717] border border-[#333333] p-6 rounded-xl">
                        <div className="flex items-center gap-3">
                            <div className="h-10 w-10 rounded-lg bg-[#FACC15]/10 flex items-center justify-center">
                                <FileText className="text-[#FACC15] h-5 w-5" />
                            </div>
                            <div>
                                <p className="text-[#A3A3A3] text-sm">Total de Processos</p>
                                <p className="text-2xl font-bold text-white">{processosFiltrados.length}</p>
                            </div>
                        </div>
                    </div>
                    <div className="bg-[#171717] border border-[#333333] p-6 rounded-xl">
                        <div className="flex items-center gap-3">
                            <div className="h-10 w-10 rounded-lg bg-yellow-500/10 flex items-center justify-center">
                                <FileText className="text-yellow-400 h-5 w-5" />
                            </div>
                            <div>
                                <p className="text-[#A3A3A3] text-sm">Em Documentação</p>
                                <p className="text-2xl font-bold text-white">{processosFiltrados.filter(p => p.fase_kanban === 'DOCUMENTACAO' || p.fase_kanban === 'DOC_PENDENTE').length}</p>
                            </div>
                        </div>
                    </div>
                    <div className="bg-[#171717] border border-[#333333] p-6 rounded-xl">
                        <div className="flex items-center gap-3">
                            <div className="h-10 w-10 rounded-lg bg-[#FACC15]/10 flex items-center justify-center">
                                <Clock className="text-[#FACC15] h-5 w-5" />
                            </div>
                            <div>
                                <p className="text-[#A3A3A3] text-sm">Pronto para Protocolo</p>
                                <p className="text-2xl font-bold text-white">{processosFiltrados.filter(p => p.fase_kanban === 'PRONTO_PROTOCOLO').length}</p>
                            </div>
                        </div>
                    </div>
                    <div className="bg-[#171717] border border-[#333333] p-6 rounded-xl">
                        <div className="flex items-center gap-3">
                            <div className="h-10 w-10 rounded-lg bg-green-500/10 flex items-center justify-center">
                                <FileText className="text-green-400 h-5 w-5" />
                            </div>
                            <div>
                                <p className="text-[#A3A3A3] text-sm">Finalizados</p>
                                <p className="text-2xl font-bold text-white">{processosFiltrados.filter(p => p.fase_kanban === 'PROCESSO_FINALIZADO').length}</p>
                            </div>
                        </div>
                    </div>
                </div>

                {/* Tabela de Processos */}
                <div className="bg-[#171717] border border-[#333333] rounded-xl overflow-hidden">
                    {carregando ? (
                        <div className="flex items-center justify-center py-20">
                            <Loader2 className="h-8 w-8 text-[#FACC15] animate-spin" />
                            <span className="ml-3 text-[#A3A3A3]">Carregando processos...</span>
                        </div>
                    ) : (
                        <table className="min-w-full divide-y divide-[#333333]">
                            <thead>
                                <tr className="bg-[#1F1F1F]/50">
                                    <th className="px-6 py-4 text-left text-xs font-semibold text-[#A3A3A3] uppercase tracking-wider">Processo</th>
                                    <th className="px-6 py-4 text-left text-xs font-semibold text-[#A3A3A3] uppercase tracking-wider">Cliente</th>
                                    <th className="px-6 py-4 text-left text-xs font-semibold text-[#A3A3A3] uppercase tracking-wider">Tipo</th>
                                    <th className="px-6 py-4 text-left text-xs font-semibold text-[#A3A3A3] uppercase tracking-wider">Status</th>
                                    <th className="px-6 py-4 text-left text-xs font-semibold text-[#A3A3A3] uppercase tracking-wider">Dias</th>
                                    <th className="px-6 py-4 text-left text-xs font-semibold text-[#A3A3A3] uppercase tracking-wider">Ações</th>
                                </tr>
                            </thead>
                            <tbody className="divide-y divide-[#333333]">
                                {processosFiltrados.map((processo) => (
                                    <tr key={processo.id} className="hover:bg-[#1F1F1F]/50 transition-colors group">
                                        <td className="px-6 py-4 whitespace-nowrap">
                                            <div className="flex items-center gap-2">
                                                <span className="text-sm font-bold text-white font-mono">{processo.numero_processo || processo.id.slice(0, 8)}</span>
                                                {processo.urgencia && (
                                                    <span className="flex h-2 w-2 rounded-full bg-red-500 shadow-[0_0_8px_rgba(239,68,68,0.8)] animate-pulse" />
                                                )}
                                            </div>
                                        </td>
                                        <td className="px-6 py-4 whitespace-nowrap">
                                            <div>
                                                <p className="text-sm font-bold text-white group-hover:text-[#FACC15] transition-colors">{processo.cliente?.nome_completo || '—'}</p>
                                                <p className="text-xs text-[#A3A3A3] font-mono">{processo.cliente?.cpf || '—'}</p>
                                            </div>
                                        </td>
                                        <td className="px-6 py-4 whitespace-nowrap text-sm text-white">
                                            {beneficioLabel(processo.tipo_beneficio)}
                                        </td>
                                        <td className="px-6 py-4 whitespace-nowrap">
                                            <span className={`px-3 py-1 rounded text-xs font-bold border ${faseColor(processo.fase_kanban)}`}>
                                                {faseLabel(processo.fase_kanban)}
                                            </span>
                                        </td>
                                        <td className="px-6 py-4 whitespace-nowrap">
                                            <div className="flex items-center gap-1">
                                                <Clock className="h-4 w-4 text-[#A3A3A3]" />
                                                <span className={`text-sm font-bold ${processo.dias_na_fase > 10 ? 'text-red-400' : 'text-white'}`}>
                                                    {processo.dias_na_fase}d
                                                </span>
                                            </div>
                                        </td>
                                        <td className="px-6 py-4 whitespace-nowrap">
                                            <div className="flex items-center gap-2">
                                                <Link
                                                    href={`/processo/${processo.id}`}
                                                    className="p-2 rounded bg-[#262626] hover:bg-[#FACC15] hover:text-black transition-colors"
                                                    title="Ver processo"
                                                >
                                                    <Eye className="h-4 w-4" />
                                                </Link>
                                                <button
                                                    className="p-2 rounded bg-[#262626] hover:bg-[#FACC15] hover:text-black transition-colors"
                                                    title="Editar"
                                                >
                                                    <Edit className="h-4 w-4" />
                                                </button>
                                                <button
                                                    onClick={() => handleDeleteProcesso(processo.id)}
                                                    disabled={deletandoId === processo.id}
                                                    className="p-2 rounded bg-[#262626] hover:bg-red-500 hover:text-white disabled:opacity-50 transition-colors"
                                                    title="Apagar processo"
                                                >
                                                    {deletandoId === processo.id ? <Loader2 className="h-4 w-4 animate-spin" /> : <Trash2 className="h-4 w-4" />}
                                                </button>
                                            </div>
                                        </td>
                                    </tr>
                                ))}
                                {processosFiltrados.length === 0 && (
                                    <tr>
                                        <td colSpan={6} className="px-6 py-12 text-center text-[#A3A3A3] text-sm">
                                            Nenhum processo encontrado. Clique em &quot;Novo Processo&quot; para começar.
                                        </td>
                                    </tr>
                                )}
                            </tbody>
                        </table>
                    )}
                    <div className="bg-[#1F1F1F]/30 px-6 py-3 border-t border-[#333333]">
                        <p className="text-xs text-[#A3A3A3]">
                            Mostrando {processosFiltrados.length} de {processos.length} processos
                        </p>
                    </div>
                </div>
            </div>
        </DashboardLayout>
    )
}
