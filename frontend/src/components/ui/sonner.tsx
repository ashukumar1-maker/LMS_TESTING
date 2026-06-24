"use client"

import { CircleCheckIcon, InfoIcon, OctagonXIcon, TriangleAlertIcon } from "lucide-react"
import { Toaster as Sonner, type ToasterProps } from "sonner"
import { Spinner } from "@/components/ui/spinner"

type SonnerStyleProperties = React.CSSProperties & Record<`--${string}`, string>

const toasterStyle: SonnerStyleProperties = {
	"--normal-bg": "var(--popover)",
	"--normal-text": "var(--popover-foreground)",
	"--normal-border": "var(--border)",
	"--border-radius": "var(--radius)",
	"--success-bg": "var(--success-muted)",
	"--success-border": "var(--success)",
	"--success-text": "var(--success)",
	"--info-bg": "var(--info-muted)",
	"--info-border": "var(--info)",
	"--info-text": "var(--info)",
	"--warning-bg": "var(--warning-muted)",
	"--warning-border": "var(--warning)",
	"--warning-text": "var(--warning-foreground)",
	"--error-bg": "var(--destructive)",
	"--error-border": "var(--destructive)",
	"--error-text": "var(--destructive-foreground)",
}

const Toaster = ({ theme = "system", ...props }: ToasterProps) => {
	return (
		<Sonner
			theme={theme}
			icons={{
				success: <CircleCheckIcon className="size-4" />,
				info: <InfoIcon className="size-4" />,
				warning: <TriangleAlertIcon className="size-4" />,
				error: <OctagonXIcon className="size-4" />,
				loading: <Spinner className="size-4" />,
			}}
			style={toasterStyle}
			{...props}
		/>
	)
}

export { Toaster }
