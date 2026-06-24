import { useCallback, useEffect, useMemo, useState, type ReactNode } from "react"
import posthog from "posthog-js"
import {
	CIRIDAE_LOGO,
	CIRIDAE_LOGO_DARK,
	CIRIDAE_UI_WORDMARK,
	CIRIDAE_UI_WORDMARK_DARK,
	STORAGE_KEY,
	ThemeContext,
	type ThemeMode,
} from "./theme-context"

export type ThemeProviderProps = {
	children: ReactNode
	defaultMode?: ThemeMode
}

export function ThemeProvider({ children, defaultMode = "light" }: ThemeProviderProps) {
	const [mode, setModeState] = useState<ThemeMode>(() => readStoredMode(defaultMode))
	const resolvedTheme = mode

	useEffect(() => {
		const root = document.documentElement
		root.classList.remove("light", "dark")
		root.classList.add(resolvedTheme)
	}, [resolvedTheme])

	const setMode = useCallback((nextMode: ThemeMode) => {
		setModeState(nextMode)
		localStorage.setItem(STORAGE_KEY, nextMode)
		posthog.capture("theme_mode_changed", { mode: nextMode })
	}, [])

	const toggleTheme = useCallback(() => {
		setMode(resolvedTheme === "dark" ? "light" : "dark")
	}, [resolvedTheme, setMode])

	const currentLogo = resolvedTheme === "dark" ? CIRIDAE_LOGO_DARK : CIRIDAE_LOGO
	const currentWordmark = resolvedTheme === "dark" ? CIRIDAE_UI_WORDMARK_DARK : CIRIDAE_UI_WORDMARK

	const contextValue = useMemo(
		() => ({ mode, resolvedTheme, setMode, toggleTheme, currentLogo, currentWordmark }),
		[mode, resolvedTheme, setMode, toggleTheme, currentLogo, currentWordmark]
	)

	return <ThemeContext.Provider value={contextValue}>{children}</ThemeContext.Provider>
}

function readStoredMode(defaultMode: ThemeMode): ThemeMode {
	if (typeof window === "undefined") return defaultMode

	const storedMode = localStorage.getItem(STORAGE_KEY)
	if (storedMode === "light" || storedMode === "dark") {
		return storedMode
	}

	return defaultMode
}
