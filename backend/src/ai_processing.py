"""AI-powered skill extraction from TNA form submissions using Google Gemini.

This module processes the free-text fields from TNA submissions and extracts
the relevant skills that represent skill gaps, mapping them to the defined
31 skills list. Skills not in the list are returned as unmapped for HR review.

Requires GOOGLE_SERVICE_ACCOUNT_JSON to be configured for Gemini API access.
When no credentials are configured, the module falls back to keyword-based extraction.
"""

from __future__ import annotations

import json
import logging
from typing import TYPE_CHECKING

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from src.config import settings
from src.models import Employee, EmployeeStenScore, TnaFormSubmission

if TYPE_CHECKING:
    pass

logger = logging.getLogger(__name__)

DEFINED_SKILLS: list[str] = [
    "Learning Agility",
    "Service Orientation",
    "Process Orientation",
    "Planning",
    "Interpersonal Skills/ Social Competence",
    "Stress Management",
    "Communication",
    "Functional Proficiency",
    "Ethical Propensity",
    "Flexibility",
    "Quality Focus",
    "Training Delivery Skills",
    "Leadership",
    "Coaching skills",
    "Accountability",
    "Self-assurance",
    "Collaboration",
    "Critical thinking",
    "Functional Proficiency - Language",
    "Presentation skills",
    "Strategic Thinking",
    "Technical Skills",
    "Corporate skills",
    "Inclusion",
    "Self Management",
    "Communication Skills",
    "Negotiation Skills",
    "Technical Proficiency",
    "Result Orientation",
    "Networking",
    "Initiative Taking",
    "Innovation",
]

SKILL_KEYWORDS: dict[str, list[str]] = {
    "Learning Agility": ["learn", "adapt", "curiosity", "growth mindset", "upskill", "agility"],
    "Service Orientation": ["service", "customer", "client", "stakeholder satisf", "user"],
    "Process Orientation": ["process", "systematic", "procedur", "method", "standard", "workflow"],
    "Planning": ["plan", "organiz", "prioriti", "time manage", "schedul", "deadline"],
    "Interpersonal Skills/ Social Competence": ["interpersonal", "social", "rapport", "empathy"],
    "Stress Management": ["stress", "pressure", "burnout", "overwhelm", "calm", "resilien"],
    "Communication": ["communicat", "verbal", "written", "articulate", "express"],
    "Functional Proficiency": ["functional", "domain", "expertise", "proficien"],
    "Ethical Propensity": ["ethic", "integrity", "honest", "moral", "trust"],
    "Flexibility": ["flexib", "adapt", "change", "agile", "versatil", "open-minded"],
    "Quality Focus": ["quality", "attention to detail", "accuracy", "thorough", "precision"],
    "Training Delivery Skills": ["training", "facilitat", "instruct", "teach", "deliver"],
    "Leadership": ["leader", "vision", "influence", "direct", "guide", "mentor"],
    "Coaching skills": ["coach", "mentor", "develop others", "feedback", "guide"],
    "Accountability": ["accountab", "ownership", "responsible", "reliability", "dependab"],
    "Self-assurance": ["confidence", "self-assur", "asserti", "self-belief", "decisive"],
    "Collaboration": ["collaborat", "teamwork", "team player", "cooperat", "together"],
    "Critical thinking": ["critical think", "analy", "logic", "problem-solv", "reason"],
    "Functional Proficiency - Language": ["language", "english", "verbal", "grammar", "fluency"],
    "Presentation skills": ["presentat", "public speak", "slide", "demo"],
    "Strategic Thinking": ["strateg", "long-term", "vision", "big picture"],
    "Technical Skills": ["technical", "software", "system", "tool", "technology"],
    "Corporate skills": ["corporate", "business acumen", "professional", "etiquette"],
    "Inclusion": ["inclusi", "divers", "equit", "belonging", "respect"],
    "Self Management": ["self manage", "self-manage", "discipline", "autonomy", "self-regulat"],
    "Communication Skills": ["communicat", "listen", "articulate", "convers"],
    "Negotiation Skills": ["negotiat", "persuad", "bargain", "influence", "convinc"],
    "Technical Proficiency": ["technical", "it skill", "digital", "software"],
    "Result Orientation": ["result", "outcome", "goal", "target", "deliver", "achievement"],
    "Networking": ["network", "relationship", "stakeholder", "connect", "liaison"],
    "Initiative Taking": ["initiative", "proactive", "self-start", "drive", "motivat"],
    "Innovation": ["innovat", "creativ", "new ideas", "think outside"],
}

