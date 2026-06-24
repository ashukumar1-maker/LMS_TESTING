import * as React from "react"
import { Slot } from "radix-ui"

import { cn } from "@/lib/utils"

function SidebarGroup({ className, ...props }: React.ComponentProps<"div">) {
	return (
		<div
			data-slot="sidebar-group"
			data-sidebar="group"
			className={cn(
				"relative flex w-full min-w-0 flex-col gap-(--sidebar-group-gap) p-(--sidebar-group-padding)",
				className
			)}
			{...props}
		/>
	)
}

function SidebarGroupLabel({
	className,
	asChild = false,
	...props
}: React.ComponentProps<"div"> & { asChild?: boolean }) {
	const Comp = asChild ? Slot.Root : "div"

	return (
		<Comp
			data-slot="sidebar-group-label"
			data-sidebar="group-label"
			className={cn(
				"flex h-(--sidebar-item-height-sm) shrink-0 items-center rounded-[var(--sidebar-item-radius)] px-(--sidebar-item-padding-x) text-meta text-sidebar-foreground/45 ring-sidebar-ring outline-hidden transition-[margin,opacity] duration-200 ease-linear focus-visible:ring-[var(--focus-ring-width)] [&>svg]:size-(--sidebar-icon-size) [&>svg]:shrink-0",
				"group-data-[collapsible=icon]:-mt-8 group-data-[collapsible=icon]:opacity-0",
				className
			)}
			{...props}
		/>
	)
}

function SidebarGroupAction({
	className,
	asChild = false,
	...props
}: React.ComponentProps<"button"> & { asChild?: boolean }) {
	const Comp = asChild ? Slot.Root : "button"

	return (
		<Comp
			data-slot="sidebar-group-action"
			data-sidebar="group-action"
			className={cn(
				"absolute top-(--sidebar-group-padding) right-(--sidebar-group-padding) flex size-(--sidebar-item-height-sm) items-center justify-center rounded-[var(--sidebar-item-radius)] p-0 text-sidebar-foreground/70 ring-sidebar-ring outline-hidden transition-colors hover:bg-sidebar-accent hover:text-sidebar-accent-foreground focus-visible:ring-[var(--focus-ring-width)] after:absolute after:-inset-2 md:after:hidden [&>svg]:size-(--sidebar-icon-size) [&>svg]:shrink-0",
				"group-data-[collapsible=icon]:hidden",
				className
			)}
			{...props}
		/>
	)
}

function SidebarGroupContent({ className, ...props }: React.ComponentProps<"div">) {
	return (
		<div
			data-slot="sidebar-group-content"
			data-sidebar="group-content"
			className={cn("w-full text-sm", className)}
			{...props}
		/>
	)
}

export { SidebarGroup, SidebarGroupAction, SidebarGroupContent, SidebarGroupLabel }
