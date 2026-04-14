"use client"

import { useState, useEffect } from "react"
import { useRouter } from "next/navigation"
import { Loader2 } from "lucide-react"
import DashboardLayout from "@/components/layout/dashboard-layout"
import { DragDropContext, Droppable, Draggable, DropResult } from "@hello-pangea/dnd"
import { buscarProcessos, moverProcessoFase } from "@/lib/services/processos"
import type { Processo, FaseKanban } from "@/lib/types/database"
import { FASE_KANBAN_LABELS, FASE_KANBAN_COLORS, getTipoBeneficioLabel } from "@/lib/types/database"

const KANBAN_COLUMNS: { id: FaseKanban; title: string; highlight?: boolean; success?: boolean; warning?: boolean }[] = [
    { id: "NOVO_PROCESSO", title: "Novo Processo" },
    { id: "DOCUMENTACAO", title: "Documentação" },
    { id: "DOC_PENDENTE", title: "Documentação Pendente", warning: true },
    { id: "APROVACAO_GESTOR", title: "Aprovação Gestor" },
    { id: "PRONTO_PROTOCOLO", title: "Pronto para Protocolo", highlight: true },
    { id: "PETICIONADO", title: "Peticionado" },
    { id: "PENDENCIA", title: "Pendência" },
    { id: "PROCESSO_FINALIZADO", title: "Processo Finalizado", success: true },
]

