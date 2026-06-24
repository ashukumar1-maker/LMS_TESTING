import { ChevronUpIcon, LogOutIcon, MoonIcon, SunIcon } from "lucide-react"

import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar"
import {
	DropdownMenu,
	DropdownMenuContent,
	DropdownMenuItem,
	DropdownMenuLabel,
	DropdownMenuSeparator,
	DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu"
import { SidebarMenu, SidebarMenuButton, SidebarMenuItem } from "@/components/ui/sidebar/menu"
import { useSidebar } from "@/components/ui/sidebar/context"
import { Spinner } from "@/components/ui/spinner"
import { cn } from "@/lib/utils"

type SidebarAccountThemeMode = "light" | "dark"

type SidebarAccountMenuProps = {
	username?: string | null
	email?: string | null
	imageUrl?: string | null
	onSignOut?: () => void
	isSigningOut?: boolean
	themeMode?: SidebarAccountThemeMode
	onThemeModeChange?: (mode: SidebarAccountThemeMode) => void
	className?: string
}

function SidebarAccountMenu({
	username,
	email,
	imageUrl,
	onSignOut,
	isSigningOut = false,
	themeMode,
	onThemeModeChange,
	className,
}: SidebarAccountMenuProps) {
	const { isMobile, state } = useSidebar()
	const label = getAccountLabel(username, email)
	const detail = email ?? "Signed in"
	const accountMark = getAccountMark(label)
	const isCollapsed = state === "collapsed" && !isMobile

	return (
		<SidebarMenu className={cn("group-data-[collapsible=icon]:-mx-0.5", className)}>
			<SidebarMenuItem>
				<AccountDropdown
					detail={detail}
					imageUrl={imageUrl}
					accountMark={accountMark}
					isCollapsed={isCollapsed}
					isSigningOut={isSigningOut}
					label={label}
					onSignOut={onSignOut}
					onThemeModeChange={onThemeModeChange}
					themeMode={themeMode}
				/>
			</SidebarMenuItem>
		</SidebarMenu>
	)
}

function AccountDropdown({
	accountMark,
	detail,
	imageUrl,
	isCollapsed,
	isSigningOut,
	label,
	onSignOut,
	onThemeModeChange,
	themeMode,
}: {
	accountMark: string
	detail: string
	imageUrl?: string | null
	isCollapsed: boolean
	isSigningOut: boolean
	label: string
	onSignOut?: () => void
	onThemeModeChange?: (mode: SidebarAccountThemeMode) => void
	themeMode?: SidebarAccountThemeMode
}) {
	return (
		<DropdownMenu>
			<AccountMenuTrigger
				accountMark={accountMark}
				detail={detail}
				imageUrl={imageUrl}
				label={label}
			/>
			<DropdownMenuContent
				align={isCollapsed ? "end" : "start"}
				className={cn("shadow-sm", isCollapsed ? "w-44" : "w-52")}
				side={isCollapsed ? "right" : "top"}
				sideOffset={4}
			>
				<AccountMenuLabel
					accountMark={accountMark}
					detail={detail}
					imageUrl={imageUrl}
					label={label}
				/>
				<AccountThemeSection mode={themeMode} onModeChange={onThemeModeChange} />
				<DropdownMenuSeparator />
				<AccountSignOutItem isSigningOut={isSigningOut} onSignOut={onSignOut} />
			</DropdownMenuContent>
		</DropdownMenu>
	)
}

function AccountMenuTrigger({
	accountMark,
	detail,
	imageUrl,
	label,
}: {
	accountMark: string
	detail: string
	imageUrl?: string | null
	label: string
}) {
	return (
		<DropdownMenuTrigger asChild>
			<SidebarMenuButton
				aria-label={`Open account menu for ${label}`}
				className={cn(
					"h-auto min-h-(--control-height) py-1",
					"text-sidebar-foreground/78 hover:text-sidebar-accent-foreground",
					"data-[state=open]:bg-sidebar-accent/45 data-[state=open]:text-sidebar-accent-foreground",
					"group-data-[collapsible=icon]:justify-center group-data-[collapsible=icon]:p-0!"
				)}
				tooltip={label}
			>
				<AccountAvatar accountMark={accountMark} imageUrl={imageUrl} />
				<AccountTriggerText detail={detail} label={label} />
				<ChevronUpIcon className="ml-auto size-3.5 text-sidebar-foreground/42 group-data-[collapsible=icon]:hidden" />
			</SidebarMenuButton>
		</DropdownMenuTrigger>
	)
}

function AccountTriggerText({ detail, label }: { detail: string; label: string }) {
	return (
		<span className="grid min-w-0 flex-1 gap-0.5 text-left group-data-[collapsible=icon]:hidden">
			<span className="truncate text-sm leading-4 font-control">{label}</span>
			<span className="truncate text-xs leading-3 text-sidebar-foreground/46">{detail}</span>
		</span>
	)
}

function AccountMenuLabel({
	accountMark,
	detail,
	imageUrl,
	label,
}: {
	accountMark: string
	detail: string
	imageUrl?: string | null
	label: string
}) {
	return (
		<DropdownMenuLabel className="p-0 normal-case tracking-normal text-popover-foreground">
			<div className="flex min-w-0 items-center gap-(--control-gap) px-(--menu-item-padding-x) py-0.5">
				<AccountAvatar accountMark={accountMark} imageUrl={imageUrl} />
				<AccountMenuLabelText detail={detail} label={label} />
			</div>
		</DropdownMenuLabel>
	)
}

function AccountMenuLabelText({ detail, label }: { detail: string; label: string }) {
	return (
		<span className="grid min-w-0 flex-1 gap-0.5 text-left">
			<span className="truncate text-sm leading-4 font-control">{label}</span>
			<span className="truncate text-xs leading-3 text-muted-foreground">{detail}</span>
		</span>
	)
}

function AccountSignOutItem({
	isSigningOut,
	onSignOut,
}: {
	isSigningOut: boolean
	onSignOut?: () => void
}) {
	return (
		<DropdownMenuItem
			className="min-h-(--sidebar-item-height)"
			disabled={!onSignOut || isSigningOut}
			onSelect={() => onSignOut?.()}
		>
			{isSigningOut ? <Spinner aria-hidden="true" /> : <LogOutIcon />}
			<span>Sign out</span>
		</DropdownMenuItem>
	)
}

function AccountThemeSection({
	mode,
	onModeChange,
}: {
	mode?: SidebarAccountThemeMode
	onModeChange?: (mode: SidebarAccountThemeMode) => void
}) {
	if (!mode || !onModeChange) return null

	return (
		<>
			<DropdownMenuSeparator />
			<AccountThemeControls mode={mode} onModeChange={onModeChange} />
		</>
	)
}

function AccountThemeControls({
	mode,
	onModeChange,
}: {
	mode: SidebarAccountThemeMode
	onModeChange: (mode: SidebarAccountThemeMode) => void
}) {
	return (
		<div className="px-(--menu-item-padding-x) py-1">
			<div className="mb-1 text-xs font-control text-muted-foreground">Theme</div>
			<ThemeModeButtons mode={mode} onModeChange={onModeChange} />
		</div>
	)
}

function ThemeModeButtons({
	mode,
	onModeChange,
}: {
	mode: SidebarAccountThemeMode
	onModeChange: (mode: SidebarAccountThemeMode) => void
}) {
	return (
		<div className="grid grid-cols-2 gap-0.5 rounded-[var(--sidebar-item-radius)] border border-border/70 bg-transparent p-0.5">
			<ThemeModeButton active={mode === "light"} mode="light" onModeChange={onModeChange} />
			<ThemeModeButton active={mode === "dark"} mode="dark" onModeChange={onModeChange} />
		</div>
	)
}

function ThemeModeButton({
	active,
	mode,
	onModeChange,
}: {
	active: boolean
	mode: SidebarAccountThemeMode
	onModeChange: (mode: SidebarAccountThemeMode) => void
}) {
	const label = getThemeModeLabel(mode)

	return (
		<button
			aria-pressed={active}
			className={cn(
				"flex h-(--sidebar-item-height-sm) items-center justify-center gap-1 rounded-sm px-2 text-xs font-control text-muted-foreground outline-hidden transition-[color,background-color,box-shadow]",
				"hover:bg-background hover:text-foreground focus-visible:ring-[var(--focus-ring-width)] focus-visible:ring-ring",
				active && "bg-muted text-foreground shadow-none"
			)}
			onClick={() => onModeChange(mode)}
			type="button"
		>
			<ThemeModeIcon mode={mode} />
			<span>{label}</span>
		</button>
	)
}

function ThemeModeIcon({ mode }: { mode: SidebarAccountThemeMode }) {
	if (mode === "light") return <SunIcon className="size-3.5" />

	return <MoonIcon className="size-3.5" />
}

function getThemeModeLabel(mode: SidebarAccountThemeMode) {
	if (mode === "light") return "Light"

	return "Dark"
}

function AccountAvatar({
	accountMark,
	imageUrl,
}: {
	accountMark: string
	imageUrl?: string | null
}) {
	return (
		<Avatar className="size-5 rounded-[var(--sidebar-item-radius)]" size="sm">
			{imageUrl ? <AvatarImage alt="" src={imageUrl} /> : null}
			<AvatarFallback className="rounded-[var(--sidebar-item-radius)] bg-sidebar-accent text-xs text-sidebar-accent-foreground">
				{accountMark}
			</AvatarFallback>
		</Avatar>
	)
}

function getAccountLabel(username?: string | null, email?: string | null) {
	const trimmedUsername = username?.trim()
	if (trimmedUsername) return trimmedUsername

	const emailPrefix = email?.split("@")[0]?.trim()
	if (emailPrefix) return emailPrefix

	return "Account"
}

function getAccountMark(label: string) {
	return label.match(/[A-Za-z0-9]/)?.[0]?.toUpperCase() ?? "U"
}

export { SidebarAccountMenu }
export type { SidebarAccountMenuProps, SidebarAccountThemeMode }