GAP_THRESHOLD = 5
MAX_EXTRACTED_SKILLS = 8


async def process_tna_submission(db: AsyncSession, submission_id: str) -> list[str]:
    """Process a TNA submission and extract relevant skills.

    Returns the list of extracted skill names (from the 31 defined skills).
    """
    submission = await db.get(TnaFormSubmission, submission_id)
    if submission is None:
        return []

    employee = (
        await db.execute(
            select(Employee).where(Employee.email == submission.employee_email)
        )
    ).scalar_one_or_none()

    sten_scores: EmployeeStenScore | None = None
    if employee:
        sten_scores = await db.get(EmployeeStenScore, employee.employee_id)

    google_creds = getattr(settings, "GOOGLE_SERVICE_ACCOUNT_JSON", None) or ""
    if google_creds and google_creds.strip().startswith("{"):
        result = await _extract_skills_with_gemini(submission, sten_scores, google_creds)
    else:
        result = _extract_skills_keyword_fallback(submission, sten_scores)

    # extracted_traits = raw AI-identified gaps (natural language)
    submission.extracted_traits = json.dumps(result.get("extracted", result["mapped"]))
    # extracted_skills = mapped to fixed skill list (used for course matching)
    submission.extracted_skills = json.dumps(result["mapped"])
    submission.unmapped_skills = json.dumps(result["unmapped"])
    submission.ai_processed = True
    await db.commit()

    return result["mapped"]


async def _extract_skills_with_gemini(
    submission: TnaFormSubmission,
    sten_scores: EmployeeStenScore | None,
    service_account_json: str,
) -> dict[str, list[str]]:
    """Call Google Gemini API to extract skills from the TNA text fields."""
    try:
        import httpx
        from google.oauth2 import service_account
        from google.auth.transport.requests import Request as GoogleAuthRequest
    except ImportError:
        logger.warning("Required packages not available, falling back to keyword extraction")
        return _extract_skills_keyword_fallback(submission, sten_scores)

    try:
        creds_dict = json.loads(service_account_json)
        credentials = service_account.Credentials.from_service_account_info(
            creds_dict,
            scopes=["https://www.googleapis.com/auth/generative-language", "https://www.googleapis.com/auth/cloud-platform"],
        )
        credentials.refresh(GoogleAuthRequest())
        access_token = credentials.token
    except Exception:
        logger.exception("Failed to get Google credentials")
        return _extract_skills_keyword_fallback(submission, sten_scores)

    skills_list = "\n".join(f"- {s}" for s in DEFINED_SKILLS)

    scores_context = ""
    if sten_scores:
        trait_map = {
            "accountability": "Accountability",
            "ethical_propensity": "Ethical Propensity",
            "self_assurance": "Self-assurance",
            "stress_management": "Stress Management",
            "learning_agility": "Learning Agility",
            "initiative_taking": "Initiative Taking",
            "collaboration": "Collaboration",
            "inclusion": "Inclusion",
            "networking": "Networking",
            "interpersonal_skills": "Interpersonal Skills/ Social Competence",
            "process_orientation": "Process Orientation",
            "result_orientation": "Result Orientation",
            "planning": "Planning",
            "service_orientation": "Service Orientation",
            "quality_focus": "Quality Focus",
            "flexibility": "Flexibility",
            "innovation": "Innovation",
        }
        low_scores = []
        for trait_key, skill_name in trait_map.items():
            score_val = getattr(sten_scores, trait_key, None)
            if score_val is not None and score_val < GAP_THRESHOLD:
                low_scores.append(f"{skill_name}: STEN score {score_val}")
        if low_scores:
            scores_context = f"\n\nEmployee's low Mettl assessment scores (indicating gaps):\n" + "\n".join(low_scores)

    prompt = f"""You are a training needs analyst. Analyze this TNA form and do TWO things:

STEP 1: Extract the raw skill gaps mentioned in the text (use natural language descriptions).
STEP 2: Map each extracted gap to the CLOSEST match from the DEFINED SKILLS LIST below. You MUST use the EXACT spelling from this list.

DEFINED SKILLS LIST (use these EXACT names in "mapped"):
{skills_list}

EMPLOYEE'S TNA ASSESSMENT:
Department: {submission.department}
Role: {submission.employee_role}

1. Performance/Skill Gaps identified: {submission.gap_description}
2. Business Impact: {submission.business_impact}
3. Capabilities/Skills Required: {submission.capabilities_required}
4. Expected Training Outcome: {submission.expected_training_outcome}
5. Additional Comments: {submission.additional_comments or "None"}
{scores_context}

IMPORTANT RULES:
- "mapped" MUST only contain values copied EXACTLY from the DEFINED SKILLS LIST above (case-sensitive, including special characters like "/")
- For example: use "Interpersonal Skills/ Social Competence" NOT "Communication" or "Interpersonal Skills"
- Use "Learning Agility" NOT "Learning ability"
- Use "Initiative Taking" NOT "Initiative"
- Use "Communication Skills" or "Communication" (both are in the list)
- "extracted" contains the raw natural-language gaps you identified from the text
- "unmapped" contains gaps that genuinely cannot be matched to ANY defined skill
- Return 5-8 mapped skills maximum

Return ONLY this JSON, no other text:
{{"extracted": ["raw gap 1", "raw gap 2", ...], "mapped": ["Exact Skill Name 1", "Exact Skill Name 2", ...], "unmapped": ["gap with no match", ...]}}"""

    try:
        url = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent"

        async with httpx.AsyncClient(timeout=60.0) as client:
            response = await client.post(
                url,
                headers={
                    "Authorization": f"Bearer {access_token}",
                    "Content-Type": "application/json",
                },
                json={
                    "contents": [{"role": "user", "parts": [{"text": prompt}]}],
                    "generationConfig": {
                        "temperature": 0.2,
                        "maxOutputTokens": 4096,
                        "responseMimeType": "application/json",
                    },
                },
            )
            response.raise_for_status()
            data = response.json()

            parts = data["candidates"][0]["content"]["parts"]
            text = parts[0]["text"].strip()

            result = json.loads(text)
            extracted = result.get("extracted", [])
            mapped = [s for s in result.get("mapped", []) if s in DEFINED_SKILLS]
            unmapped = result.get("unmapped", [])
            return {"extracted": extracted, "mapped": mapped[:MAX_EXTRACTED_SKILLS], "unmapped": unmapped}
    except Exception:
        logger.exception("Gemini skill extraction failed, using keyword fallback")
        return _extract_skills_keyword_fallback(submission, sten_scores)


