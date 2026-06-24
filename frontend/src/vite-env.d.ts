/// <reference types="vite/client" />

interface ImportMetaEnv {
	readonly VITE_API_URL: string
	readonly VITE_PROJECT_ID: string
	readonly VITE_AUTH_SERVICE_FRONTEND_URL: string
	readonly VITE_POSTHOG_API_KEY: string | undefined
	readonly VITE_POSTHOG_HOST: string | undefined
	readonly VITE_ENVIRONMENT: string
	readonly VITE_SENTRY_DSN: string | undefined
	readonly VITE_IDENTITY_PLATFORM_API_KEY: string | undefined
	readonly VITE_IDENTITY_PLATFORM_AUTH_DOMAIN: string | undefined
}

interface ImportMeta {
	readonly env: ImportMetaEnv
}
