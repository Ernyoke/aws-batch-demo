output "ecr_registry_url" {
  value = data.terraform_remote_state.ecr.outputs.ecr_registry_url
}