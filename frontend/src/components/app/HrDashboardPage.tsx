import { useEffect, useMemo, useState } from "react"
import { BookOpenIcon, BrainCircuitIcon, ChevronDownIcon, ChevronRightIcon, ClipboardListIcon, ClockIcon, FileSpreadsheetIcon, RefreshCwIcon, SearchIcon, UsersIcon } from "lucide-react"
import { toast } from "sonner"

import BackendClient from "@/lib/BackendClient"
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Input } from "@/components/ui/input"
import {
	PageHeader,
	PageHeaderContent,
	PageHeaderDescription,
	PageHeaderMain,
	PageHeaderTitle,
} from "@/components/ui/page-header"
import { SidebarTrigger } from "@/components/ui/sidebar"
import type { CourseRecord, CourseRecommendation, DashboardData, EmployeeRecord, TnaSubmission, TraitDefinition } from "./phase1-types"

type DashboardSummary = {
	total_employees: number
	assessed_employees: number
	new_employees_7d: number
	total_courses: number
	total_recommendations: number
	total_tna_submissions: number
	pending_tna: number
	processed_tna: number
	employees_with_recommendations: number
	recommendation_coverage_pct: number
}

type Tab = "recommendations" | "courses" | "submissions"
const dashboardTabs: Tab[] = ["recommendations", "courses", "submissions"]

function HrDashboardPage() {
	const [data, setData] = useState<DashboardData | null>(null)
	const [summary, setSummary] = useState<DashboardSummary | null>(null)
	const [activeTab, setActiveTab] = useState<Tab>("recommendations")
	const [search, setSearch] = useState("")
	const [loading, setLoading] = useState(false)

	useEffect(() => {
		void loadDashboard()
	}, [])

	async function loadDashboard() {
		setLoading(true)
		try {
			const dashResponse = await BackendClient.get<DashboardData>("/phase1/hr/dashboard")
			setData(dashResponse.data)
			BackendClient.get<DashboardSummary>("/phase1/hr/dashboard/summary")
				.then((r) => setSummary(r.data))
				.catch(() => {})
		} finally {
			setLoading(false)
		}
	}

	async function uploadFile(kind: "mettl" | "courses", file: File | null) {
		if (!file) return
		const formData = new FormData()
		formData.append("file", file)
		const endpoint = kind === "mettl" ? "/phase1/hr/mettl-upload" : "/phase1/hr/courses-upload"
		const response = await BackendClient.post<{ loaded: number; invalid: number }>(endpoint, formData)
		toast.success(`Loaded ${response.data.loaded} records.`)
		await loadDashboard()
	}

	const employees = useMemo(() => filterEmployees(data?.employees ?? [], search), [data, search])

	return (
		<>
			<DashboardHeader />
			<main className="relative flex-1 bg-background text-foreground">
				<SidebarTrigger className="absolute top-4 left-4 md:hidden" />
				<div className="container grid gap-5 py-5">
					{summary ? <OverviewStats summary={summary} /> : null}
					<UploadPanel onUpload={uploadFile} refreshing={loading} reload={loadDashboard} />
					<TabButtons activeTab={activeTab} onTabChange={setActiveTab} />
					{activeTab === "recommendations" && data ? (
						<RecommendationsView data={data} employees={employees} search={search} setSearch={setSearch} />
					) : null}
					{activeTab === "courses" && data ? (
						<CoursesView courses={data.courses} />
					) : null}
					{activeTab === "submissions" && data ? <SubmissionsView data={data} /> : null}
				</div>
			</main>
		</>
	)
}

function OverviewStats({ summary }: { summary: DashboardSummary }) {
	return (
		<div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-4">
			<StatCard
				icon={<UsersIcon className="size-4 text-muted-foreground" />}
				label="Total employees"
				value={summary.total_employees}
				sub={`${summary.new_employees_7d} new in last 7 days`}
			/>
			<StatCard
				icon={<BrainCircuitIcon className="size-4 text-muted-foreground" />}
				label="Assessed (Mettl)"
				value={summary.assessed_employees}
				sub={`${summary.recommendation_coverage_pct}% have recommendations`}
			/>
			<StatCard
				icon={<ClipboardListIcon className="size-4 text-muted-foreground" />}
				label="TNA submissions"
				value={summary.total_tna_submissions}
				sub={`${summary.pending_tna} pending AI processing`}
			/>
			<StatCard
				icon={<BookOpenIcon className="size-4 text-muted-foreground" />}
				label="Courses in repository"
				value={summary.total_courses}
				sub={`${summary.total_recommendations} recommendations generated`}
			/>
		</div>
	)
}

