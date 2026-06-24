import { Link, useLocation } from "react-router-dom"
import { useEffect } from "react"

const NotFound = () => {
	const location = useLocation()

	useEffect(() => {
		console.error("404 Error: User attempted to access non-existent route:", location.pathname)
	}, [location.pathname])

	return (
		<div className="flex min-h-svh items-center justify-center bg-background p-6 text-foreground">
			<div className="text-center">
				<h1 className="mb-4 text-4xl font-semibold">404</h1>
				<p className="mb-4 text-sm text-muted-foreground">Page not found</p>
				<Link to="/" className="text-sm text-primary underline underline-offset-4">
					Return to Home
				</Link>
			</div>
		</div>
	)
}

export default NotFound
