terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.37"
    }
  }
}

locals {
  cloud = lower(var.cloud)

  labels = {
    app         = var.workflow_template_name
    environment = var.environment
    managed-by  = "terraform"
  }

  step_service_accounts = {
    terraform_apply   = var.workflow_kubernetes_service_accounts.terraform_apply
    source_inspector  = var.workflow_kubernetes_service_accounts.source_inspector
    backend_builder   = var.workflow_kubernetes_service_accounts.backend_builder
    backend_rollout   = var.workflow_kubernetes_service_accounts.backend_rollout
    frontend_deployer = var.workflow_kubernetes_service_accounts.frontend_deployer
    cdn_invalidator   = var.workflow_kubernetes_service_accounts.cdn_invalidator
  }

  step_service_account_identity_annotation_keys = {
    gcp   = "iam.gke.io/gcp-service-account"
    azure = "azure.workload.identity/client-id"
  }

  step_service_account_identity_annotation_key = local.step_service_account_identity_annotation_keys[local.cloud]

  step_service_account_annotations = {
    for step_name in keys(local.step_service_accounts) :
    step_name => contains(keys(var.workflow_step_service_account_emails), step_name) ? {
      (local.step_service_account_identity_annotation_key) = var.workflow_step_service_account_emails[step_name]
    } : {}
  }

  workflow_submitter_subject_name = var.workflow_submitter_service_account_email == null ? "" : trimspace(var.workflow_submitter_service_account_email)
}

resource "kubernetes_service_account_v1" "workflow_orchestrator" {
  metadata {
    name      = var.workflow_kubernetes_service_accounts.workflow_orchestrator
    namespace = var.namespace
    labels    = local.labels
  }
}

resource "kubernetes_service_account_v1" "step_instances" {
  for_each = local.step_service_accounts

  metadata {
    name        = each.value
    namespace   = var.namespace
    labels      = local.labels
    annotations = local.step_service_account_annotations[each.key]
  }
}

# Runtime workflow state (hashes and deployed image URI). Terraform creates an
# empty ConfigMap; successful CD runs patch data via kubectl. See README.md
# "Workflow State ConfigMap" for the data key schema.
resource "kubernetes_config_map_v1" "workflow_state" {
  metadata {
    name      = var.workflow_state_config_map_name
    namespace = var.namespace
    labels    = local.labels
  }

  data = {}

  lifecycle {
    ignore_changes = [data]
  }
}

resource "kubernetes_role_v1" "workflow_executor" {
  metadata {
    name      = "${var.environment}-workflow-executor"
    namespace = var.namespace
    labels    = local.labels
  }

  rule {
    api_groups = ["argoproj.io"]
    resources  = ["workflows", "workflowtaskresults"]
    verbs      = ["get", "list", "watch", "create", "update", "patch"]
  }

  rule {
    api_groups = [""]
    resources  = ["pods", "pods/log"]
    verbs      = ["get", "list", "watch"]
  }
}

resource "kubernetes_role_binding_v1" "workflow_executor" {
  metadata {
    name      = "${var.environment}-workflow-executor"
    namespace = var.namespace
    labels    = local.labels
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role_v1.workflow_executor.metadata[0].name
  }

  dynamic "subject" {
    for_each = merge(
      {
        workflow_orchestrator = kubernetes_service_account_v1.workflow_orchestrator.metadata[0].name
      },
      { for key, account in kubernetes_service_account_v1.step_instances : key => account.metadata[0].name }
    )

    content {
      kind      = "ServiceAccount"
      name      = subject.value
      namespace = var.namespace
    }
  }
}

resource "kubernetes_role_v1" "workflow_state_editor" {
  metadata {
    name      = "${var.environment}-workflow-state-editor"
    namespace = var.namespace
    labels    = local.labels
  }

  rule {
    api_groups = [""]
    resources  = ["configmaps"]
    resource_names = [
      kubernetes_config_map_v1.workflow_state.metadata[0].name,
    ]
    verbs = ["get", "update", "patch"]
  }

  rule {
    api_groups = [""]
    resources  = ["secrets"]
    verbs      = ["get", "delete"]
  }
}