function StatCard({ icon, label, value, sub }: { icon: React.ReactNode; label: string; value: number; sub: string }) {
	return (
		<Card>
			<CardContent className="flex flex-col gap-1 p-4">
				<div className="flex items-center gap-2">
					{icon}
					<span className="text-xs font-medium text-muted-foreground">{label}</span>
				</div>
				<span className="text-2xl font-semibold">{value}</span>
				<span className="text-xs text-muted-foreground">{sub}</span>
			</CardContent>
		</Card>
	)
}

function DashboardHeader() {
	return (
		<PageHeader>
			<PageHeaderMain className="pl-14 md:pl-6 lg:pl-8">
				<PageHeaderContent>
					<PageHeaderTitle>HR Training Dashboard</PageHeaderTitle>
					<PageHeaderDescription>Upload Mettl scores, manage courses, and review skill-based recommendations.</PageHeaderDescription>
				</PageHeaderContent>
			</PageHeaderMain>
		</PageHeader>
	)
}

function UploadPanel({
	onUpload,
	refreshing,
	reload,
}: {
	onUpload: (kind: "mettl" | "courses", file: File | null) => Promise<void>
	refreshing: boolean
	reload: () => Promise<void>
}) {
	return (
		<Card>
			<CardHeader>
				<CardTitle className="flex items-center gap-2">
					<FileSpreadsheetIcon className="size-4" />
					File Uploads
				</CardTitle>
				<CardDescription>Load the Mettl score file and the Learning Content Repository.</CardDescription>
			</CardHeader>
			<CardContent className="grid gap-3 md:grid-cols-[1fr_1fr_auto]">
				<FileUpload label="Mettl Personality Profiler" onChange={(file) => void onUpload("mettl", file)} />
				<FileUpload label="Learning Content Repository" onChange={(file) => void onUpload("courses", file)} />
				<Button loading={refreshing} onClick={() => void reload()} type="button" variant="outline">
					<RefreshCwIcon />
					Refresh
				</Button>
			</CardContent>
		</Card>
	)
}

function FileUpload({ label, onChange }: { label: string; onChange: (file: File | null) => void }) {
	return (
		<label className="grid gap-1 text-sm font-medium">
			{label}
			<Input accept=".xlsx" onChange={(event) => onChange(event.target.files?.[0] ?? null)} type="file" />
		</label>
	)
}

function TabButtons({
	activeTab,
	onTabChange,
}: {
	activeTab: Tab
	onTabChange: (tab: Tab) => void
}) {
	return (
		<div className="flex flex-wrap gap-2">
			{dashboardTabs.map((tab) => (
				<Button
					key={tab}
					onClick={() => onTabChange(tab)}
					type="button"
					variant={activeTab === tab ? "default" : "outline"}
				>
					{tabLabel(tab)}
				</Button>
			))}
		</div>
	)
}

function RecommendationsView({
	data,
	employees,
	search,
	setSearch,
}: {
	data: DashboardData
	employees: EmployeeRecord[]
	search: string
	setSearch: (value: string) => void
}) {
	const [expandedEmail, setExpandedEmail] = useState<string | null>(null)

	function toggle(email: string) {
		setExpandedEmail((prev) => (prev === email ? null : email))
	}

	return (
		<div className="grid gap-3">
			<SearchBox search={search} setSearch={setSearch} />
			<div className="grid gap-2">
				{employees.map((employee) => (
					<EmployeeRow
						key={employee.email}
						employee={employee}
						data={data}
						isExpanded={expandedEmail === employee.email}
						onToggle={() => toggle(employee.email)}
					/>
				))}
			</div>
		</div>
	)
}

function SearchBox({ search, setSearch }: { search: string; setSearch: (value: string) => void }) {
	return (
		<div className="relative max-w-xl">
			<SearchIcon className="absolute top-2.5 left-3 size-4 text-muted-foreground" />
			<Input className="pl-9" onChange={(event) => setSearch(event.target.value)} placeholder="Search by name or email" value={search} />
		</div>
	)
}

