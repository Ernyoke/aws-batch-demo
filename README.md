# aws-batch-demo

This repository contains the source code for article: [https://ervinszilagyi.dev/articles/an-introduction-to-aws-batch.html](https://ervinszilagyi.dev/articles/an-introduction-to-aws-batch.html)

## Deployment

Requirements:

- Terraform version 1.0.0 or later
- Docker

Follow this steps in order:

1. Adjust the variables in the `terraform.tfvars` files in each [ecr](./infra/ecr) and [batch](./infra/batch) Terraform projects. Also, these projects are configured to use an S3 bucket for the Terraform state. You may want to reconfigure this to point to an existing bucket in your AWS account.


2. Create an ECR repository by deploying the [ecr](./infra/ecr) Terraform project:

```bash
cd infra/ecr
terraform init
terraform apply
```

3. Build the Docker image for the batch job:

```bash
cd movies-loader
docker buildx build --platform linux/amd64 -t movies-loader .
```

4. Push the Docker image to the ECR repository. You can follow the push commands from the AWS console for the repository crated at step 2.

5. Deploy the batch job:

```bash
cd infra/batch
terraform init
terraform apply
```