import { createRoot } from "react-dom/client"
import * as Sentry from "@sentry/react"
import App from "./App.tsx"
import "./index.css"

// Initialize Sentry
if (import.meta.env.VITE_SENTRY_DSN) {
	Sentry.init({
		dsn: import.meta.env.VITE_SENTRY_DSN,
		integrations: [Sentry.browserTracingIntegration(), Sentry.replayIntegration()],
		// Performance Monitoring
		tracesSampleRate: 1.0,
		// Session Replay
		replaysSessionSampleRate: 0.1,
		replaysOnErrorSampleRate: 1.0,
		environment: import.meta.env.VITE_ENVIRONMENT,
	})
}

const rootElement = document.getElementById("root")
if (!rootElement) {
	throw new Error("Root element not found")
}

createRoot(rootElement).render(<App />)
