import { Navigate } from "react-router-dom"
import { useAuth } from "@/hooks/useAuth"
import { isSignOutRedirectPending } from "@/hooks/useSignOut"
import { PageLoadingState } from "@/components/ui/loading-state"

type PrivateRouteProps = {
	element: React.ReactElement
}

const PrivateRoute = ({ element }: PrivateRouteProps) => {
	const { currentUser, loading } = useAuth()

	if (loading) {
		return <PageLoadingState label="Loading Fullstack Template 1" />
	}

	if (!currentUser) {
		if (isSignOutRedirectPending()) {
			return <PageLoadingState label="Signing out" />
		}

		const authServiceFrontendUrl = import.meta.env.VITE_AUTH_SERVICE_FRONTEND_URL
		const projectId = import.meta.env.VITE_PROJECT_ID

		if (authServiceFrontendUrl && projectId) {
			const redirectUrl = encodeURIComponent(
				`${window.location.origin}/signincallback?redirect_path=${window.location.pathname}${encodeURIComponent(window.location.search || "")}`
			)
			const authUrl = `${authServiceFrontendUrl}?project_id=${projectId}&redirect_url=${redirectUrl}`
			window.location.href = authUrl
			return null
		}

		// Fallback if env vars are not set
		return <Navigate to="/signin" replace />
	}

	return element
}

export default PrivateRoute
