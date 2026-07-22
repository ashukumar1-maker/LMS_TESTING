import { ClipboardListIcon, FileSpreadsheetIcon } from "lucide-react"
import { Link } from "react-router-dom"

import { HrDashboardPage } from "@/components/app/HrDashboardPage"
import { SidebarAccountMenu } from "@/components/ui/sidebar-account-menu"
import {
	Sidebar,
	SidebarContent,
	SidebarFooter,
	SidebarHeader,
	SidebarInset,
	SidebarMenu,
	SidebarMenuButton,
	SidebarMenuItem,
	SidebarProvider,
	SidebarTrigger,
} from "@/components/ui/sidebar"
import type { SidebarProviderStyle } from "@/components/ui/sidebar/context"
import { useTheme } from "@/contexts"
import { useAuth } from "@/hooks/useAuth"
import { useSignOut } from "@/hooks/useSignOut"

const sidebarStyle: SidebarProviderStyle = {
	"--sidebar-width": "15.5rem",
	"--sidebar-width-icon": "3rem",
}

function AppShell() {
	return (
		<SidebarProvider className="bg-background" style={sidebarStyle}>
			<AppSidebar />
			<SidebarInset className="min-h-svh">
				<HrDashboardPage />
			</SidebarInset>
		</SidebarProvider>
	)
}

function AppSidebar() {
	return (
		<Sidebar collapsible="icon" expandOnCollapsedBlankClick>
			<SidebarHeader className="gap-3">
				<SidebarBrand />
				<ExampleNavItem />
			</SidebarHeader>
			<SidebarContent />
			<SidebarFooter>
				<AppSidebarAccountMenu />
			</SidebarFooter>
		</Sidebar>
	)
}

function AppSidebarAccountMenu() {
	const { currentUser } = useAuth()
	const signOut = useSignOut()
	const theme = useTheme()

	return (
		<SidebarAccountMenu
			className="group-data-[collapsible=icon]:items-center"
			email={currentUser?.email}
			imageUrl={currentUser?.photoURL}
			isSigningOut={signOut.isPending}
			onSignOut={() => signOut.mutate()}
			onThemeModeChange={theme.setMode}
			themeMode={theme.mode}
			username={currentUser?.displayName}
		/>
	)
}

function SidebarBrand() {
	return (
		<div className="flex h-10 items-center gap-2 group-data-[collapsible=icon]:h-16 group-data-[collapsible=icon]:justify-center">
			<CollapsedIcon />
			<ExpandedLogoLockup />
			<SidebarTrigger className="size-7 group-data-[collapsible=icon]:hidden" />
		</div>
	)
}

function ExpandedLogoLockup() {
	return (
		<span className="flex min-w-0 flex-1 items-center gap-1.5 group-data-[collapsible=icon]:hidden">
			<img alt="" className="size-7 shrink-0 dark:hidden" src="/ciridae-icon-black.png" />
			<img alt="" className="hidden size-7 shrink-0 dark:block" src="/ciridae-icon-white.png" />
			<img
				alt="Ciridae"
				className="h-3.5 w-auto max-w-[9.5rem] dark:hidden"
				src="/ciridae-wordmark-black.png"
			/>
			<img
				alt="Ciridae"
				className="hidden h-3.5 w-auto max-w-[9.5rem] dark:block"
				src="/ciridae-wordmark-white.png"
			/>
		</span>
	)
}

function CollapsedIcon() {
	return (
		<span className="hidden shrink-0 items-center justify-center rounded-[var(--sidebar-item-radius)] group-data-[collapsible=icon]:flex">
			<img alt="" className="h-8 w-auto dark:hidden" src="/ciridae-icon-black.png" />
			<img alt="" className="hidden h-8 w-auto dark:block" src="/ciridae-icon-white.png" />
		</span>
	)
}

function ExampleNavItem() {
	return (
		<SidebarMenu className="group-data-[collapsible=icon]:items-center">
			<SidebarMenuItem>
				<SidebarMenuButton asChild isActive tooltip="HR Dashboard">
					<Link to="/app">
						<FileSpreadsheetIcon />
						<span>HR Dashboard</span>
					</Link>
				</SidebarMenuButton>
			</SidebarMenuItem>
			<SidebarMenuItem>
				<SidebarMenuButton asChild tooltip="TNA Form">
					<a href="/tna" target="_blank" rel="noopener noreferrer">
						<ClipboardListIcon />
						<span>TNA Form</span>
					</a>
				</SidebarMenuButton>
			</SidebarMenuItem>
		</SidebarMenu>
	)
}

export default AppShell
