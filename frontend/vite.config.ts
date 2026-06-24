import { defineConfig } from "vite"
import react from "@vitejs/plugin-react-swc"
import tailwindcss from "@tailwindcss/vite"
import path from "path"
import { sentryVitePlugin } from "@sentry/vite-plugin"

export default defineConfig(({ mode }) => ({
	server: {
		host: "::",
		port: 3000,
		allowedHosts: true,
	},
	plugins: [
		react(),
		tailwindcss(),
		mode === "production" &&
			sentryVitePlugin({
				org: process.env.SENTRY_ORG,
				project: process.env.SENTRY_PROJECT,
				authToken: process.env.SENTRY_AUTH_TOKEN,
				sourcemaps: {
					filesToDeleteAfterUpload: ["dist/**/*.js.map"],
				},
			}),
	].filter(Boolean),
	resolve: {
		alias: {
			"@": path.resolve(__dirname, "./src"),
		},
	},
	build: {
		sourcemap: true,
	},
}))
