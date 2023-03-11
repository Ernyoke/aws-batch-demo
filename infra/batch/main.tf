data "aws_caller_identity" "current" {
}

data "terraform_remote_state" "ecr" {
  backend = "s3"

  config = {
    bucket = "tf-demo-states-1234"
    key    = "aws-batch-demo/ecr"
    region = var.aws_region
  }
}