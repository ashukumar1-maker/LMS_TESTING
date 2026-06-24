import {
	PageHeader,
	PageHeaderContent,
	PageHeaderDescription,
	PageHeaderMain,
	PageHeaderTitle,
} from "@/components/ui/page-header"
import { SidebarTrigger } from "@/components/ui/sidebar"

function GettingStartedPage() {
	return (
		<>
			<PageHeader>
				<PageHeaderMain className="pl-14 md:pl-6 lg:pl-8">
					<PageHeaderContent>
						<PageHeaderTitle>Getting Started</PageHeaderTitle>
						<PageHeaderDescription>The launchpad for AI transformation.</PageHeaderDescription>
					</PageHeaderContent>
				</PageHeaderMain>
			</PageHeader>
			<div className="relative flex flex-1 items-center justify-center bg-background p-6 text-foreground">
				<SidebarTrigger className="absolute top-4 left-4 md:hidden" />
				<div className="flex flex-col items-center gap-4 text-center">
					<HeroBrand />
					<h2 className="text-2xl font-heading tracking-normal">Take pride in your work.</h2>
					<p className="max-w-md text-sm text-muted-foreground">
						To view more Ciridae UI components, visit{" "}
						<a
							className="font-medium text-foreground underline underline-offset-4 hover:text-foreground/72"
							href="https://ciridae-ui.ciridae.app/app"
							rel="noreferrer"
							target="_blank"
						>
							Ciridae UI
						</a>
						.
					</p>
				</div>
			</div>
		</>
	)
}

function HeroBrand() {
	return (
		<div className="flex justify-center">
			<img alt="" className="h-24 w-auto dark:hidden" src="/ciridae-icon-black.png" />
			<img alt="" className="hidden h-24 w-auto dark:block" src="/ciridae-icon-white.png" />
		</div>
	)
}

export { GettingStartedPage }
