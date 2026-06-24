import { useEffect, useState } from "react"

/**
 * Hook to detect if a media query matches
 * @param query - CSS media query string (e.g., "(max-width: 640px)")
 * @returns boolean indicating if the query matches
 */
export function useMediaQuery(query: string): boolean {
	const [matches, setMatches] = useState(false)

	useEffect(() => {
		const mediaQuery = window.matchMedia(query)

		// Set initial value
		setMatches(mediaQuery.matches)

		// Create listener
		const handler = (event: MediaQueryListEvent) => {
			setMatches(event.matches)
		}

		// Add listener
		mediaQuery.addEventListener("change", handler)

		// Cleanup
		return () => {
			mediaQuery.removeEventListener("change", handler)
		}
	}, [query])

	return matches
}
