import { useEffect, useState, ReactNode, useMemo } from "react"
import { User, onAuthStateChanged, setPersistence, inMemoryPersistence } from "firebase/auth"
import { auth } from "@/firebase-config"
import { AuthContext } from "./AuthContextDefinition"

export const AuthProvider = ({ children }: { children: ReactNode }) => {
	const [currentUser, setCurrentUser] = useState<User | null>(null)
	const [loading, setLoading] = useState(true)
	const contextValue = useMemo(() => ({ currentUser, loading }), [currentUser, loading])

	useEffect(() => {
		const initializeAuth = async () => {
			try {
				await setPersistence(auth, inMemoryPersistence)
			} catch (error) {
				console.error("Error setting auth persistence:", error)
			}
			const unsubscribe = onAuthStateChanged(auth, (user) => {
				setCurrentUser(user)
				setLoading(false)
			})
			return unsubscribe
		}

		const unsubscribePromise = initializeAuth()

		return () => {
			unsubscribePromise.then((unsubscribe) => {
				if (unsubscribe) {
					unsubscribe()
				}
			})
		}
	}, [])

	return <AuthContext.Provider value={contextValue}>{children}</AuthContext.Provider>
}
