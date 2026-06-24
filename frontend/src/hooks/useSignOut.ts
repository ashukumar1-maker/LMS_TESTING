import { useMutation } from "@tanstack/react-query"
import { signOut as firebaseSignOut } from "firebase/auth"
import { usePostHog } from "posthog-js/react"

import { auth } from "@/firebase-config"

const SIGN_OUT_REDIRECT_PENDING_KEY = "ciridae-ui-signout-redirect-pending"
const SIGN_OUT_REDIRECT_PENDING_TTL_MS = 10_000

const performFirebaseSignOut = async () => {
	markSignOutRedirectPending()
	await firebaseSignOut(auth)
}

export const isSignOutRedirectPending = () => {
	const pendingSince = Number(sessionStorage.getItem(SIGN_OUT_REDIRECT_PENDING_KEY))
	if (!Number.isFinite(pendingSince)) return false

	const isPending = Date.now() - pendingSince < SIGN_OUT_REDIRECT_PENDING_TTL_MS
	if (!isPending) {
		clearSignOutRedirectPending()
	}

	return isPending
}

export const useSignOut = () => {
	const posthog = usePostHog()

	return useMutation({
		mutationFn: performFirebaseSignOut,
		onSuccess: () => {
			const signOutUrl = `${import.meta.env.VITE_AUTH_SERVICE_FRONTEND_URL}/signout`
			try {
				posthog.capture("user_logged_out", {
					logout_method: "manual",
					redirect_url: signOutUrl,
				})
			} finally {
				clearSignOutRedirectPending()
				window.location.assign(signOutUrl)
			}
		},
		onError: (error) => {
			clearSignOutRedirectPending()
			console.error("Firebase sign out failed:", error)
		},
	})
}

function markSignOutRedirectPending() {
	sessionStorage.setItem(SIGN_OUT_REDIRECT_PENDING_KEY, String(Date.now()))
}

function clearSignOutRedirectPending() {
	sessionStorage.removeItem(SIGN_OUT_REDIRECT_PENDING_KEY)
}
