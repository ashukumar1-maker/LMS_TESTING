# Azure CDN Invalidate CD Step

Defines the Azure-specific Argo `Template` for the `cdn-invalidate` workflow
task.

## Responsibilities

- Authenticates to Azure with Workload Identity through `az login --service-principal`.
- Purges the Azure Front Door endpoint cache for the frontend custom domain.

## Workflow Integration

- Argo template name: `cdn-invalidate`
- DAG task name: `cdn-invalidate`
- Runs after `frontend-upload` succeeds.
- Runs only in `FRONTEND_ONLY` or `FULL` deployment modes when
  `frontend-deploy-needed` is `true`.
- Successful completion is required before `record-final-frontend-cd-state`.

The shared workflow schedules this task after frontend upload so Azure and GCP
environments keep the same DAG shape.

## Key Inputs

- `step_service_account_name`: Kubernetes service account used by the Argo step.
  Wired from the `cdn_invalidator` workflow identity in
  `infra/modules/azure/ci_cd`.
- `azure_subscription_id`: Subscription used by the Azure CLI purge command.
- `resource_group_name`: Resource group containing the Azure Front Door profile.
- `frontdoor_profile_name`: Azure Front Door profile to purge.
- `frontdoor_endpoint_name`: Azure Front Door endpoint to purge.
- `frontend_domain_name`: Custom frontend domain served by Front Door.

## Outputs

- `template`: Argo `Template` object merged into the shared
  `WorkflowTemplate.spec.templates[]` list.

## Notes

`infra/modules/azure/ci_cd` grants the `cdn_invalidator` identity access at the
environment resource group scope so it can call the Front Door purge API.
