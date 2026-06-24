import * as React from "react"
import { cva, type VariantProps } from "class-variance-authority"
import { Slot } from "radix-ui"

import { cn } from "@/lib/utils"
import { Skeleton } from "@/components/ui/skeleton"
import { Tooltip, TooltipContent, TooltipTrigger } from "@/components/ui/tooltip"
import { type SidebarSkeletonStyle, useSidebar } from "@/components/ui/sidebar/context"

const sidebarMenuButtonVariants = cva(
	"peer/menu-button relative flex w-full items-center gap-(--control-gap) overflow-hidden rounded-[var(--sidebar-item-radius)] px-(--sidebar-item-padding-x) py-1 text-left text-sm text-sidebar-foreground/72 ring-sidebar-ring outline-hidden transition-[color,background-color,box-shadow,width,height,padding] before:absolute before:inset-y-1 before:left-0 before:w-(--sidebar-active-indicator-width) before:rounded-r-sm before:bg-transparent before:content-[''] group-has-data-[sidebar=menu-action]/menu-item:pr-8 group-data-[collapsible=icon]:mx-auto group-data-[collapsible=icon]:size-(--control-height)! group-data-[collapsible=icon]:justify-center group-data-[collapsible=icon]:p-0! group-data-[collapsible=icon]:before:hidden group-data-[collapsible=icon]:[&>span:not([data-slot=avatar])]:hidden hover:bg-sidebar-accent/65 hover:text-sidebar-accent-foreground hover:[&>svg]:text-sidebar-accent-foreground focus-visible:ring-[var(--focus-ring-width)] active:bg-sidebar-accent active:text-sidebar-accent-foreground disabled:pointer-events-none disabled:opacity-50 aria-disabled:pointer-events-none aria-disabled:opacity-50 data-[active=true]:bg-sidebar-accent/75 data-[active=true]:font-medium data-[active=true]:text-sidebar-accent-foreground data-[active=true]:shadow-none data-[active=true]:before:bg-sidebar-primary data-[active=true]:[&>svg]:text-sidebar-accent-foreground data-[state=open]:hover:bg-sidebar-accent data-[state=open]:hover:text-sidebar-accent-foreground [&>span:last-child]:truncate [&>svg]:size-(--sidebar-icon-size) [&>svg]:shrink-0 [&>svg]:text-sidebar-foreground/52",
	{
		variants: {
			variant: {
				default: "hover:bg-sidebar-accent/65 hover:text-sidebar-accent-foreground",
				outline:
					"bg-sidebar shadow-sidebar-ring hover:bg-sidebar-accent hover:text-sidebar-accent-foreground hover:shadow-sidebar-ring-hover",
			},
			size: {
				default: "h-(--sidebar-item-height)",
				sm: "h-(--sidebar-item-height-sm) text-xs",
				lg: "h-[calc(var(--sidebar-item-height)+0.625rem)] group-data-[collapsible=icon]:p-0!",
			},
		},
		defaultVariants: {
			variant: "default",
			size: "default",
		},
	}
)

function SidebarMenu({ className, ...props }: React.ComponentProps<"ul">) {
	return (
		<ul
			data-slot="sidebar-menu"
			data-sidebar="menu"
			className={cn("flex w-full min-w-0 flex-col gap-(--sidebar-menu-gap)", className)}
			{...props}
		/>
	)
}

function SidebarMenuItem({ className, ...props }: React.ComponentProps<"li">) {
	return (
		<li
			data-slot="sidebar-menu-item"
			data-sidebar="menu-item"
			className={cn("group/menu-item relative", className)}
			{...props}
		/>
	)
}

function SidebarMenuButton({
	asChild = false,
	isActive = false,
	variant = "default",
	size = "default",
	tooltip,
	className,
	...props
}: React.ComponentProps<"button"> & {
	asChild?: boolean
	isActive?: boolean
	tooltip?: string | React.ComponentProps<typeof TooltipContent>
} & VariantProps<typeof sidebarMenuButtonVariants>) {
	const Comp = asChild ? Slot.Root : "button"
	const { isMobile, state } = useSidebar()
	const buttonProps = asChild ? props : { type: "button" as const, ...props }
	const button = (
		<Comp
			data-slot="sidebar-menu-button"
			data-sidebar="menu-button"
			data-size={size}
			data-active={isActive}
			className={cn(sidebarMenuButtonVariants({ variant, size }), className)}
			{...buttonProps}
		/>
	)

	if (!tooltip) return button

	const tooltipProps = typeof tooltip === "string" ? { children: tooltip } : tooltip

	return (
		<Tooltip>
			<TooltipTrigger asChild>{button}</TooltipTrigger>
			<TooltipContent
				side="right"
				align="center"
				hidden={state !== "collapsed" || isMobile}
				{...tooltipProps}
			/>
		</Tooltip>
	)
}

function SidebarMenuAction({
	className,
	asChild = false,
	showOnHover = false,
	...props
}: React.ComponentProps<"button"> & {
	asChild?: boolean
	showOnHover?: boolean
}) {
	const Comp = asChild ? Slot.Root : "button"
	const buttonProps = asChild ? props : { type: "button" as const, ...props }

	return (
		<Comp
			data-slot="sidebar-menu-action"
			data-sidebar="menu-action"
			className={cn(
				"absolute top-0.5 right-0.5 flex size-(--sidebar-item-height-sm) items-center justify-center rounded-[var(--sidebar-item-radius)] p-0 text-sidebar-foreground/60 ring-sidebar-ring outline-hidden transition-colors peer-hover/menu-button:text-sidebar-accent-foreground hover:bg-sidebar-accent hover:text-sidebar-accent-foreground focus-visible:ring-[var(--focus-ring-width)] after:absolute after:-inset-2 md:after:hidden [&>svg]:size-(--sidebar-icon-size) [&>svg]:shrink-0",
				"peer-data-[size=sm]/menu-button:top-1",
				"peer-data-[size=default]/menu-button:top-1",
				"peer-data-[size=lg]/menu-button:top-2.5",
				"group-data-[collapsible=icon]:hidden",
				showOnHover &&
					"group-focus-within/menu-item:opacity-100 group-hover/menu-item:opacity-100 peer-data-[active=true]/menu-button:text-sidebar-accent-foreground data-[state=open]:opacity-100 md:opacity-0",
				className
			)}
			{...buttonProps}
		/>
	)
}

