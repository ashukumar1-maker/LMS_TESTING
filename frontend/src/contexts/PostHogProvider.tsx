import { useAuth } from "@/hooks/useAuth"
import posthog from "posthog-js"
import { PostHogProvider as PostHogProviderBase } from "posthog-js/react"
import { useEffect, useState } from "react"

/**
 * PostHogProvider is a component that initializes PostHog and provides it to the children.
 *
 * This component must be within an AuthProvider.
 *
 * Posthog won't be initalized until the user is authenticated.
 * This is to prevent session replay on the signincallback page which includes
 * a single use user token as a query param.
 *
 * @param children - The children to be rendered.
 * @returns The children wrapped in the PostHogProvider.
 */
export const PostHogProvider = ({ children }: { children: React.ReactNode }) => {
	const [isInitialized, setIsInitialized] = useState(false)
	const { currentUser } = useAuth()

	useEffect(() => {
		// Reset PostHog when user logs out
		if (!currentUser && isInitialized) {
			try {
				posthog.reset()
			} catch (error) {
				console.error("Error resetting PostHog:", error)
			}
			setIsInitialized(false)
			return
		}

		// Initialize PostHog when user is authenticated

		if (isInitialized) return
		if (!currentUser) return
		if (!currentUser.email) {
			console.warn("PostHog identify skipped: user has no email.")
			return
		}
		const userEmail = currentUser.email
		// Skip PostHog initialization on sensitive pages such as signincallback

		const apiKey = import.meta.env.VITE_POSTHOG_API_KEY
		const host = import.meta.env.VITE_POSTHOG_HOST || "https://app.posthog.com"
		const projectId = import.meta.env.VITE_PROJECT_ID
		const environment = import.meta.env.VITE_ENVIRONMENT || "development"

		if (!apiKey) {
			console.warn("PostHog API key not found. PostHog will not be initialized.")
			return
		}

		if (!projectId) {
			console.warn("Project ID not found. PostHog events will not be properly tagged.")
		}

		posthog.init(apiKey, {
			api_host: host,
			session_recording: {
				recordCrossOriginIframes: true,
			},
			loaded: (posthog) => {
				posthog.identify(userEmail, {
					email: userEmail,
					user_id: currentUser.uid,
					display_name: currentUser.displayName,
					email_verified: currentUser.emailVerified,
				})

				posthog.setPersonProperties({
					project_id: projectId,
					environment: environment,
				})
				// Register global properties that will be automatically added to ALL events
				posthog.register({
					project_id: projectId,
					environment: environment,
				})
			},
			capture_pageview: true,
			capture_pageleave: true,
			cross_subdomain_cookie: true,
		})

		setIsInitialized(true)
	}, [isInitialized, currentUser])

	return <PostHogProviderBase client={posthog}>{children}</PostHogProviderBase>
}

// eslint-disable-next-line react-refresh/only-export-components
export { posthog }
