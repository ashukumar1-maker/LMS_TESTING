import * as React from "react"

export const SIDEBAR_STORAGE_KEY = "sidebar_state"
export const SIDEBAR_WIDTH = "14rem"
export const SIDEBAR_WIDTH_MOBILE = "18rem"
export const SIDEBAR_WIDTH_ICON = "3rem"
export const SIDEBAR_KEYBOARD_SHORTCUT = "b"

export type SidebarContextProps = {
	state: "expanded" | "collapsed"
	open: boolean
	setOpen: (open: boolean) => void
	openMobile: boolean
	setOpenMobile: (open: boolean) => void
	isMobile: boolean
	toggleSidebar: () => void
}

export type SidebarProviderStyle = React.CSSProperties &
	Record<"--sidebar-width" | "--sidebar-width-icon", string>
export type SidebarMobileStyle = React.CSSProperties & Record<"--sidebar-width", string>
export type SidebarSkeletonStyle = React.CSSProperties & Record<"--skeleton-width", string>

export const SidebarContext = React.createContext<SidebarContextProps | null>(null)

export function useSidebar() {
	const context = React.useContext(SidebarContext)
	if (!context) {
		throw new Error("useSidebar must be used within a SidebarProvider.")
	}

	return context
}