export default function KanbanBoardPage() {
    const [isMounted, setIsMounted] = useState(false)
    const [processos, setProcessos] = useState<Processo[]>([])
    const [loading, setLoading] = useState(true)
    const router = useRouter()

    useEffect(() => {
        setIsMounted(true)

        async function carregarProcessos() {
            const { processos: data, error } = await buscarProcessos()
            if (!error && data) {
                setProcessos(data)
            }
            setLoading(false)
        }

        carregarProcessos()
    }, [])

    const onDragEnd = async (result: DropResult) => {
        const { destination, source, draggableId } = result
        if (!destination) return
        if (destination.droppableId === source.droppableId && destination.index === source.index) return

        const novaFase = destination.droppableId as FaseKanban

        // Optimistic update
        setProcessos((prev) =>
            prev.map((p) =>
                p.id === draggableId ? { ...p, fase_kanban: novaFase } : p
            )
        )

        // Persist to database
        const { error } = await moverProcessoFase(draggableId, novaFase)
        if (error) {
            // Revert on error
            setProcessos((prev) =>
                prev.map((p) =>
                    p.id === draggableId ? { ...p, fase_kanban: source.droppableId as FaseKanban } : p
                )
            )
        }
    }

    if (!isMounted) return null

    if (loading) {
        return (
            <DashboardLayout>
                <div className="flex flex-col h-full w-full px-12 py-10 overflow-hidden bg-[#0A0A0A] items-center justify-center">
                    <Loader2 className="h-8 w-8 animate-spin text-[#FACC15]" />
                    <p className="text-[#A3A3A3] mt-4 font-medium tracking-wide">Carregando processos...</p>
                </div>
            </DashboardLayout>
        )
    }

    return (
        <DashboardLayout>
            <div className="flex flex-col h-full w-full px-12 py-10 overflow-hidden bg-[#0A0A0A]">
                <div className="mb-8 shrink-0 flex items-center justify-between">
                    <div>
                        <h1 className="text-4xl font-black tracking-tighter text-white uppercase italic">Kanban</h1>
                        <p className="text-[#A3A3A3] mt-1 font-medium tracking-wide flex items-center gap-2">
                            <span className="h-2 w-2 rounded-full bg-green-500 animate-pulse" />
                            Sessão Ativa • <span className="text-white font-bold">{processos.length} Processos</span> em andamento
                        </p>
                    </div>
                </div>

                <DragDropContext onDragEnd={onDragEnd}>
                    <div className="flex-1 overflow-x-auto pb-6 scrollbar-thin scrollbar-thumb-[#333333] scrollbar-track-transparent">
                        <div className="flex gap-4 h-full min-w-max">
                            {KANBAN_COLUMNS.map((coluna) => {
                                const cardsDaColuna = processos.filter((p) => p.fase_kanban === coluna.id)

                                return (
                                    <div
                                        key={coluna.id}
                                        className={`flex flex-col w-80 shrink-0 rounded-xl border shadow-2xl ${
                                            coluna.success
                                                ? 'border-green-500/30 bg-[#171717]'
                                                : coluna.highlight
                                                    ? 'border-[#FACC15]/20 ring-1 ring-[#FACC15]/5 bg-[#171717]'
                                                    : coluna.warning
                                                        ? 'border-orange-500/30 bg-[#171717]'
                                                        : 'border-[#333333] bg-[#171717]'
                                        }`}
                                    >
                                        <div className="p-4 border-b border-[#333333] flex items-center justify-between bg-[#1F1F1F]/50 rounded-t-xl">
                                            <h3 className={`font-black text-[11px] uppercase tracking-[0.2em] ${
                                                coluna.success ? 'text-green-400' : coluna.highlight ? 'text-[#FACC15]' : coluna.warning ? 'text-orange-400' : 'text-white'
                                            }`}>
                                                {coluna.title}
                                            </h3>
                                            <span className={`px-2 py-0.5 rounded text-[10px] font-bold border ${
                                                coluna.success
                                                    ? 'bg-green-500/10 text-green-400 border-green-500/20'
                                                    : coluna.highlight
                                                        ? 'bg-[#FACC15]/10 text-[#FACC15] border-[#FACC15]/20'
                                                        : coluna.warning
                                                            ? 'bg-orange-500/10 text-orange-400 border-orange-500/20'
                                                            : 'bg-[#0A0A0A] text-[#FACC15] border-[#333333]'
                                            }`}>
                                                {cardsDaColuna.length}
                                            </span>
                                        </div>

                                        <Droppable droppableId={coluna.id}>
                                            {(provided, snapshot) => (
                                                <div
                                                    ref={provided.innerRef}
                                                    {...provided.droppableProps}
                                                    className={`flex-1 p-4 overflow-y-auto flex flex-col gap-4 transition-all ${snapshot.isDraggingOver ? 'bg-[#FACC15]/5' : ''}`}
                                                >
                                                    {cardsDaColuna.map((processo, index) => (
                                                        <Draggable key={processo.id} draggableId={processo.id} index={index}>
                                                            {(provided, snapshot) => (
                                                                <div
                                                                    ref={provided.innerRef}
                                                                    {...provided.draggableProps}
                                                                    {...provided.dragHandleProps}
                                                                    onClick={() => router.push(`/processo/${processo.id}`)}
                                                                    className={`bg-[#1F1F1F] p-5 rounded-lg border ${processo.urgencia ? 'border-red-500/50 shadow-[0_0_15px_rgba(239,68,68,0.1)]' : 'border-[#333333]'
                                                                        } hover:border-[#FACC15]/40 transition-all group cursor-pointer ${snapshot.isDragging ? 'shadow-2xl ring-2 ring-[#FACC15] z-50 scale-105' : ''
                                                                        }`}
                                                                    style={{
                                                                        ...provided.draggableProps.style,
                                                                    }}
                                                                >
                                                                    <div className="flex justify-between items-start mb-3">
                                                                        <span className="text-[10px] font-black text-[#A3A3A3] tracking-widest group-hover:text-[#FACC15] transition-colors">
                                                                            {processo.numero_processo || processo.id.substring(0, 8).toUpperCase()}
                                                                        </span>
                                                                        {processo.urgencia && (
                                                                            <span className="flex h-2 w-2 rounded-full bg-red-500 shadow-[0_0_8px_rgba(239,68,68,0.8)] animate-pulse" />
                                                                        )}
                                                                    </div>
                                                                    <h4 className="font-bold text-white text-base mb-1 tracking-tight">{processo.cliente?.nome_completo || 'Cliente não informado'}</h4>
                                                                    <p className="text-xs text-[#A3A3A3] mb-4 font-medium uppercase tracking-tighter">{getTipoBeneficioLabel(processo.tipo_beneficio)}</p>

                                                                    {processo.observacoes && (
                                                                        <div className="mb-4 p-2 bg-[#0A0A0A] rounded border border-[#333333] text-[10px] text-[#A3A3A3] leading-relaxed">
                                                                            <span className="font-bold text-[#FACC15] mr-1">INFO:</span> {processo.observacoes}
                                                                        </div>
                                                                    )}

                                                                    <div className="flex items-center justify-between mt-2 pt-3 border-t border-[#333333]/50">
                                                                        <div className="flex items-center gap-1">
                                                                            <span className="material-symbols-outlined text-[14px] text-[#A3A3A3]">schedule</span>
                                                                            <span className="text-[10px] font-bold text-[#A3A3A3]">
                                                                                {processo.dias_na_fase}D
                                                                            </span>
                                                                        </div>
                                                                        <button className="h-6 w-6 rounded flex items-center justify-center bg-[#262626] hover:bg-[#FACC15] hover:text-black mt-1 transition-colors">
                                                                            <span className="material-symbols-outlined text-[16px]">more_vert</span>
                                                                        </button>
                                                                    </div>
                                                                </div>
                                                            )}
                                                        </Draggable>
                                                    ))}
                                                    {provided.placeholder}
                                                </div>
                                            )}
                                        </Droppable>
                                    </div>
                                )
                            })}
                        </div>
                    </div>
                </DragDropContext>
            </div>
        </DashboardLayout>
    )
}
