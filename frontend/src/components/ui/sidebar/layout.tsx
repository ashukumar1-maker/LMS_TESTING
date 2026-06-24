import * as React from "react"

import { cn } from "@/lib/utils"
import { Input } from "@/components/ui/input"
import { Separator } from "@/components/ui/separator"
import {
	Sheet,
	SheetContent,
	SheetDescription,
	SheetHeader,
	SheetTitle,
} from "@/components/ui/sheet"
import {
	SIDEBAR_WIDTH_MOBILE,
	type SidebarMobileStyle,
	useSidebar,
} from "@/components/ui/sidebar/context"

type SidebarProps = React.ComponentProps<"div"> & {
	side?: "left" | "right"
	variant?: "sidebar" | "floating" | "inset"
	collapsible?: "offcanvas" | "icon" | "none"
	expandOnCollapsedBlankClick?: boolean
}

function Sidebar({
	side = "left",
	variant = "sidebar",
	collapsible = "offcanvas",
	expandOnCollapsedBlankClick = false,
	className,
	children,
	onClick,
	...props
}: SidebarProps) {
	const { isMobile, state, openMobile, setOpen, setOpenMobile } = useSidebar()

	if (collapsible === "none") {
		return (
			<SidebarStatic className={className} {...props}>
				{children}
			</SidebarStatic>
		)
	}

	if (isMobile) {
		return (
			<SidebarMobile
				open={openMobile}
				setOpen={setOpenMobile}
				side={side}
				onClick={onClick}
				{...props}
			>
				{children}
			</SidebarMobile>
		)
	}

	const handleDesktopClick = (event: React.MouseEvent<HTMLDivElement>) => {
		onClick?.(event)
		if (!expandOnCollapsedBlankClick || event.defaultPrevented) return
		if (state !== "collapsed" || collapsible !== "icon") return
		if (isInteractiveSidebarTarget(event.target)) return

		setOpen(true)
	}

	return (
		<SidebarDesktop
			className={className}
			collapsible={collapsible}
			expandOnCollapsedBlankClick={expandOnCollapsedBlankClick}
			onClick={handleDesktopClick}
			side={side}
			state={state}
			variant={variant}
			{...props}
		>
			{children}
		</SidebarDesktop>
	)
}

function SidebarStatic({ className, children, ...props }: React.ComponentProps<"div">) {
	return (
		<div
			data-slot="sidebar"
			className={cn(
				"flex h-full w-(--sidebar-width) flex-col bg-sidebar text-sidebar-foreground",
				className
			)}
			{...props}
		>
			{children}
		</div>
	)
}

function SidebarMobile({
	children,
	open,
	setOpen,
	side,
	...props
}: React.ComponentProps<"div"> & {
	open: boolean
	setOpen: (open: boolean) => void
	side: "left" | "right"
}) {
	const sidebarStyle = React.useMemo<SidebarMobileStyle>(
		() => ({ "--sidebar-width": SIDEBAR_WIDTH_MOBILE }),
		[]
	)

	return (
		<Sheet open={open} onOpenChange={setOpen} {...props}>
			<SheetContent
				data-sidebar="sidebar"
				data-slot="sidebar"
				data-mobile="true"
				className="w-(--sidebar-width) bg-sidebar p-0 text-sidebar-foreground [&>button]:hidden"
				style={sidebarStyle}
				side={side}
			>
				<SheetHeader className="sr-only">
					<SheetTitle>Sidebar</SheetTitle>
					<SheetDescription>Displays the mobile sidebar.</SheetDescription>
				</SheetHeader>
				<div className="flex h-full w-full flex-col">{children}</div>
			</SheetContent>
		</Sheet>
	)
}

