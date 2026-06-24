import { dirname } from "node:path"
import { fileURLToPath } from "node:url"
import js from "@eslint/js"
import importPlugin from "eslint-plugin-import"
import react from "eslint-plugin-react"
import globals from "globals"
import reactHooks from "eslint-plugin-react-hooks"
import reactRefresh from "eslint-plugin-react-refresh"
import tailwindcss from "eslint-plugin-tailwindcss"
import tseslint from "typescript-eslint"

const tsconfigRootDir = dirname(fileURLToPath(import.meta.url))

export default tseslint.config(
	{ ignores: ["dist"] },
	{
		extends: [js.configs.recommended, ...tseslint.configs.recommended],
		files: ["**/*.{ts,tsx}"],
		languageOptions: {
			ecmaVersion: 2020,
			globals: globals.browser,
			parserOptions: {
				ecmaFeatures: {
					jsx: true,
				},
				projectService: true,
				tsconfigRootDir: tsconfigRootDir,
			},
		},
		plugins: {
			import: importPlugin,
			react: react,
			"react-hooks": reactHooks,
			"react-refresh": reactRefresh,
			tailwindcss: tailwindcss,
		},
		rules: {
			...reactHooks.configs.recommended.rules,
			"@typescript-eslint/no-explicit-any": "error",
			"@typescript-eslint/no-non-null-assertion": "error",
			"@typescript-eslint/no-unnecessary-type-assertion": "error",
			complexity: ["error", 12],
			"react-refresh/only-export-components": ["warn", { allowConstantExport: true }],
			"@typescript-eslint/no-unused-vars": "warn",
			"@typescript-eslint/no-unsafe-argument": "error",
			"@typescript-eslint/no-unsafe-assignment": "error",
			"@typescript-eslint/no-unsafe-call": "error",
			"@typescript-eslint/no-unsafe-member-access": "error",
			"@typescript-eslint/no-unsafe-return": "error",
			"@typescript-eslint/switch-exhaustiveness-check": "error",
			"import/no-cycle": "error",
			"import/no-self-import": "error",
			"max-depth": ["error", 3],
			"max-lines": ["error", { max: 300, skipBlankLines: true, skipComments: true }],
			"max-lines-per-function": ["error", { max: 80, skipBlankLines: true, skipComments: true }],
			"max-nested-callbacks": ["error", 3],
			"max-params": ["error", 4],
			"no-restricted-syntax": [
				"error",
				{
					selector:
						"TSAsExpression:not([typeAnnotation.type='TSTypeReference'][typeAnnotation.typeName.name='const'])",
					message:
						"Type assertions are banned. Prefer narrowing, parser/schema validation, or an eslint-disable with justification.",
				},
				{
					selector: "TSTypeAssertion",
					message:
						"Type assertions are banned. Prefer narrowing, parser/schema validation, or an eslint-disable with justification.",
				},
			],
			"react/jsx-max-depth": ["error", { max: 4 }],
			"react/jsx-no-constructed-context-values": "error",
			"react/no-unstable-nested-components": "error",
			"react-hooks/immutability": "off",
			"react-hooks/purity": "off",
			"react-hooks/set-state-in-effect": "off",
			// Enforce semantic design tokens - no custom/invalid Tailwind classes
			"tailwindcss/no-custom-classname": [
				"error",
				{
					whitelist: [
						"^(group|peer)(/[A-Za-z0-9_-]+)?$",
						"^(default|horizontal|vertical|responsive|xs|inline-start)$",
						"^(text-meta|font-heading|font-control|font-strong)$",
						"^.*(bg|text|border|fill|outline|ring)-(background|foreground|card|card-foreground|popover|popover-foreground|primary|primary-foreground|secondary|secondary-foreground|muted|muted-foreground|accent|accent-foreground|destructive|destructive-foreground|surface|surface-foreground|surface-inverse|surface-inverse-foreground|success|success-foreground|success-muted|info|info-foreground|info-muted|warning|warning-foreground|warning-muted|input|border|ring|overlay|table-header-foreground|chart-[1-5]|sidebar|sidebar-foreground|sidebar-primary|sidebar-primary-foreground|sidebar-accent|sidebar-accent-foreground|sidebar-border|sidebar-ring)(/\\d+)?$",
						"^.*ring-offset-background$",
						"^.*shadow-sidebar-ring(-hover)?$",
					],
				},
			],
		},
		settings: {
			"import/extensions": [".js", ".jsx", ".ts", ".tsx"],
			"import/parsers": {
				"@typescript-eslint/parser": [".ts", ".tsx"],
			},
			"import/resolver": {
				node: {
					extensions: [".js", ".jsx", ".ts", ".tsx"],
				},
			},
			react: {
				version: "detect",
			},
			tailwindcss: {
				config: {},
				cssFiles: [`${tsconfigRootDir}/src/index.css`],
			},
		},
	}
)
