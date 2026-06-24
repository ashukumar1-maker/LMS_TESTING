# GCP Kubernetes Secret Link

Creates the GCP-specific Kubernetes External Secrets resources that link Google
Secret Manager secrets into a Kubernetes namespace.

This module owns:

- A namespaced External Secrets `SecretStore` backed by Google Secret Manager.
- An `ExternalSecret` that maps Google Secret Manager secret names to keys in a
  Kubernetes Secret.

It is intentionally separate from `infra/modules/kubernetes/config` so the
shared Kubernetes config module can stay cloud-neutral and instantiate this
module only when `cloud = "gcp"`.

## Requirements

External Secrets Operator and its CRDs must already be installed. In this
repository that is handled by `infra/modules/kubernetes/crds`.

The External Secrets service account must have access to the referenced Google
Secret Manager secrets. The GCP backend module grants that access when it creates
the secrets.

## Inputs

- `gcp_project_id`: GCP project containing the Secret Manager secrets.
- `namespace`: Kubernetes namespace where the `SecretStore` and
  `ExternalSecret` are created.
- `target_secret_name`: Kubernetes Secret name created by External Secrets.
- `secret_names`: Map of Kubernetes Secret keys to Google Secret Manager secret
  names.
- `labels`, `secret_store_name`, `external_secret_name`, and `refresh_interval`
  customize metadata and refresh behavior.

## Outputs

- `secret_store_name`: Created `SecretStore` name.
- `external_secret_name`: Created `ExternalSecret` name.
- `target_secret_name`: Kubernetes Secret name populated by External Secrets.
