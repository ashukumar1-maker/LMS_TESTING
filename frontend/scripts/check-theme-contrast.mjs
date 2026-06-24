import { readFileSync } from "node:fs"
import { join } from "node:path"
import { parse, wcagContrast } from "culori"

const ROOT = process.cwd()
const CSS_PATH = join(ROOT, "src/index.css")
const css = readFileSync(CSS_PATH, "utf8")

const themes = {
	light: readTokens(":root"),
	dark: readTokens(".dark"),
}

const contrastChecks = [
	text("foreground", "background", 7),
	text("card-foreground", "card", 7),
	text("popover-foreground", "popover", 7),
	text("surface-foreground", "surface", 7),
	text("surface-inverse-foreground", "surface-inverse", 7),
	text("muted-foreground", "background", 4.5),
	text("secondary-foreground", "secondary", 4.5),
	text("accent-foreground", "accent", 4.5),
	text("primary-foreground", "primary", 4.5),
	text("destructive-foreground", "destructive", 4.5),
	text("success-foreground", "success", 4.5),
	text("info-foreground", "info", 4.5),
	text("warning-foreground", "warning", 4.5),
	text("sidebar-foreground", "sidebar", 7),
	text("sidebar-primary-foreground", "sidebar-primary", 4.5),
	text("sidebar-accent-foreground", "sidebar-accent", 4.5),
	text("table-header-foreground", "background", 7),
	text("table-header-foreground", "card", 7),
	text("success", "background", 4.5),
	text("success", "card", 4.5),
	text("success", "muted", 4.5),
	text("success", "success-muted", 4.5),
	text("info", "background", 4.5),
	text("info", "card", 4.5),
	text("info", "muted", 4.5),
	text("info", "info-muted", 4.5),
	text("warning", "background", 4.5),
	text("warning", "card", 4.5),
	text("warning", "muted", 4.5),
	text("warning", "warning-muted", 4.5),
	text("destructive", "background", 4.5),
	text("destructive", "card", 4.5),
	text("destructive", "muted", 4.5),
	ui("ring", "background", 3),
	passive("border", "background", 1.25),
	passive("input", "background", 1.25),
	passive("sidebar-border", "sidebar", 1.25),
]

const failures = []

for (const [themeName, tokens] of Object.entries(themes)) {
	for (const check of contrastChecks) {
		const foreground = readColor(tokens, check.foreground, themeName)
		const background = readColor(tokens, check.background, themeName)
		const contrast = wcagContrast(foreground, background)

		if (contrast < check.minimum) {
			failures.push({
				theme: themeName,
				type: check.type,
				foreground: check.foreground,
				background: check.background,
				minimum: check.minimum,
				contrast,
			})
		}
	}
}

if (failures.length > 0) {
	console.error("Theme contrast check failed:")
	for (const failure of failures) {
		console.error(
			`${failure.theme} ${failure.type}: --${failure.foreground} on --${failure.background} ` +
				`${failure.contrast.toFixed(2)} < ${failure.minimum}`
		)
	}
	process.exit(1)
}

console.log("Theme contrast check passed.")

function readTokens(selector) {
	const match = css.match(new RegExp(`${escapeRegex(selector)}\\s*\\{([\\s\\S]*?)\\n\\}`))
	if (!match) {
		throw new Error(`Unable to find ${selector} token block in ${CSS_PATH}`)
	}

	const tokens = new Map()
	const declarations = match[1]
	for (const declaration of declarations.matchAll(/--([a-z0-9-]+):\s*([^;]+);/g)) {
		tokens.set(declaration[1], declaration[2].trim())
	}

	return tokens
}

function readColor(tokens, token, themeName) {
	const value = tokens.get(token)
	if (!value) {
		throw new Error(`Missing --${token} token in ${themeName} theme`)
	}

	const color = parse(value)
	if (!color) {
		throw new Error(`Unable to parse --${token} as a color in ${themeName}: ${value}`)
	}

	return color
}

function text(foreground, background, minimum) {
	return { type: "text", foreground, background, minimum }
}

function ui(foreground, background, minimum) {
	return { type: "ui", foreground, background, minimum }
}

function passive(foreground, background, minimum) {
	return { type: "passive", foreground, background, minimum }
}

function escapeRegex(value) {
	return value.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")
}
