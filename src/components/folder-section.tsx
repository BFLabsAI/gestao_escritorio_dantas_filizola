"use client"

import { useState } from "react"
import { ChevronDown, ChevronRight } from "lucide-react"

interface FolderSectionProps {
    nome: string
    subfolder?: boolean
    defaultOpen?: boolean
    badge?: string
    children: React.ReactNode
}

export function FolderSection({
    nome,
    subfolder = false,
    defaultOpen = false,
    badge,
    children,
}: FolderSectionProps) {
    const [isOpen, setIsOpen] = useState(defaultOpen)

    const totalDocs = typeof badge === 'string' ? badge : ''

    return (
        <div className={subfolder ? "ml-4" : ""}>
            <button
                onClick={() => setIsOpen(!isOpen)}
                className={`w-full flex items-center gap-2 py-2 px-1 text-left hover:bg-[#1F1F1F]/50 rounded-lg transition-colors ${
                    subfolder ? "text-sm" : "text-sm font-medium"
                }`}
            >
                <span className={`material-symbols-outlined shrink-0 ${
                    isOpen
                        ? "text-[#FACC15]"
                        : subfolder
                          ? "text-[#A3A3A3]"
                          : "text-[#FACC15]"
                }`} style={{ fontSize: subfolder ? '18px' : '20px' }}>
                    {isOpen ? "folder_open" : "folder"}
                </span>
                <span className={`truncate ${subfolder ? "text-[#A3A3A3]" : "text-white"}`}>
                    {nome}
                </span>
                {totalDocs && (
                    <span className={`text-[10px] px-1.5 py-0.5 rounded-full font-medium shrink-0 ${
                        subfolder
                            ? "bg-[#333333] text-[#A3A3A3]"
                            : "bg-[#FACC15]/10 text-[#FACC15] border border-[#FACC15]/20"
                    }`}>
                        {totalDocs}
                    </span>
                )}
                {isOpen ? (
                    <ChevronDown className="h-3.5 w-3.5 text-[#525252] shrink-0 ml-auto" />
                ) : (
                    <ChevronRight className="h-3.5 w-3.5 text-[#525252] shrink-0 ml-auto" />
                )}
            </button>
            {isOpen && (
                <div className="space-y-1">
                    {children}
                </div>
            )}
        </div>
    )
}