function EmployeeRow({
	employee,
	data,
	isExpanded,
	onToggle,
}: {
	employee: EmployeeRecord
	data: DashboardData
	isExpanded: boolean
	onToggle: () => void
}) {
	const recs = data.recommendations[employee.email] ?? []
	const submission = data.submissions.find((s) => s.employee_email === employee.email)
	const hasTna = !!submission

	return (
		<Card>
			<button
				type="button"
				onClick={onToggle}
				className="flex w-full items-center gap-3 px-4 py-3 text-left hover:bg-muted/50 transition-colors"
			>
				{isExpanded ? (
					<ChevronDownIcon className="size-4 shrink-0 text-muted-foreground" />
				) : (
					<ChevronRightIcon className="size-4 shrink-0 text-muted-foreground" />
				)}
				<div className="flex flex-1 items-center justify-between gap-2">
					<div>
						<span className="font-medium">{employee.full_name || employee.email}</span>
						<span className="ml-2 text-sm text-muted-foreground">{employee.email}</span>
					</div>
					<div className="flex items-center gap-3">
						{hasTna ? (
							<span className="rounded-full bg-green-100 px-2 py-0.5 text-xs font-medium text-green-700">TNA Submitted</span>
						) : (
							<span className="rounded-full bg-yellow-100 px-2 py-0.5 text-xs font-medium text-yellow-700">Awaiting TNA</span>
						)}
						{recs.length > 0 ? (
							<span className="text-xs text-muted-foreground">{recs.length} course{recs.length !== 1 ? "s" : ""}</span>
						) : null}
					</div>
				</div>
			</button>

			{isExpanded ? (
				<EmployeeExpandedView employee={employee} data={data} submission={submission} recs={recs} />
			) : null}
		</Card>
	)
}