resource "kubernetes_role_binding_v1" "workflow_state_editor" {
  metadata {
    name      = "${var.environment}-workflow-state-editor"
    namespace = var.namespace
    labels    = local.labels
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role_v1.workflow_state_editor.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account_v1.workflow_orchestrator.metadata[0].name
    namespace = var.namespace
  }
}

resource "kubernetes_role_v1" "workflow_submitter" {
  metadata {
    name      = "${var.environment}-workflow-submitter"
    namespace = var.namespace
    labels    = local.labels
  }

  rule {
    api_groups = ["argoproj.io"]
    resources  = ["workflows", "workflowtemplates"]
    verbs      = ["get", "list", "watch", "create"]
  }

  rule {
    api_groups = [""]
    resources  = ["secrets"]
    verbs      = ["create", "get", "delete"]
  }
}

resource "kubernetes_role_binding_v1" "workflow_submitter" {
  count = local.workflow_submitter_subject_name == "" ? 0 : 1

  metadata {
    name      = "${var.environment}-workflow-submitter"
    namespace = var.namespace
    labels    = local.labels
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role_v1.workflow_submitter.metadata[0].name
  }

  subject {
    api_group = "rbac.authorization.k8s.io"
    kind      = "User"
    name      = local.workflow_submitter_subject_name
  }
}

resource "kubernetes_cluster_role_binding_v1" "terraform_apply_cluster_admin" {
  metadata {
    name   = "${var.environment}-argo-terraform-apply-cluster-admin"
    labels = local.labels
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account_v1.step_instances["terraform_apply"].metadata[0].name
    namespace = var.namespace
  }
}

resource "kubernetes_role_v1" "source_inspector" {
  metadata {
    name      = "${var.environment}-source-inspector"
    namespace = var.backend_namespace
    labels    = local.labels
  }

  rule {
    api_groups = ["apps"]
    resources  = ["deployments"]
    verbs      = ["get", "list"]
  }
}

resource "kubernetes_role_binding_v1" "source_inspector" {
  metadata {
    name      = "${var.environment}-source-inspector"
    namespace = var.backend_namespace
    labels    = local.labels
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role_v1.source_inspector.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account_v1.step_instances["source_inspector"].metadata[0].name
    namespace = var.namespace
  }
}

resource "kubernetes_role_v1" "backend_rollout" {
  metadata {
    name      = "${var.environment}-backend-rollout"
    namespace = var.backend_namespace
    labels    = local.labels
  }

  rule {
    api_groups = ["apps"]
    resources  = ["deployments", "deployments/status", "replicasets"]
    verbs      = ["get", "list", "watch", "update", "patch"]
  }

  rule {
    api_groups = [""]
    resources  = ["pods", "events"]
    verbs      = ["get", "list", "watch"]
  }
}

resource "kubernetes_role_binding_v1" "backend_rollout" {
  metadata {
    name      = "${var.environment}-backend-rollout"
    namespace = var.backend_namespace
    labels    = local.labels
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role_v1.backend_rollout.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account_v1.step_instances["backend_rollout"].metadata[0].name
    namespace = var.namespace
  }
}

resource "kubernetes_role_v1" "backend_cd_task_runner" {
  metadata {
    name      = "${var.environment}-backend-cd-task-runner"
    namespace = var.backend_namespace
    labels    = local.labels
  }

  rule {
    api_groups = ["batch"]
    resources  = ["jobs"]
    verbs      = ["create", "get", "list", "watch", "delete"]
  }

  rule {
    api_groups = [""]
    resources  = ["pods", "pods/log", "events"]
    verbs      = ["get", "list", "watch"]
  }
}

resource "kubernetes_role_binding_v1" "backend_cd_task_runner" {
  metadata {
    name      = "${var.environment}-backend-cd-task-runner"
    namespace = var.backend_namespace
    labels    = local.labels
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role_v1.backend_cd_task_runner.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account_v1.workflow_orchestrator.metadata[0].name
    namespace = var.namespace
  }
}
