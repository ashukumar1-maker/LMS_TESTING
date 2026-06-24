import * as React from "react"

import { cn } from "@/lib/utils"
import { Card, CardContent, CardHeader } from "@/components/ui/card"
import { Skeleton } from "@/components/ui/skeleton"
import { Spinner } from "@/components/ui/spinner"

type LoadingStateSize = "sm" | "default" | "lg"

const loadingStateSizes: Record<LoadingStateSize, string> = {
	sm: "min-h-14 gap-2 p-3",
	default: "min-h-24 gap-3 p-(--panel-padding)",
	lg: "min-h-48 gap-3 p-8",
}

const loadingSpinnerSizes: Record<LoadingStateSize, string> = {
	sm: "size-3.5",
	default: "size-4",
	lg: "size-5",
}

type LoadingStateProps = React.ComponentProps<"div"> & {
	description?: React.ReactNode
	label?: React.ReactNode
	size?: LoadingStateSize
}

function LoadingState({
	className,
	description,
	label = "Loading",
	size = "default",
	...props
}: LoadingStateProps) {
	const labelId = React.useId()

	return (
		<div
			role="status"
			aria-labelledby={label ? labelId : undefined}
			aria-live="polite"
			data-slot="loading-state"
			data-size={size}
			className={cn(
				"flex flex-col items-center justify-center text-center text-muted-foreground",
				loadingStateSizes[size],
				className
			)}
			{...props}
		>
			<Spinner
				aria-hidden="true"
				className={cn("text-muted-foreground", loadingSpinnerSizes[size])}
			/>
			{label || description ? (
				<div className="grid gap-1">
					{label ? (
						<div id={labelId} className="text-sm font-medium text-foreground">
							{label}
						</div>
					) : null}
					{description ? <div className="text-sm text-muted-foreground">{description}</div> : null}
				</div>
			) : null}
		</div>
	)
}

type PageLoadingStateProps = Omit<LoadingStateProps, "size">

function PageLoadingState({
	className,
	description,
	label = "Preparing workspace",
	...props
}: PageLoadingStateProps) {
	return (
		<div
			data-slot="page-loading-state"
			className={cn(
				"flex min-h-svh items-center justify-center bg-background p-6 text-foreground",
				className
			)}
			{...props}
		>
			<LoadingState description={description} label={label} size="sm" className="min-h-0 p-0" />
		</div>
	)
}

type TableSkeletonProps = React.ComponentProps<"div"> & {
	columns?: number
	rows?: number
	showHeader?: boolean
}

function TableSkeleton({
	className,
	columns = 4,
	rows = 5,
	showHeader = true,
	...props
}: TableSkeletonProps) {
	const safeColumns = Math.max(1, Math.floor(columns))
	const safeRows = Math.max(1, Math.floor(rows))
	const columnItems = Array.from({ length: safeColumns })
	const rowItems = Array.from({ length: safeRows })
	const gridStyle: React.CSSProperties = {
		gridTemplateColumns: `repeat(${safeColumns}, minmax(0, 1fr))`,
	}

	return (
		<div
			role="status"
			aria-label="Loading table"
			data-slot="table-skeleton"
			className={cn("overflow-hidden rounded-md border bg-card text-card-foreground", className)}
			{...props}
		>
			<div aria-hidden="true">
				{showHeader ? (
					<div className="grid border-b bg-muted/40" style={gridStyle}>
						{columnItems.map((_, index) => (
							<div key={index} className="px-(--table-cell-padding-x) py-(--table-cell-padding-y)">
								<Skeleton
									className={cn("h-3", index === safeColumns - 1 ? "ml-auto w-12" : "w-16")}
								/>
							</div>
						))}
					</div>
				) : null}
				{rowItems.map((_, rowIndex) => (
					<div key={rowIndex} className="grid border-b last:border-b-0" style={gridStyle}>
						{columnItems.map((_, columnIndex) => (
							<div
								key={columnIndex}
								className="flex h-(--table-row-height) items-center px-(--table-cell-padding-x)"
							>
								<Skeleton
									className={cn(
										"h-3",
										columnIndex === safeColumns - 1
											? "ml-auto w-14"
											: columnIndex === 0
												? "w-24"
												: "w-20"
									)}
								/>
							</div>
						))}
					</div>
				))}
			</div>
		</div>
	)
}

type CardSkeletonProps = React.ComponentProps<typeof Card> & {
	lines?: number
}

function CardSkeleton({ className, lines = 3, variant, ...props }: CardSkeletonProps) {
	const lineItems = Array.from({ length: lines })

	return (
		<Card
			role="status"
			aria-label="Loading card"
			data-slot="card-skeleton"
			variant={variant}
			className={className}
			{...props}
		>
			<div aria-hidden="true">
				<CardHeader>
					<Skeleton className="h-4 w-32" />
					<Skeleton className="h-3 w-48 max-w-full" />
				</CardHeader>
				<CardContent className="grid gap-2">
					{lineItems.map((_, index) => (
						<Skeleton
							key={index}
							className={cn("h-3", index === lineItems.length - 1 ? "w-2/3" : "w-full")}
						/>
					))}
				</CardContent>
			</div>
		</Card>
	)
}

type FormSkeletonProps = React.ComponentProps<"div"> & {
	fields?: number
}

function FormSkeleton({ className, fields = 4, ...props }: FormSkeletonProps) {
	const fieldItems = Array.from({ length: fields })

	return (
		<div
			role="status"
			aria-label="Loading form"
			data-slot="form-skeleton"
			className={cn("grid gap-[calc(var(--panel-gap)+0.5rem)]", className)}
			{...props}
		>
			<div aria-hidden="true" className="grid gap-[calc(var(--panel-gap)+0.5rem)]">
				{fieldItems.map((_, index) => (
					<div key={index} className="grid gap-2">
						<Skeleton className="h-3 w-24" />
						<Skeleton className="h-(--control-height) w-full" />
					</div>
				))}
			</div>
		</div>
	)
}

export { LoadingState, PageLoadingState, TableSkeleton, CardSkeleton, FormSkeleton }
export type {
	LoadingStateProps,
	PageLoadingStateProps,
	TableSkeletonProps,
	CardSkeletonProps,
	FormSkeletonProps,
}
