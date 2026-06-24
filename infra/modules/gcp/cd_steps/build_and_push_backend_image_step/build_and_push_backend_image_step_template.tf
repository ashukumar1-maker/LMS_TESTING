locals {
  # Argo Template object; see ../../README.md and the shared Kubernetes CD workflow README for schema context.
  build_and_push_backend_image_step_template = {
    name               = "backend-build"
    serviceAccountName = var.step_service_account_name
    inputs = {
      parameters = [
        { name = "desired-image" },
      ]
    }
    container = {
      image = var.kaniko_image
      args = [
        "--context=dir:///workspace/repo/backend",
        "--destination={{inputs.parameters.desired-image}}",
        "--cache=true",
      ]
      volumeMounts = [
        {
          name      = "workspace"
          mountPath = "/workspace"
        }
      ]
    }
  }
}
