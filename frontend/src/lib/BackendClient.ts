import axios, { AxiosError } from "axios"
import { auth } from "@/firebase-config"

const BackendClient = axios.create({
	baseURL: import.meta.env.VITE_API_URL,
})

BackendClient.interceptors.request.use(async (config) => {
	const user = auth.currentUser
	if (user) {
		const token = await user.getIdToken()
		config.headers.Authorization = `Bearer ${token}`
	}
	return config
})

BackendClient.interceptors.response.use(
	(response) => response,
	(error: AxiosError<{ detail?: string }>) => {
		if (error.response?.data?.detail) {
			error.message = error.response.data.detail
		}
		return Promise.reject(error)
	}
)

export default BackendClient