function EmployeeExpandedView({
	employee,
	data,
	submission,
	recs,
}: {
	employee: EmployeeRecord
	data: DashboardData
	submission: TnaSubmission | undefined
	recs: CourseRecommendation[]
}) {
	return (
		<div className="border-t px-4 py-4 grid gap-5">
			{/* Section 1: Mettl Assessment */}
			<section>
				<h4 className="text-sm font-semibold mb-2 flex items-center gap-2">
					<BrainCircuitIcon className="size-4" />
					Mettl Personality Assessment
				</h4>
				<div className="rounded-md border p-3 grid gap-2">
					<div className="flex flex-wrap items-center gap-2 text-sm">
						<span><strong>Email:</strong> {employee.email}</span>
						{!employee.email.toLowerCase().endsWith("@provana.com") ? (
							<span className="rounded bg-red-100 px-2 py-0.5 text-xs font-medium text-red-700">
								Non-Provana email — must fill Provana email in TNA form
							</span>
						) : null}
						{submission?.provana_email ? (
							<span className="rounded bg-green-100 px-2 py-0.5 text-xs font-medium text-green-700">
								Provana: {submission.provana_email}
							</span>
						) : null}
					</div>
					<div className="flex flex-wrap gap-4 text-sm">
						<span><strong>Status:</strong> {employee.overall_status}</span>
						<span><strong>Score:</strong> {employee.overall_score ?? "N/A"}</span>
						<span><strong>Test Date:</strong> {employee.test_date || "N/A"}</span>
					</div>
					{employee.gap_traits.length > 0 ? (
						<div>
							<span className="text-xs font-medium">Trait Gaps:</span>
							<div className="flex flex-wrap gap-1 mt-1">
								{employee.gap_traits.map((trait) => {
									const label = data.traits.find((t) => t.key === trait)?.label ?? trait
									return (
										<span key={trait} className="rounded bg-red-100 px-2 py-0.5 text-xs text-red-700">{label}</span>
									)
								})}
							</div>
						</div>
					) : (
						<p className="text-xs text-muted-foreground">No significant trait gaps detected (all scores adequate).</p>
					)}
					{employee.areas_of_development_text ? (
						<p className="text-xs text-muted-foreground whitespace-pre-wrap">{employee.areas_of_development_text}</p>
					) : null}
				</div>
			</section>

			{/* Section 2: TNA Feedback */}
			<section>
				<h4 className="text-sm font-semibold mb-2 flex items-center gap-2">
					<ClipboardListIcon className="size-4" />
					TNA Supervisor Feedback
				</h4>
				{submission ? (
					<div className="rounded-md border p-3 grid gap-2">
						<div className="flex flex-wrap gap-4 text-xs text-muted-foreground">
							<span><strong>Supervisor:</strong> {submission.supervisor_name}</span>
							<span><strong>Department:</strong> {submission.department}</span>
							<span><strong>Role:</strong> {submission.employee_role}</span>
						</div>
						<div className="grid gap-1 text-sm">
							<p><strong className="text-xs">Performance Gaps:</strong> {submission.gap_description}</p>
							<p><strong className="text-xs">Business Impact:</strong> {submission.business_impact}</p>
							<p><strong className="text-xs">Capabilities Required:</strong> {submission.capabilities_required}</p>
							<p><strong className="text-xs">Expected Outcome:</strong> {submission.expected_training_outcome}</p>
						</div>
						{submission.extracted_gaps.length > 0 ? (
							<div>
								<span className="text-xs font-medium">Extracted Gaps (AI Analysis):</span>
								<div className="flex flex-wrap gap-1 mt-1">
									{submission.extracted_gaps.map((gap) => (
										<span key={gap} className="rounded bg-gray-100 px-2 py-0.5 text-xs text-gray-700">{gap}</span>
									))}
								</div>
							</div>
						) : null}
						{submission.extracted_skills.length > 0 ? (
							<div>
								<span className="text-xs font-medium text-blue-700">Mapped Skills (used for course matching):</span>
								<div className="flex flex-wrap gap-1 mt-1">
									{submission.extracted_skills.map((skill) => (
										<span key={skill} className="rounded bg-blue-100 px-2 py-0.5 text-xs text-blue-700">{skill}</span>
									))}
								</div>
							</div>
						) : null}
						{submission.unmapped_skills.length > 0 ? (
							<div>
								<span className="text-xs font-medium text-orange-600">Unmapped Gaps (no course available):</span>
								<div className="flex flex-wrap gap-1 mt-1">
									{submission.unmapped_skills.map((skill) => (
										<span key={skill} className="rounded bg-orange-100 px-2 py-0.5 text-xs text-orange-700">{skill}</span>
									))}
								</div>
							</div>
						) : null}
					</div>
				) : (
					<div className="rounded-md border border-dashed p-4 flex items-center gap-3 text-muted-foreground">
						<ClockIcon className="size-5" />
						<span className="text-sm">Waiting for TNA response</span>
					</div>
				)}
			</section>

			{/* Section 3: Recommended Courses */}
			<section>
				<h4 className="text-sm font-semibold mb-2 flex items-center gap-2">
					<BookOpenIcon className="size-4" />
					Recommended Courses
				</h4>
				{recs.length > 0 ? (
					<div className="grid gap-2">
						{recs.map((rec) => (
							<RecommendationRow key={rec.recommendation_id} rec={rec} />
						))}
					</div>
				) : submission ? (
					<p className="text-sm text-muted-foreground">No matching courses found for extracted skills. Upload the updated Course Repository to generate recommendations.</p>
				) : (
					<div className="rounded-md border border-dashed p-4 flex items-center gap-3 text-muted-foreground">
						<ClockIcon className="size-5" />
						<span className="text-sm">Waiting for TNA response to generate course recommendations</span>
					</div>
				)}
			</section>
		</div>
	)
}

function RecommendationRow({ rec }: { rec: CourseRecommendation }) {
	return (
		<div className="rounded-md border p-3">
			<div className="flex flex-wrap items-center justify-between gap-2">
				<div className="font-medium text-sm">{rec.course.course_name}</div>
				<div className="flex items-center gap-2">
					{rec.is_mandatory ? <span className="text-xs font-medium text-destructive">Mandatory</span> : null}
					<span className="rounded bg-muted px-2 py-0.5 text-xs">{rec.source === "tna" ? "TNA-based" : "Mettl-based"}</span>
				</div>
			</div>
			<p className="mt-1 text-xs text-muted-foreground">{rec.course.description}</p>
			<div className="mt-2 flex flex-wrap items-center gap-3 text-xs text-muted-foreground">
				<span>{rec.course.department}</span>
				<span>{rec.course.training_duration_minutes ?? "N/A"} min</span>
				<span>{rec.course.content_format}</span>
			</div>
			{rec.matched_skills.length > 0 ? (
				<div className="mt-2 flex flex-wrap gap-1">
					{rec.matched_skills.map((skill) => (
						<span key={skill} className="rounded bg-green-100 px-2 py-0.5 text-xs text-green-700">{skill}</span>
					))}
				</div>
			) : null}
		</div>
	)
}

