import { QueryClient, QueryClientProvider } from "@tanstack/react-query"
import type { ReactNode } from "react"
import { AuthProvider } from "./contexts/AuthContext"
import { PostHogProvider } from "./contexts"
import { ThemeProvider } from "./contexts"
import { useTheme } from "./contexts/useTheme"
import { Toaster } from "@/components/ui/sonner"
import { TooltipProvider } from "@/components/ui/tooltip"

const queryClient = new QueryClient()

const AppProviders = ({ children }: { children: ReactNode }) => (
	<AppDataProviders>
		<AppUiProviders>{children}</AppUiProviders>
	</AppDataProviders>
)

const AppDataProviders = ({ children }: { children: ReactNode }) => (
	<QueryClientProvider client={queryClient}>
		<AuthProvider>
			<PostHogProvider>{children}</PostHogProvider>
		</AuthProvider>
	</QueryClientProvider>
)

const AppUiProviders = ({ children }: { children: ReactNode }) => (
	<ThemeProvider>
		<TooltipProvider>
			{children}
			<AppToaster />
		</TooltipProvider>
	</ThemeProvider>
)

function AppToaster() {
	const { mode } = useTheme()

	return <Toaster richColors closeButton theme={mode} />
}

export default AppProviders
