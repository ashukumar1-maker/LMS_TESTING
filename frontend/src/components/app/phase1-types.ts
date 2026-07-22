type TraitDefinition = {
	key: string
	label: string
}

type EmployeeRecord = {
	employee_id: string
	first_name: string
	last_name: string
	full_name: string
	email: string
	test_taker_id: string
	overall_status: string
	overall_score: number | null
	test_date: string
	gender: string
	date_of_birth: string
	contact_number: string
	is_valid: boolean
	scores: Record<string, number | null>
	gap_traits: string[]
	strengths_text: string
	areas_of_development_text: string
	response_style: string
}

type CourseRecord = {
	course_id: string
	course_name: string
	description: string
	department: string
	role_type: string
	level_1: boolean
	level_2: boolean
	level_3: boolean
	content_format: string
	is_lms_module: boolean
	training_duration_minutes: number | null
	primary_skill: string
	secondary_skill: string
}

type CourseRecommendation = {
	recommendation_id: string
	course: CourseRecord
	source: string
	matched_skills: string[]
	matched_traits: string[]
	rank: number
	is_mandatory: boolean
}

type TnaSubmission = {
	submission_id: string
	employee_email: string
	provana_email: string
	employee_name: string
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
	is_verified: boolean
	submitted_at: string
	ai_processed: boolean
	extracted_gaps: string[]
	extracted_skills: string[]
	unmapped_skills: string[]
}

type DashboardData = {
	traits: TraitDefinition[]
	defined_skills: string[]
	employees: EmployeeRecord[]
	courses: CourseRecord[]
	recommendations: Record<string, CourseRecommendation[]>
	submissions: TnaSubmission[]
}

export type {
	CourseRecord,
	CourseRecommendation,
	DashboardData,
	EmployeeRecord,
	TnaSubmission,
	TraitDefinition,
}
