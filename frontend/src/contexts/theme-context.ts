import { createContext } from "react"

export type ThemeMode = "light" | "dark"
export type ResolvedTheme = "light" | "dark"

export type ThemeContextValue = {
	mode: ThemeMode
	resolvedTheme: ResolvedTheme
	setMode: (mode: ThemeMode) => void
	toggleTheme: () => void
	currentLogo: string
	currentWordmark: string
}

export const CIRIDAE_LOGO = "/ciridae-black.svg"
export const CIRIDAE_LOGO_DARK = "/ciridae-white.svg"
export const CIRIDAE_UI_WORDMARK = "/ciridae-ui-wordmark-black.png"
export const CIRIDAE_UI_WORDMARK_DARK = "/ciridae-ui-wordmark-white.png"
export const STORAGE_KEY = "ciridae-ui-theme"
export const ThemeContext = createContext<ThemeContextValue | undefined>(undefined)
