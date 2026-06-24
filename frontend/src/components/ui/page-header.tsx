import * as React from "react"
import { ArrowLeftIcon } from "lucide-react"

import { Button } from "@/components/ui/button"
import { cn } from "@/lib/utils"

function PageHeader({ className, ...props }: React.ComponentProps<"header">) {
	return (
		<header
			data-slot="page-header"
			className={cn("border-b bg-background text-foreground", className)}
			{...props}
		/>
	)
}

function PageHeaderMain({ className, ...props }: React.ComponentProps<"div">) {
	return (
		<div
			data-slot="page-header-main"
			className={cn(
				"flex flex-col gap-3 px-4 py-3 md:flex-row md:items-center md:justify-between md:px-6 lg:px-8",
				className
			)}
			{...props}
		/>
	)
}

function PageHeaderContent({ className, ...props }: React.ComponentProps<"div">) {
	return (
		<div
			data-slot="page-header-content"
			className={cn("flex min-w-0 max-w-3xl flex-col gap-1", className)}
			{...props}
		/>
	)
}

type PageHeaderBackButtonProps =
	| (Omit<React.ComponentProps<typeof Button>, "asChild" | "children"> & {
			asChild?: false
			children?: React.ReactNode
	  })
	| (Omit<React.ComponentProps<typeof Button>, "asChild" | "children"> & {
			asChild: true
			children: React.ReactElement
	  })

function PageHeaderBackButton({
	asChild = false,
	children,
	className,
	...props
}: PageHeaderBackButtonProps) {
	if (asChild) {
		return (
			<Button
				data-slot="page-header-back-button"
				asChild
				variant="ghost"
				size="sm"
				className={cn(
					"-ml-2 h-7 w-fit gap-1.5 px-2 text-muted-foreground hover:text-foreground",
					className
				)}
				{...props}
			>
				{children}
			</Button>
		)
	}

	const content = children ?? "Back"

	return (
		<Button
			data-slot="page-header-back-button"
			variant="ghost"
			size="sm"
			className={cn(
				"-ml-2 h-7 w-fit gap-1.5 px-2 text-muted-foreground hover:text-foreground",
				className
			)}
			{...props}
		>
			<ArrowLeftIcon />
			{content}
		</Button>
	)
}

function PageHeaderEyebrow({ className, ...props }: React.ComponentProps<"div">) {
	return (
		<div
			data-slot="page-header-eyebrow"
			className={cn("text-meta text-muted-foreground", className)}
			{...props}
		/>
	)
}

function PageHeaderTitle({ className, ...props }: React.ComponentProps<"h1">) {
	return (
		<h1
			data-slot="page-header-title"
			className={cn(
				"text-xl leading-tight font-medium text-foreground sm:text-[1.375rem]",
				className
			)}
			{...props}
		/>
	)
}

function PageHeaderDescription({ className, ...props }: React.ComponentProps<"p">) {
	return (
		<p
			data-slot="page-header-description"
			className={cn("max-w-2xl text-sm text-muted-foreground", className)}
			{...props}
		/>
	)
}

function PageHeaderMeta({ className, ...props }: React.ComponentProps<"div">) {
	return (
		<div
			data-slot="page-header-meta"
			className={cn(
				"flex flex-wrap items-center gap-y-1 font-mono text-xs text-muted-foreground [&>*]:after:mx-2 [&>*]:after:text-muted-foreground/45 [&>*]:after:content-['·'] [&>*:last-child]:after:hidden",
				className
			)}
			{...props}
		/>
	)
}

function PageHeaderActions({ className, ...props }: React.ComponentProps<"div">) {
	return (
		<div
			data-slot="page-header-actions"
			className={cn("flex flex-wrap items-center gap-2 md:justify-end", className)}
			{...props}
		/>
	)
}

export {
	PageHeader,
	PageHeaderActions,
	PageHeaderBackButton,
	PageHeaderContent,
	PageHeaderDescription,
	PageHeaderEyebrow,
	PageHeaderMain,
	PageHeaderMeta,
	PageHeaderTitle,
}