function SidebarMenuBadge({ className, ...props }: React.ComponentProps<"div">) {
	return (
		<div
			data-slot="sidebar-menu-badge"
			data-sidebar="menu-badge"
			className={cn(
				"pointer-events-none absolute right-1 flex h-(--sidebar-item-height-sm) min-w-(--sidebar-item-height-sm) items-center justify-center rounded-[var(--badge-radius)] px-(--badge-padding-x) text-meta text-sidebar-foreground/60 tabular-nums select-none",
				"peer-hover/menu-button:text-sidebar-accent-foreground peer-data-[active=true]/menu-button:text-sidebar-accent-foreground",
				"peer-data-[size=sm]/menu-button:top-1",
				"peer-data-[size=default]/menu-button:top-1",
				"peer-data-[size=lg]/menu-button:top-2.5",
				"group-data-[collapsible=icon]:hidden",
				className
			)}
			{...props}
		/>
	)
}

function SidebarMenuSkeleton({
	className,
	showIcon = false,
	...props
}: React.ComponentProps<"div"> & {
	showIcon?: boolean
}) {
	const width = React.useMemo(() => `${Math.floor(Math.random() * 40) + 50}%`, [])
	const skeletonStyle = React.useMemo<SidebarSkeletonStyle>(
		() => ({ "--skeleton-width": width }),
		[width]
	)

	return (
		<div
			data-slot="sidebar-menu-skeleton"
			data-sidebar="menu-skeleton"
			className={cn(
				"flex h-(--sidebar-item-height) items-center gap-(--control-gap) rounded-[var(--sidebar-item-radius)] px-(--sidebar-item-padding-x)",
				className
			)}
			{...props}
		>
			{showIcon && (
				<Skeleton
					className="size-(--sidebar-icon-size) rounded-[var(--sidebar-item-radius)]"
					data-sidebar="menu-skeleton-icon"
				/>
			)}
			<Skeleton
				className="h-4 max-w-(--skeleton-width) flex-1"
				data-sidebar="menu-skeleton-text"
				style={skeletonStyle}
			/>
		</div>
	)
}

function SidebarMenuSub({ className, ...props }: React.ComponentProps<"ul">) {
	return (
		<ul
			data-slot="sidebar-menu-sub"
			data-sidebar="menu-sub"
			className={cn(
				"ml-(--sidebar-nested-indent) flex min-w-0 flex-col gap-(--sidebar-menu-gap) border-l border-sidebar-border/80 py-0.5 pl-(--sidebar-item-padding-x)",
				"group-data-[collapsible=icon]:hidden",
				className
			)}
			{...props}
		/>
	)
}

function SidebarMenuSubItem({ className, ...props }: React.ComponentProps<"li">) {
	return (
		<li
			data-slot="sidebar-menu-sub-item"
			data-sidebar="menu-sub-item"
			className={cn("group/menu-sub-item relative", className)}
			{...props}
		/>
	)
}

function SidebarMenuSubButton({
	asChild = false,
	size = "md",
	isActive = false,
	className,
	...props
}: React.ComponentProps<"a"> & {
	asChild?: boolean
	size?: "sm" | "md"
	isActive?: boolean
}) {
	const Comp = asChild ? Slot.Root : "a"

	return (
		<Comp
			data-slot="sidebar-menu-sub-button"
			data-sidebar="menu-sub-button"
			data-size={size}
			data-active={isActive}
			className={cn(
				"relative flex h-(--sidebar-sub-item-height) min-w-0 items-center gap-(--control-gap) overflow-hidden rounded-[var(--sidebar-item-radius)] px-(--sidebar-item-padding-x) text-sidebar-foreground/65 ring-sidebar-ring outline-hidden transition-[color,background-color,box-shadow] hover:bg-sidebar-accent/70 hover:text-sidebar-accent-foreground hover:[&>svg]:text-sidebar-accent-foreground focus-visible:ring-[var(--focus-ring-width)] active:bg-sidebar-accent active:text-sidebar-accent-foreground disabled:pointer-events-none disabled:opacity-50 aria-disabled:pointer-events-none aria-disabled:opacity-50 data-[active=true]:bg-transparent data-[active=true]:font-medium data-[active=true]:text-sidebar-accent-foreground data-[active=true]:shadow-none data-[active=true]:[&>svg]:text-sidebar-accent-foreground [&>span:last-child]:truncate [&>svg]:size-(--sidebar-icon-size) [&>svg]:shrink-0 [&>svg]:text-sidebar-foreground/45",
				size === "sm" && "text-xs",
				size === "md" && "text-sm",
				"group-data-[collapsible=icon]:hidden",
				className
			)}
			{...props}
		/>
	)
}

export {
	SidebarMenu,
	SidebarMenuAction,
	SidebarMenuBadge,
	SidebarMenuButton,
	SidebarMenuItem,
	SidebarMenuSkeleton,
	SidebarMenuSub,
	SidebarMenuSubButton,
	SidebarMenuSubItem,
}
