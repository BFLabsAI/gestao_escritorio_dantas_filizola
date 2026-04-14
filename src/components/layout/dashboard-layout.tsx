import { SidebarProvider, SidebarTrigger, Sidebar, SidebarHeader, SidebarContent, SidebarGroup, SidebarMenu, SidebarMenuItem, SidebarMenuButton } from "@/components/ui/sidebar"
import { Search, Bell, LogOut, Settings } from "lucide-react"

export function AppSidebar() {
  return (
    <Sidebar variant="inset" className="border-r border-[#333333] bg-[#171717] w-72">
      <SidebarHeader className="h-20 flex flex-row items-center gap-3 px-6 border-b border-[#333333]">
        <div className="bg-[#FACC15]/20 aspect-square h-10 w-10 rounded-full flex items-center justify-center text-[#FACC15]">
          <span className="material-symbols-outlined">gavel</span>
        </div>
        <div className="flex flex-col">
          <h1 className="text-white text-lg font-bold leading-tight">D&F Gestão</h1>
          <p className="text-[#A3A3A3] text-xs font-normal">Advocacia Previdenciária</p>
        </div>
      </SidebarHeader>
      <SidebarContent className="px-4 py-6 flex flex-col gap-2 bg-[#171717]">
        <SidebarGroup>
          <SidebarMenu className="gap-2">
            <SidebarMenuItem>
              <SidebarMenuButton asChild tooltip="Dashboard" className="flex items-center gap-3 px-3 py-6 rounded-lg text-[#A3A3A3] hover:bg-[#262626] hover:text-white transition-colors group h-auto">
                <a href="/dashboard">
                  <span className="material-symbols-outlined text-2xl group-hover:text-[#FACC15] transition-colors">dashboard</span>
                  <span className="text-sm font-medium">Dashboard</span>
                </a>
              </SidebarMenuButton>
            </SidebarMenuItem>
            <SidebarMenuItem>
              <SidebarMenuButton asChild tooltip="Clientes" className="flex items-center gap-3 px-3 py-6 rounded-lg text-[#A3A3A3] hover:bg-[#262626] hover:text-white transition-colors group h-auto">
                <a href="/clientes">
                  <span className="material-symbols-outlined text-2xl group-hover:text-[#FACC15] transition-colors">group</span>
                  <span className="text-sm font-medium">Clientes</span>
                </a>
              </SidebarMenuButton>
            </SidebarMenuItem>
            <SidebarMenuItem>
              <SidebarMenuButton asChild tooltip="Processos" className="flex items-center gap-3 px-3 py-6 rounded-lg text-[#A3A3A3] hover:bg-[#262626] hover:text-white transition-colors group h-auto">
                <a href="/board">
                  <span className="material-symbols-outlined text-2xl group-hover:text-[#FACC15] transition-colors">description</span>
                  <span className="text-sm font-medium">Processos</span>
                </a>
              </SidebarMenuButton>
            </SidebarMenuItem>
            <SidebarMenuItem>
              <SidebarMenuButton asChild tooltip="Kanban" className="flex items-center gap-3 px-3 py-6 rounded-lg text-[#A3A3A3] hover:bg-[#262626] hover:text-white transition-colors group h-auto">
                <a href="/kanban">
                  <span className="material-symbols-outlined text-2xl group-hover:text-[#FACC15] transition-colors">view_kanban</span>
                  <span className="text-sm font-medium">Kanban</span>
                </a>
              </SidebarMenuButton>
            </SidebarMenuItem>
            <SidebarMenuItem>
              <SidebarMenuButton asChild tooltip="Petições" className="flex items-center gap-3 px-3 py-6 rounded-lg text-[#A3A3A3] hover:bg-[#262626] hover:text-white transition-colors group h-auto">
                <a href="/peticoes">
                  <span className="material-symbols-outlined text-2xl group-hover:text-[#FACC15] transition-colors">article</span>
                  <span className="text-sm font-medium">Petições</span>
                </a>
              </SidebarMenuButton>
            </SidebarMenuItem>
          </SidebarMenu>
        </SidebarGroup>
      </SidebarContent>

      <div className="p-4 border-t border-[#333333] bg-[#171717]">
        <SidebarMenuButton asChild className="flex items-center gap-3 px-3 py-3 rounded-lg text-[#A3A3A3] hover:bg-[#262626] hover:text-white transition-colors group h-auto">
          <a href="/settings">
            <span className="material-symbols-outlined text-2xl group-hover:text-[#FACC15] transition-colors">settings</span>
            <span className="text-sm font-medium">Configurações</span>
          </a>
        </SidebarMenuButton>
        <div className="mt-4 flex items-center gap-3 px-3">
          <div className="h-10 w-10 rounded-full bg-slate-800 border-2 border-[#FACC15]/30 flex items-center justify-center text-xs font-bold text-white">
            DR
          </div>
          <div className="flex flex-col">
            <span className="text-sm font-medium text-white">Dr. Ricardo</span>
            <span className="text-xs text-[#A3A3A3]">Sócio Senior</span>
          </div>
        </div>
      </div>
    </Sidebar>
  )
}

export default function DashboardLayout({ children }: { children: React.ReactNode }) {
  return (
    <SidebarProvider>
      <div className="flex min-h-screen w-full bg-[#0A0A0A] text-white">
        <AppSidebar />
        <main className="flex-1 flex flex-col h-screen overflow-hidden bg-[#0A0A0A]">
          {/* Header Compacto (Estilo Stitch) */}
          <header className="h-20 shrink-0 flex items-center justify-between border-b border-[#333333] px-8 bg-[#0A0A0A]">
            <div className="flex items-center gap-6">
              <SidebarTrigger className="text-[#A3A3A3] hover:text-white" />
              <div className="relative hidden md:flex items-center group">
                <Search className="absolute left-3 h-4 w-4 text-[#A3A3A3] group-focus-within:text-[#FACC15] transition-colors" />
                <input
                  type="search"
                  placeholder="Buscar CPF, Nome, Processo..."
                  className="h-10 w-80 rounded-lg border border-[#333333] bg-[#1F1F1F] pl-10 pr-4 text-sm outline-none focus:border-[#FACC15] focus:ring-1 focus:ring-[#FACC15] transition-all text-white placeholder:#A3A3A3"
                />
              </div>
            </div>
            <div className="flex items-center gap-4">
              <a href="/settings" className="p-2 text-[#A3A3A3] hover:text-[#FACC15] transition-colors" title="Configurações">
                <Settings className="h-5 w-5" />
              </a>
              <button className="relative p-2 text-[#A3A3A3] hover:text-white transition-colors">
                <Bell className="h-5 w-5" />
                <span className="absolute top-1.5 right-1.5 h-2 w-2 rounded-full bg-red-500 border border-[#0A0A0A]" />
              </button>
              <button className="p-2 text-[#A3A3A3] hover:text-white transition-colors">
                <LogOut className="h-5 w-5" />
              </button>
            </div>
          </header>

          {/* Main Workspace (Scrollável) */}
          <div className="flex-1 overflow-auto bg-[#0A0A0A]">
            {children}
          </div>
        </main>
      </div>
    </SidebarProvider>
  )
}
