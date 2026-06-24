import { useEffect, useState } from "react"
import { useNavigate, useLocation } from "react-router-dom"
import { useAuth } from "@/hooks/useAuth"
import { signInWithCustomToken } from "firebase/auth"
import { auth } from "@/firebase-config"
import { PageLoadingState } from "@/components/ui/loading-state"

const SignInCallback = () => {
	const { currentUser, loading } = useAuth()
	const navigate = useNavigate()
	const location = useLocation()
	const [error, setError] = useState<string | null>(null)
	const [isSigningIn, setIsSigningIn] = useState(false)

	useEffect(() => {
		if (loading) return // Wait until auth state is loaded

		const searchParams = new URLSearchParams(location.search)
		const customToken = searchParams.get("customToken")
		const redirectPath = searchParams.get("redirect_path")

		if (customToken && !currentUser && !isSigningIn) {
			setIsSigningIn(true)
			signInWithCustomToken(auth, customToken)
				.then(() => {
					// The onAuthStateChanged listener in AuthContext will update currentUser
					// We don't need to call navigate here directly,
					// the next effect run will handle it once currentUser is set.
					setIsSigningIn(false)
					// However, explicitly navigating after token sign-in ensures redirection
					// even if onAuthStateChanged is slightly delayed.
					navigate(redirectPath || "/", { replace: true })
				})
				.catch((signInError) => {
					console.error("Custom token sign-in error:", signInError)
					setError("Authentication failed using token. Please try again.")
					setIsSigningIn(false)
					setTimeout(() => {
						navigate("/", { replace: true })
					}, 3000)
				})
			return // Exit early to wait for token sign-in
		}

		// This part runs if not signing in with a token, or after token sign-in attempt
		if (!isSigningIn) {
			if (currentUser) {
				navigate(redirectPath || "/", { replace: true })
			} else if (!loading && !customToken) {
				// Only set error if not loading and no custom token was attempted
				setError("Authentication failed or no user session found.")
				setTimeout(() => {
					navigate("/", { replace: true })
				}, 3000)
			}
		}
	}, [currentUser, loading, navigate, location.search, isSigningIn])

	if (loading || isSigningIn) {
		return <PageLoadingState label="Completing sign in" />
	}

	if (error) {
		return (
			<div className="flex min-h-svh items-center justify-center bg-background text-foreground">
				<div className="text-center">
					<p className="mb-2 text-destructive">{error}</p>
					<p className="text-sm text-muted-foreground">You will be returned to the home page.</p>
				</div>
			</div>
		)
	}

	return <PageLoadingState label="Redirecting" />
}

export default SignInCallback
