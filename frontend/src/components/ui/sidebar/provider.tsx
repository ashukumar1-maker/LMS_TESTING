import * as React from "react"
import posthog from "posthog-js"

import { useIsMobile } from "@/hooks/use-mobile"
import { cn } from "@/lib/utils"
import { TooltipProvider } from "@/components/ui/tooltip"
import {
	SIDEBAR_KEYBOARD_SHORTCUT,
	SIDEBAR_STORAGE_KEY,
	SIDEBAR_WIDTH,
	SIDEBAR_WIDTH_ICON,
	SidebarContext,
	type SidebarContextProps,
	type SidebarProviderStyle,
} from "@/components/ui/sidebar/context"

function SidebarProvider({
	defaultOpen = true,
	open: openProp,
	onOpenChange: setOpenProp,
	className,
	style,
	children,
	...props
}: React.ComponentProps<"div"> & {
	defaultOpen?: boolean
	open?: boolean
	onOpenChange?: (open: boolean) => void
}) {
	const isMobile = useIsMobile()
	const [openMobile, setOpenMobile] = React.useState(false)
	const [_open, _setOpen] = React.useState(() => readStoredOpenState(defaultOpen))
	const open = openProp ?? _open

	const setOpen = React.useCallback(
		(value: boolean | ((value: boolean) => boolean)) => {
			const openState = typeof value === "function" ? value(open) : value
			if (setOpenProp) {
				setOpenProp(openState)
			} else {
				_setOpen(openState)
			}

			writeStoredOpenState(openState)
			captureSidebarToggle(openState, "desktop")
		},
		[setOpenProp, open]
	)

	const setOpenMobileTracked = React.useCallback(
		(value: boolean | ((value: boolean) => boolean)) => {
			setOpenMobile((currentOpen) => {
				const openState = typeof value === "function" ? value(currentOpen) : value
				captureSidebarToggle(openState, "mobile")
				return openState
			})
		},
		[]
	)

	const toggleSidebar = React.useCallback(
		() => (isMobile ? setOpenMobileTracked((open) => !open) : setOpen((open) => !open)),
		[isMobile, setOpen, setOpenMobileTracked]
	)

	const state = open ? "expanded" : "collapsed"

	const contextValue = React.useMemo<SidebarContextProps>(
		() => ({
			state,
			open,
			setOpen,
			isMobile,
			openMobile,
			setOpenMobile: setOpenMobileTracked,
			toggleSidebar,
		}),
		[state, open, setOpen, isMobile, openMobile, setOpenMobileTracked, toggleSidebar]
	)

	const sidebarStyle: SidebarProviderStyle = {
		"--sidebar-width": SIDEBAR_WIDTH,
		"--sidebar-width-icon": SIDEBAR_WIDTH_ICON,
		...style,
	}

	return (
		<SidebarProviderFrame
			className={className}
			contextValue={contextValue}
			onSidebarShortcut={toggleSidebar}
			sidebarStyle={sidebarStyle}
			{...props}
		>
			{children}
		</SidebarProviderFrame>
	)
}

function captureSidebarToggle(openState: boolean, context: "desktop" | "mobile") {
	posthog.capture("sidebar_toggled", {
		open: openState,
		context,
	})
}

function SidebarProviderFrame({
	children,
	className,
	contextValue,
	onSidebarShortcut,
	sidebarStyle,
	...props
}: React.ComponentProps<"div"> & {
	contextValue: SidebarContextProps
	onSidebarShortcut: () => void
	sidebarStyle: SidebarProviderStyle
}) {
	const handleKeyDown = (event: React.KeyboardEvent<HTMLDivElement>) => {
		if (event.defaultPrevented) return
		if (event.key !== SIDEBAR_KEYBOARD_SHORTCUT || (!event.metaKey && !event.ctrlKey)) return
		if (isEditableShortcutTarget(event.target)) return

		event.preventDefault()
		onSidebarShortcut()
	}

	return (
		<SidebarContext.Provider value={contextValue}>
			<TooltipProvider delayDuration={0}>
				<div
					data-slot="sidebar-wrapper"
					onKeyDown={handleKeyDown}
					style={sidebarStyle}
					tabIndex={-1}
					className={cn(
						"group/sidebar-wrapper flex min-h-svh w-full has-data-[variant=inset]:bg-sidebar",
						className
					)}
					{...props}
				>
					{children}
				</div>
			</TooltipProvider>
		</SidebarContext.Provider>
	)
}

function readStoredOpenState(defaultOpen: boolean) {
	if (typeof window === "undefined") return defaultOpen

	try {
		const storedValue = window.localStorage.getItem(SIDEBAR_STORAGE_KEY)
		if (storedValue === "true") return true
		if (storedValue === "false") return false
	} catch {
		return defaultOpen
	}

	return defaultOpen
}

function writeStoredOpenState(openState: boolean) {
	if (typeof window === "undefined") return

	try {
		window.localStorage.setItem(SIDEBAR_STORAGE_KEY, String(openState))
	} catch {
		// Ignore storage failures from private browsing or restricted environments.
	}
}

function isEditableShortcutTarget(target: EventTarget) {
	return (
		target instanceof HTMLElement &&
		Boolean(target.closest("input,textarea,select,[contenteditable='true'],[role='textbox']"))
	)
}

export { SidebarProvider }