def _extract_skills_keyword_fallback(
    submission: TnaFormSubmission,
    sten_scores: EmployeeStenScore | None,
) -> dict[str, list[str]]:
    """Extract skills using keyword matching as a fallback."""
    combined_text = " ".join([
        submission.gap_description,
        submission.business_impact,
        submission.capabilities_required,
        submission.expected_training_outcome,
        submission.additional_comments or "",
    ]).lower()

    skill_scores: dict[str, float] = {}
    for skill_name, keywords in SKILL_KEYWORDS.items():
        keyword_hits = sum(1 for kw in keywords if kw in combined_text)
        if keyword_hits > 0:
            score = keyword_hits
            # Boost if related Mettl trait has a low score
            if sten_scores:
                trait_key = _skill_to_trait(skill_name)
                if trait_key:
                    sten_val = getattr(sten_scores, trait_key, None)
                    if sten_val is not None and sten_val < GAP_THRESHOLD:
                        score += 2
            skill_scores[skill_name] = score

    sorted_skills = sorted(skill_scores, key=lambda k: skill_scores[k], reverse=True)
    mapped = sorted_skills[:MAX_EXTRACTED_SKILLS]
    return {"extracted": mapped, "mapped": mapped, "unmapped": []}


def _skill_to_trait(skill_name: str) -> str | None:
    """Map a skill name back to its Mettl trait key for score boosting."""
    mapping = {
        "Accountability": "accountability",
        "Ethical Propensity": "ethical_propensity",
        "Self-assurance": "self_assurance",
        "Stress Management": "stress_management",
        "Learning Agility": "learning_agility",
        "Initiative Taking": "initiative_taking",
        "Collaboration": "collaboration",
        "Inclusion": "inclusion",
        "Networking": "networking",
        "Interpersonal Skills/ Social Competence": "interpersonal_skills",
        "Process Orientation": "process_orientation",
        "Result Orientation": "result_orientation",
        "Planning": "planning",
        "Service Orientation": "service_orientation",
        "Quality Focus": "quality_focus",
        "Flexibility": "flexibility",
        "Innovation": "innovation",
    }
    return mapping.get(skill_name)
