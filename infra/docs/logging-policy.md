# Logging and Retention Policy

## Purpose

This document defines what logs are collected in GCP for this project, where they are stored, how long they are retained, and why those retention periods were selected.

## Scope

This policy applies to infrastructure managed by Terraform in:

- `infra/modules/gcp/deployment/logging.tf`

## Log Types and Retention

| Log type | GCP bucket | Retention | Why |
|---|---|---:|---|
| Operational and application logs (short-term audit log duplicates) | `_Default` | 30 days | Supports troubleshooting and short-term operational analysis while minimizing storage cost and unnecessary long-term retention. |
| Audit logs (except Data Access) | `audit-logs-<suffix>` | 2555 days (7 years) | Preserves security and compliance evidence for privileged/admin actions and policy/system events over long audit windows. |
| Audit Data Access logs (excluding selected Cloud Storage data-read logs) | `audit-data-access-logs-<suffix>` | 730 days (2 years) | Maintains forensic and access-tracing records for sensitive data access with lower storage overhead than 7-year retention, while avoiding long-retention volume from high-frequency object and related data-read activity. |
| Required audit logs (Google-managed) | `_Required` | 400 days (platform fixed) | GCP-required baseline retention for mandatory audit logs; this setting is managed by Google and not configurable. |

## Routing Rules

Terraform enforces the following routing:

- `_Default` bucket retention is set to 30 days and keeps all log types short-term (including audit logs).
- A sink routes non-Data Access audit logs to `audit-logs-<suffix>`.
- A sink routes Data Access audit logs except selected Cloud Storage data-read logs to `audit-data-access-logs-<suffix>`.
- Cloud Storage admin-read actions are still retained in the long-retention audit buckets.
- Only the selected Cloud Storage data-read logs that tend to be high-volume remain in `_Default` only, so canary bucket read alerts still have short-term log coverage without 730-day retention.
- Project-level exclusions are intentionally not used because they would drop audit logs from all sinks.

## Compliance Rationale (SOC 2)

These retention and routing controls support SOC 2 evidence expectations for monitoring, security investigation, and access traceability.

Relevant SOC 2 documentation and control frameworks:

- [AICPA SOC 2 Overview](https://www.aicpa-cima.com/topic/audit-assurance/audit-and-assurance-greater-than-soc-2)
- [AICPA Trust Services Criteria (controls)](https://www.aicpa-cima.com/resources/download/trust-services-criteria)

Control families primarily supported by this policy include:

- Common Criteria (CC), especially logical access and system operations monitoring
- Availability Criteria (A), especially operational monitoring and incident handling evidence

## Implementation Notes

- Cloud Audit Logs categories are defined by Google Cloud and include Admin Activity, System Event, Policy Denied, Data Access, and Access Transparency.
- Data Access logs may have delayed visibility depending on service and activity volume.
- Selected Cloud Storage data-read audit logs are intentionally excluded from the long-retention Data Access sink and retained only in `_Default`; Cloud Storage admin-read actions continue to flow to long-retention storage.
- Audit bucket names include a short random suffix that is stable across applies unless intentionally rotated.
- Policy updates to retention windows or bucket structure require Terraform review and approval.

## References

- [Cloud Logging buckets and retention](https://cloud.google.com/logging/docs/buckets)
- [Cloud Logging Log Router and sinks](https://cloud.google.com/logging/docs/routing/overview)
- [Cloud Audit Logs overview](https://cloud.google.com/logging/docs/audit)
