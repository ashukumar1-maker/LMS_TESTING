import * as React from "react"
import { MenuIcon, PanelLeftCloseIcon, PanelLeftOpenIcon } from "lucide-react"

import { Button } from "@/components/ui/button"
import { useSidebar } from "@/components/ui/sidebar/context"
import { cn } from "@/lib/utils"

function SidebarTrigger({ className, onClick, ...props }: React.ComponentProps<typeof Button>) {
	const { isMobile, openMobile, state, toggleSidebar } = useSidebar()
	const isExpanded = isMobile ? openMobile : state === "expanded"
	const label = isExpanded ? "Collapse sidebar" : "Expand sidebar"
	const Icon =
		isMobile && !isExpanded ? MenuIcon : isExpanded ? PanelLeftCloseIcon : PanelLeftOpenIcon

	return (
		<Button
			aria-label={label}
			data-sidebar="trigger"
			data-slot="sidebar-trigger"
			title={label}
			variant="ghost"
			size="icon"
			className={cn("size-7", className)}
			onClick={(event) => {
				onClick?.(event)
				if (!event.defaultPrevented) toggleSidebar()
			}}
			{...props}
		>
			<Icon />
			<span className="sr-only">{label}</span>
		</Button>
	)
}

export { SidebarTrigger }
