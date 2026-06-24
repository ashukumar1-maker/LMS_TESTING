import * as React from "react"
import { Slot } from "radix-ui"

import { cn } from "@/lib/utils"
import { buttonVariants, type ButtonVariantProps } from "@/components/ui/button-variants"
import { Spinner } from "@/components/ui/spinner"

function Button({
	children,
	className,
	variant = "default",
	size = "default",
	asChild = false,
	disabled,
	loading = false,
	loadingLabel = "Loading",
	onClick,
	tabIndex,
	...props
}: React.ComponentProps<"button"> &
	ButtonVariantProps & {
		asChild?: boolean
		loading?: boolean
		loadingLabel?: string
	}) {
	const Comp = asChild ? Slot.Root : "button"
	const isDisabled = disabled || loading

	return (
		<Comp
			{...props}
			data-slot="button"
			data-variant={variant}
			data-size={size}
			data-loading={getDataLoading(loading)}
			aria-busy={getAriaBusy(loading)}
			aria-disabled={getAriaDisabled(asChild, isDisabled)}
			className={cn(
				buttonVariants({ variant, size, className }),
				getDisabledChildClass(asChild, isDisabled)
			)}
			disabled={getDisabled(asChild, isDisabled)}
			onClick={getClickHandler(asChild, isDisabled, onClick)}
			tabIndex={getTabIndex(asChild, isDisabled, tabIndex)}
		>
			<ButtonChildren asChild={asChild} loading={loading} loadingLabel={loadingLabel}>
				{children}
			</ButtonChildren>
		</Comp>
	)
}

function ButtonChildren({
	asChild,
	children,
	loading,
	loadingLabel,
}: {
	asChild: boolean
	children: React.ReactNode
	loading: boolean
	loadingLabel: string
}) {
	return (
		<>
			<ButtonLoadingIcon loading={loading} />
			<ButtonContent asChild={asChild}>{children}</ButtonContent>
			<ButtonLoadingLabel label={loadingLabel} loading={loading} />
		</>
	)
}

function ButtonLoadingIcon({ loading }: { loading: boolean }) {
	if (!loading) return null

	return <Spinner aria-hidden="true" className="shrink-0" />
}

function ButtonContent({ asChild, children }: { asChild: boolean; children: React.ReactNode }) {
	if (asChild) return <Slot.Slottable>{children}</Slot.Slottable>

	return <>{children}</>
}

function ButtonLoadingLabel({ label, loading }: { label: string; loading: boolean }) {
	if (!loading) return null

	return <span className="sr-only">{label}</span>
}

function getDataLoading(loading: boolean) {
	if (!loading) return undefined

	return "true"
}

function getAriaBusy(loading: boolean) {
	if (!loading) return undefined

	return true
}

function getAriaDisabled(asChild: boolean, isDisabled: boolean) {
	if (!asChild || !isDisabled) return undefined

	return true
}

function getDisabled(asChild: boolean, isDisabled: boolean) {
	if (asChild) return undefined

	return isDisabled
}

function getDisabledChildClass(asChild: boolean, isDisabled: boolean) {
	if (!asChild || !isDisabled) return undefined

	return "pointer-events-none"
}

function getClickHandler(
	asChild: boolean,
	isDisabled: boolean,
	onClick: React.ComponentProps<"button">["onClick"]
) {
	if (!asChild || !isDisabled) return onClick

	return (event: React.MouseEvent<HTMLButtonElement>) => {
		event.preventDefault()
		event.stopPropagation()
	}
}

function getTabIndex(asChild: boolean, isDisabled: boolean, tabIndex: number | undefined) {
	if (!asChild || !isDisabled) return tabIndex

	return -1
}

export { Button }
