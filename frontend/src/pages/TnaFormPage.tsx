import { useState } from "react"
import { toast } from "sonner"

import BackendClient from "@/lib/BackendClient"
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Input } from "@/components/ui/input"

type LookupResult = {
	employee_id: string
	employee_email: string
	employee_name: string
}

type FormState = {
	provana_email: string
	department: string
	team: string
	employee_role: string
	supervisor_name: string
	assessment_period: string
	gap_description: string
	business_impact: string
	capabilities_required: string
	expected_training_outcome: string
	additional_comments: string
	hr_id_entered: string
}

const emptyForm: FormState = {
	provana_email: "",
	department: "",
	team: "",
	employee_role: "",
	supervisor_name: "",
	assessment_period: "",
	gap_description: "",
	business_impact: "",
	capabilities_required: "",
	expected_training_outcome: "",
	additional_comments: "",
	hr_id_entered: "",
}

function TnaFormPage() {
	const [query, setQuery] = useState("")
	const [employee, setEmployee] = useState<LookupResult | null>(null)
	const [form, setForm] = useState<FormState>(emptyForm)
	const [error, setError] = useState<string | null>(null)
	const [loading, setLoading] = useState(false)

	async function lookupEmployee(event: React.FormEvent<HTMLFormElement>) {
		event.preventDefault()
		setError(null)
		try {
			const response = await BackendClient.get<LookupResult>("/phase1/public/employee-lookup", {
				params: { query },
			})
			setEmployee(response.data)
		} catch (lookupError) {
			setEmployee(null)
			setError(lookupError instanceof Error ? lookupError.message : "Employee not found.")
		}
	}

	async function submitForm(event: React.FormEvent<HTMLFormElement>) {
		event.preventDefault()
		if (!employee) return
		const validationError = validateForm(form)
		if (validationError) {
			setError(validationError)
			return
		}
		setLoading(true)
		setError(null)
		try {
			await BackendClient.post("/phase1/public/tna-submissions", {
				employee_email: employee.employee_email,
				employee_name: employee.employee_name,
				employee_id_entered: employee.employee_id,
				provana_email: form.provana_email,
				department: form.department,
				team: form.team,
				employee_role: form.employee_role,
				supervisor_name: form.supervisor_name,
				assessment_period: form.assessment_period,
				gap_description: form.gap_description,
				business_impact: form.business_impact,
				capabilities_required: form.capabilities_required,
				expected_training_outcome: form.expected_training_outcome,
				additional_comments: form.additional_comments,
				hr_id_entered: form.hr_id_entered,
			})
			setForm(emptyForm)
			toast.success("Training Needs Assessment submitted.")
		} catch (submitError) {
			setError(submitError instanceof Error ? submitError.message : "Submission failed.")
		} finally {
			setLoading(false)
		}
	}

	return (
		<main className="min-h-svh bg-background p-4 text-foreground md:p-8">
			<div className="mx-auto grid max-w-3xl gap-5">
				<header>
					<h1 className="text-2xl font-medium">Training Needs Assessment</h1>
					<p className="text-sm text-muted-foreground">Enter an employee email, employee ID, or Mettl test-taker ID to begin.</p>
				</header>
				<LookupCard lookupEmployee={lookupEmployee} query={query} setQuery={setQuery} />
				{error ? <div className="rounded-md border border-destructive/30 bg-destructive/10 p-3 text-sm text-destructive">{error}</div> : null}
				{employee ? (
					<EmployeeIdentityCard employee={employee} />
				) : null}
				{employee ? <TnaForm employee={employee} form={form} loading={loading} setForm={setForm} submitForm={submitForm} /> : null}
			</div>
		</main>
	)
}

function EmployeeIdentityCard({ employee }: { employee: LookupResult }) {
	return (
		<Card>
			<CardHeader>
				<CardTitle>Matched Employee</CardTitle>
				<CardDescription>This employee was found in the Mettl assessment database.</CardDescription>
			</CardHeader>
			<CardContent>
				<div className="grid gap-2 text-sm md:grid-cols-3">
					<div>
						<span className="font-medium text-muted-foreground">Name</span>
						<p>{employee.employee_name || "—"}</p>
					</div>
					<div>
						<span className="font-medium text-muted-foreground">Email</span>
						<p>{employee.employee_email}</p>
					</div>
					<div>
						<span className="font-medium text-muted-foreground">Employee ID</span>
						<p className="font-mono text-xs">{employee.employee_id}</p>
					</div>
				</div>
			</CardContent>
		</Card>
	)
}

function LookupCard({
	lookupEmployee,
	query,
	setQuery,
}: {
	lookupEmployee: (event: React.FormEvent<HTMLFormElement>) => Promise<void>
	query: string
	setQuery: (query: string) => void
}) {
	return (
		<Card>
			<CardHeader>
				<CardTitle>Employee Lookup</CardTitle>
				<CardDescription>Search by email, employee ID, or Mettl test-taker ID.</CardDescription>
			</CardHeader>
			<CardContent>
				<LookupForm lookupEmployee={lookupEmployee} query={query} setQuery={setQuery} />
			</CardContent>
		</Card>
	)
}