function CoursesView({ courses }: { courses: CourseRecord[] }) {
	return (
		<div className="grid gap-3">
			{courses.map((course) => (
				<Card key={course.course_id}>
					<CardHeader>
						<CardTitle>{course.course_name}</CardTitle>
						<CardDescription>{course.department} · {course.role_type} · {course.training_duration_minutes ?? "N/A"} min</CardDescription>
					</CardHeader>
					<CardContent className="grid gap-2">
						<p className="text-sm text-muted-foreground">{course.description}</p>
						<div className="flex flex-wrap gap-2">
							<span className="rounded bg-blue-100 px-2 py-0.5 text-xs text-blue-700">Primary: {course.primary_skill || "Not set"}</span>
							<span className="rounded bg-purple-100 px-2 py-0.5 text-xs text-purple-700">Secondary: {course.secondary_skill || "Not set"}</span>
						</div>
						<div className="flex flex-wrap gap-2 text-xs text-muted-foreground">
							{course.level_1 ? <span className="rounded bg-muted px-2 py-0.5">Level 1</span> : null}
							{course.level_2 ? <span className="rounded bg-muted px-2 py-0.5">Level 2</span> : null}
							{course.level_3 ? <span className="rounded bg-muted px-2 py-0.5">Level 3</span> : null}
						</div>
					</CardContent>
				</Card>
			))}
		</div>
	)
}

function SubmissionsView({ data }: { data: DashboardData }) {
	return (
		<div className="grid gap-3">
			<div className="flex items-center justify-between">
				<p className="text-sm text-muted-foreground">{data.submissions.length} submission{data.submissions.length !== 1 ? "s" : ""}</p>
				<a href="/tna" target="_blank" rel="noopener noreferrer">
					<Button variant="outline" type="button">
						<ClipboardListIcon className="size-4" />
						Open TNA form
					</Button>
				</a>
			</div>
			{data.submissions.length === 0 ? (
				<Card>
					<CardContent className="flex flex-col items-center gap-2 py-10 text-center">
						<ClipboardListIcon className="size-8 text-muted-foreground" />
						<p className="text-sm font-medium">No TNA submissions yet</p>
						<p className="text-xs text-muted-foreground">Share the TNA form with supervisors to collect skill gap assessments.</p>
						<a href="/tna" target="_blank" rel="noopener noreferrer">
							<Button variant="secondary" type="button" className="mt-2">Go to TNA form</Button>
						</a>
					</CardContent>
				</Card>
			) : null}
			{data.submissions.map((submission) => (
				<Card key={submission.submission_id}>
					<CardHeader>
						<CardTitle>{submission.employee_name}</CardTitle>
						<CardDescription>{submission.employee_email} · {submission.department} · {submission.employee_role}</CardDescription>
					</CardHeader>
					<CardContent className="grid gap-2 text-sm">
						<p><strong>Performance gaps:</strong> {submission.gap_description}</p>
						<p><strong>Business impact:</strong> {submission.business_impact}</p>
						<p><strong>Capabilities:</strong> {submission.capabilities_required}</p>
						<p><strong>Expected outcome:</strong> {submission.expected_training_outcome}</p>
						{submission.additional_comments ? <p><strong>Comments:</strong> {submission.additional_comments}</p> : null}
						{submission.extracted_skills.length > 0 ? (
							<div className="flex flex-wrap gap-1 mt-1">
								<span className="text-xs font-medium">Skills:</span>
								{submission.extracted_skills.map((skill) => (
									<span key={skill} className="rounded bg-blue-100 px-2 py-0.5 text-xs text-blue-700">{skill}</span>
								))}
							</div>
						) : null}
					</CardContent>
				</Card>
			))}
		</div>
	)
}

function filterEmployees(employees: EmployeeRecord[], search: string) {
	const query = search.toLowerCase()
	return employees.filter((employee) =>
		employee.is_valid && `${employee.full_name} ${employee.email}`.toLowerCase().includes(query)
	)
}

function tabLabel(tab: Tab) {
	if (tab === "recommendations") return "Recommendations"
	if (tab === "courses") return "Course Repository"
	return "TNA Submissions"
}

export { HrDashboardPage }