function SidebarDesktop({
	className,
	children,
	collapsible,
	expandOnCollapsedBlankClick,
	side,
	state,
	variant,
	...props
}: React.ComponentProps<"div"> &
	Required<Pick<SidebarProps, "collapsible" | "side" | "variant">> & {
		expandOnCollapsedBlankClick: boolean
		state: "expanded" | "collapsed"
	}) {
	return (
		<div
			className="group peer hidden text-sidebar-foreground md:block"
			data-state={state}
			data-collapsible={state === "collapsed" ? collapsible : ""}
			data-variant={variant}
			data-side={side}
			data-slot="sidebar"
		>
			<SidebarGap variant={variant} />
			<div
				data-slot="sidebar-container"
				className={cn(
					"fixed inset-y-0 z-10 hidden h-svh w-(--sidebar-width) transition-[left,right,width] duration-200 ease-linear md:flex",
					side === "left"
						? "left-0 group-data-[collapsible=offcanvas]:left-[calc(var(--sidebar-width)*-1)]"
						: "right-0 group-data-[collapsible=offcanvas]:right-[calc(var(--sidebar-width)*-1)]",
					variant === "floating" || variant === "inset"
						? "p-2 group-data-[collapsible=icon]:w-[calc(var(--sidebar-width-icon)+(--spacing(4))+2px)]"
						: "border-sidebar-border group-data-[collapsible=icon]:w-(--sidebar-width-icon) group-data-[side=left]:border-r group-data-[side=right]:border-l",
					expandOnCollapsedBlankClick &&
						side === "left" &&
						"group-data-[collapsible=icon]:cursor-e-resize",
					expandOnCollapsedBlankClick &&
						side === "right" &&
						"group-data-[collapsible=icon]:cursor-w-resize",
					className
				)}
				{...props}
			>
				<div
					data-sidebar="sidebar"
					data-slot="sidebar-inner"
					className="flex h-full w-full flex-col bg-sidebar group-data-[variant=floating]:rounded-md group-data-[variant=floating]:border group-data-[variant=floating]:border-sidebar-border group-data-[variant=floating]:shadow-sm"
				>
					{children}
				</div>
			</div>
		</div>
	)
}

function isInteractiveSidebarTarget(target: EventTarget) {
	return (
		target instanceof Element &&
		Boolean(
			target.closest(
				"button,a,input,textarea,select,summary,[role='button'],[role='link'],[data-sidebar-no-expand]"
			)
		)
	)
}

function SidebarGap({ variant }: Required<Pick<SidebarProps, "variant">>) {
	return (
		<div
			data-slot="sidebar-gap"
			className={cn(
				"relative w-(--sidebar-width) bg-transparent transition-[width] duration-200 ease-linear",
				"group-data-[collapsible=offcanvas]:w-0",
				"group-data-[side=right]:rotate-180",
				variant === "floating" || variant === "inset"
					? "group-data-[collapsible=icon]:w-[calc(var(--sidebar-width-icon)+(--spacing(4)))]"
					: "group-data-[collapsible=icon]:w-(--sidebar-width-icon)"
			)}
		/>
	)
}

function SidebarInset({ className, ...props }: React.ComponentProps<"main">) {
	return (
		<main
			data-slot="sidebar-inset"
			className={cn(
				"relative flex w-full flex-1 flex-col bg-background",
				"md:peer-data-[variant=inset]:m-2 md:peer-data-[variant=inset]:ml-0 md:peer-data-[variant=inset]:rounded-lg md:peer-data-[variant=inset]:shadow-xs md:peer-data-[variant=inset]:peer-data-[state=collapsed]:ml-2",
				className
			)}
			{...props}
		/>
	)
}

function SidebarInput({ className, ...props }: React.ComponentProps<typeof Input>) {
	return (
		<Input
			data-slot="sidebar-input"
			data-sidebar="input"
			className={cn("h-8 w-full bg-background shadow-none", className)}
			{...props}
		/>
	)
}

function SidebarHeader({ className, ...props }: React.ComponentProps<"div">) {
	return (
		<div
			data-slot="sidebar-header"
			data-sidebar="header"
			className={cn("flex flex-col gap-(--sidebar-group-gap) p-(--sidebar-padding)", className)}
			{...props}
		/>
	)
}

function SidebarFooter({ className, ...props }: React.ComponentProps<"div">) {
	return (
		<div
			data-slot="sidebar-footer"
			data-sidebar="footer"
			className={cn("flex flex-col gap-(--sidebar-group-gap) p-(--sidebar-padding)", className)}
			{...props}
		/>
	)
}

function SidebarSeparator({ className, ...props }: React.ComponentProps<typeof Separator>) {
	return (
		<Separator
			data-slot="sidebar-separator"
			data-sidebar="separator"
			className={cn("mx-(--sidebar-padding) w-auto bg-sidebar-border", className)}
			{...props}
		/>
	)
}

function SidebarContent({ className, ...props }: React.ComponentProps<"div">) {
	return (
		<div
			data-slot="sidebar-content"
			data-sidebar="content"
			className={cn(
				"flex min-h-0 flex-1 flex-col gap-(--sidebar-content-gap) overflow-auto group-data-[collapsible=icon]:overflow-hidden",
				className
			)}
			{...props}
		/>
	)
}

export {
	Sidebar,
	SidebarContent,
	SidebarFooter,
	SidebarHeader,
	SidebarInput,
	SidebarInset,
	SidebarSeparator,
}
