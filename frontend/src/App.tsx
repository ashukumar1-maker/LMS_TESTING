import { BrowserRouter, Navigate, Route, Routes } from "react-router-dom"
import AppProviders from "./AppProviders"
import AppShell from "./components/app/AppShell"
import PrivateRoute from "./components/features/auth/PrivateRoute"
import NotFound from "./pages/NotFound"
import SignInCallback from "./pages/SignInCallback"

const App = () => (
	<AppProviders>
		<BrowserRouter>
			<Routes>
				<Route path="/signincallback" element={<SignInCallback />} />
				<Route path="/app/*" element={<PrivateRoute element={<AppShell />} />} />
				<Route path="/" element={<Navigate to="/app" replace />} />
				<Route path="*" element={<NotFound />} />
			</Routes>
		</BrowserRouter>
	</AppProviders>
)

export default App
