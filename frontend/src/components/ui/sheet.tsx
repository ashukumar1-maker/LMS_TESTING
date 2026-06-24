"use client"

import * as React from "react"
import { XIcon } from "lucide-react"
import { Dialog as SheetPrimitive } from "radix-ui"

import { cn } from "@/lib/utils"

type SheetPortalContainerContextValue = {
	container: HTMLElement | null
	disableModalBehavior: boolean
}

const SheetPortalContainerContext = React.createContext<SheetPortalContainerContextValue>({
	container: null,
	disableModalBehavior: false,
})

function SheetPortalContainerProvider({
	children,
	container,
	disableModalBehavior = false,
}: {
	children: React.ReactNode
	container: HTMLElement | null
	disableModalBehavior?: boolean
}) {
	const value = React.useMemo(
		() => ({ container, disableModalBehavior }),
		[container, disableModalBehavior]
	)

	return (
		<SheetPortalContainerContext.Provider value={value}>
			{children}
		</SheetPortalContainerContext.Provider>
	)
}

function Sheet({ modal, ...props }: React.ComponentProps<typeof SheetPrimitive.Root>) {
	const { disableModalBehavior } = React.useContext(SheetPortalContainerContext)
	const resolvedModal = modal ?? (disableModalBehavior ? false : undefined)

	return <SheetPrimitive.Root data-slot="sheet" modal={resolvedModal} {...props} />
}

function SheetTrigger({ ...props }: React.ComponentProps<typeof SheetPrimitive.Trigger>) {
	return <SheetPrimitive.Trigger data-slot="sheet-trigger" {...props} />
}

function SheetClose({ ...props }: React.ComponentProps<typeof SheetPrimitive.Close>) {
	return <SheetPrimitive.Close data-slot="sheet-close" {...props} />
}

function SheetPortal({ container, ...props }: React.ComponentProps<typeof SheetPrimitive.Portal>) {
	const { container: contextualContainer } = React.useContext(SheetPortalContainerContext)

	return (
		<SheetPrimitive.Portal
			container={container ?? contextualContainer ?? undefined}
			data-slot="sheet-portal"
			{...props}
		/>
	)
}

function SheetOverlay({
	className,
	...props
}: React.ComponentProps<typeof SheetPrimitive.Overlay>) {
	return (
		<SheetPrimitive.Overlay
			data-slot="sheet-overlay"
			className={cn(
				"fixed inset-0 z-50 bg-overlay data-[state=closed]:animate-out data-[state=closed]:fade-out-0 data-[state=open]:animate-in data-[state=open]:fade-in-0",
				className
			)}
			{...props}
		/>
	)
}

function SheetContent({
	className,
	children,
	side = "right",
	showCloseButton = true,
	size = "sm",
	...props
}: React.ComponentProps<typeof SheetPrimitive.Content> & {
	size?: "sm" | "md" | "lg"
	side?: "top" | "right" | "bottom" | "left"
	showCloseButton?: boolean
}) {
	return (
		<SheetPortal>
			<SheetOverlay />
			<SheetPrimitive.Content
				data-slot="sheet-content"
				className={cn(
					"@container/sheet fixed z-50 flex flex-col overflow-hidden bg-background shadow-lg transition ease-in-out data-[state=closed]:animate-out data-[state=closed]:duration-300 data-[state=open]:animate-in data-[state=open]:duration-500",
					side === "right" &&
						cn(
							"inset-y-0 right-0 h-full w-full border-l data-[state=closed]:slide-out-to-right data-[state=open]:slide-in-from-right sm:w-3/4",
							getSheetSideSizeClass(size)
						),
					side === "left" &&
						cn(
							"inset-y-0 left-0 h-full w-full border-r data-[state=closed]:slide-out-to-left data-[state=open]:slide-in-from-left sm:w-3/4",
							getSheetSideSizeClass(size)
						),
					side === "top" &&
						"inset-x-0 top-0 h-auto border-b data-[state=closed]:slide-out-to-top data-[state=open]:slide-in-from-top",
					side === "bottom" &&
						"inset-x-0 bottom-0 h-auto border-t data-[state=closed]:slide-out-to-bottom data-[state=open]:slide-in-from-bottom",
					className
				)}
				{...props}
			>
				{children}
				{showCloseButton && (
					<SheetPrimitive.Close className="absolute top-4 right-4 rounded-xs opacity-70 ring-offset-background transition-opacity hover:opacity-100 focus:ring-[var(--focus-ring-width)] focus:ring-ring focus:ring-offset-2 focus:outline-hidden disabled:pointer-events-none data-[state=open]:bg-secondary">
						<XIcon className="size-4" />
						<span className="sr-only">Close</span>
					</SheetPrimitive.Close>
				)}
			</SheetPrimitive.Content>
		</SheetPortal>
	)
}

function SheetHeader({ className, ...props }: React.ComponentProps<"div">) {
	return (
		<div
			data-slot="sheet-header"
			className={cn("flex flex-col gap-1.5 p-(--panel-padding)", className)}
			{...props}
		/>
	)
}

function SheetBody({ className, ...props }: React.ComponentProps<"div">) {
	return (
		<div
			data-slot="sheet-body"
			className={cn("min-h-0 flex-1 overflow-y-auto px-(--panel-padding)", className)}
			{...props}
		/>
	)
}

function SheetFooter({ className, ...props }: React.ComponentProps<"div">) {
	return (
		<div
			data-slot="sheet-footer"
			className={cn(
				"mt-auto flex flex-col-reverse gap-2 border-t bg-background p-(--panel-padding)",
				"@md/sheet:flex-row @md/sheet:justify-end",
				"[&_[data-slot=button]]:w-full @md/sheet:[&_[data-slot=button]]:w-auto",
				className
			)}
			{...props}
		/>
	)
}

function SheetTitle({ className, ...props }: React.ComponentProps<typeof SheetPrimitive.Title>) {
	return (
		<SheetPrimitive.Title
			data-slot="sheet-title"
			className={cn("font-medium text-foreground", className)}
			{...props}
		/>
	)
}

function SheetDescription({
	className,
	...props
}: React.ComponentProps<typeof SheetPrimitive.Description>) {
	return (
		<SheetPrimitive.Description
			data-slot="sheet-description"
			className={cn("text-sm text-muted-foreground", className)}
			{...props}
		/>
	)
}

function getSheetSideSizeClass(size: "sm" | "md" | "lg") {
	if (size === "lg") return "sm:max-w-2xl"
	if (size === "md") return "sm:max-w-xl"

	return "sm:max-w-sm"
}

export {
	Sheet,
	SheetTrigger,
	SheetClose,
	SheetContent,
	SheetHeader,
	SheetBody,
	SheetFooter,
	SheetTitle,
	SheetDescription,
	SheetPortalContainerProvider,
}