function LookupForm({
	lookupEmployee,
	query,
	setQuery,
}: {
	lookupEmployee: (event: React.FormEvent<HTMLFormElement>) => Promise<void>
	query: string
	setQuery: (query: string) => void
}) {
	return (
		<form className="flex gap-2" onSubmit={lookupEmployee}>
			<Input
				onChange={(event) => setQuery(event.target.value)}
				placeholder="Email, Employee ID, or Test-taker ID"
				value={query}
			/>
			<Button type="submit">Find</Button>
		</form>
	)
}

function TnaForm({
	employee,
	form,
	loading,
	setForm,
	submitForm,
}: {
	employee: LookupResult
	form: FormState
	loading: boolean
	setForm: (form: FormState) => void
	submitForm: (event: React.FormEvent<HTMLFormElement>) => Promise<void>
}) {
	return (
		<Card>
			<CardHeader>
				<CardTitle>{employee.employee_name}</CardTitle>
				<CardDescription>{employee.employee_email}</CardDescription>
			</CardHeader>
			<CardContent>
				<form className="grid gap-4" onSubmit={submitForm}>
					<div className="rounded-md border border-blue-200 bg-blue-50 p-3">
						<label className="grid gap-1 text-sm font-medium">
							<span>Provana Email (@provana.com) <span className="text-destructive">*</span></span>
							<Input
								required
								type="email"
								placeholder="firstname.lastname@provana.com"
								pattern="[a-zA-Z0-9._%+\-]+@provana\.com"
								title="Must be a valid @provana.com email address"
								onChange={(event) => setForm({ ...form, provana_email: event.target.value })}
								value={form.provana_email}
							/>
							<span className="text-xs text-muted-foreground">Required for LMS (Moodle) integration. Enter your official Provana email address.</span>
						</label>
					</div>
					<div className="grid gap-3 md:grid-cols-2">
						<TextInput form={form} name="department" setForm={setForm} title="Department" />
						<TextInput form={form} name="team" setForm={setForm} title="Team" />
						<TextInput form={form} name="employee_role" setForm={setForm} title="Employee Role" />
						<TextInput form={form} name="supervisor_name" setForm={setForm} title="Supervisor Name" />
						<TextInput form={form} name="assessment_period" setForm={setForm} title="Assessment Period" />
						<TextInput form={form} name="hr_id_entered" setForm={setForm} title="HR Verification ID" />
					</div>
					<LongInput form={form} name="gap_description" setForm={setForm} title="Describe the current performance gaps observed in this role" />
					<LongInput form={form} name="business_impact" setForm={setForm} title="What business impact are these gaps creating" />
					<LongInput form={form} name="capabilities_required" setForm={setForm} title="What capabilities should the employee develop" />
					<LongInput form={form} name="expected_training_outcome" setForm={setForm} title="What training outcome is expected" />
					<LongInput form={form} name="additional_comments" required={false} setForm={setForm} title="Additional comments" />
					<Button loading={loading} type="submit">Submit TNA</Button>
				</form>
			</CardContent>
		</Card>
	)
}

function TextInput({
	form,
	name,
	setForm,
	title,
}: {
	form: FormState
	name: keyof FormState
	setForm: (form: FormState) => void
	title: string
}) {
	return (
		<label className="grid gap-1 text-sm font-medium">
			{title}
			<Input required onChange={(event) => setForm({ ...form, [name]: event.target.value })} value={form[name]} />
		</label>
	)
}

function LongInput({
	form,
	name,
	required = true,
	setForm,
	title,
}: {
	form: FormState
	name: keyof FormState
	required?: boolean
	setForm: (form: FormState) => void
	title: string
}) {
	const words = form[name].split(/\s+/).filter(Boolean).length
	return (
		<label className="grid gap-1 text-sm font-medium">
			{title}
			<textarea
				className="min-h-28 rounded-md border border-input bg-transparent px-3 py-2 text-sm outline-none focus-visible:ring-2 focus-visible:ring-ring/50"
				onChange={(event) => setForm({ ...form, [name]: event.target.value })}
				required={required}
				value={form[name]}
			/>
			{required ? <span className="text-xs text-muted-foreground">{words}/50 words minimum</span> : null}
		</label>
	)
}

function validateForm(form: FormState) {
	if (!form.provana_email || !form.provana_email.toLowerCase().endsWith("@provana.com")) {
		return "Provana Email is required and must be a valid @provana.com email address."
	}
	const requiredTextAreas: (keyof FormState)[] = [
		"gap_description",
		"business_impact",
		"capabilities_required",
		"expected_training_outcome",
	]
	for (const field of requiredTextAreas) {
		if (form[field].split(/\s+/).filter(Boolean).length < 50) {
			return "Each required narrative response must contain at least 50 words."
		}
	}
	return null
}

export default TnaFormPage
