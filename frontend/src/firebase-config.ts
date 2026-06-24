import { initializeApp } from "firebase/app"
import { getAuth } from "firebase/auth"

// TODO: Replace placeholder values below with your actual Identity Platform config
// from the Google Cloud Console (Identity Platform -> Settings -> Application Setup Details)
// Ensure these environment variables are set in your .env.development file
const firebaseConfig = {
	apiKey: import.meta.env.VITE_IDENTITY_PLATFORM_API_KEY,
	authDomain: import.meta.env.VITE_IDENTITY_PLATFORM_AUTH_DOMAIN,
}

// Initialize Firebase
const app = initializeApp(firebaseConfig)

// Initialize Firebase Authentication and get a reference to the service
export const auth = getAuth(app)
