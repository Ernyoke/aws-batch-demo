#--------------------
# Compute Environment
#--------------------
data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["batch.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "service_role" {
  name               = "${var.module_name}-service-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy_attachment" "service_role_attachment" {
  role       = aws_iam_role.service_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBatchServiceRole"
}

resource "aws_security_group" "sg" {
  name        = "${var.module_name}-sg"
  description = "Movies batch demo SG."
  vpc_id      = aws_vpc.vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_batch_compute_environment" "compute_environment" {
  compute_environment_name = var.module_name

  compute_resources {
    max_vcpus = 4

    security_group_ids = [
      aws_security_group.sg.id
    ]

    subnets = [
      aws_subnet.private_subnet.id
    ]

    type = "FARGATE"
  }

  service_role = aws_iam_role.service_role.arn
  type         = "MANAGED"
  depends_on   = [aws_iam_role_policy_attachment.service_role_attachment]
}

#--------------------
# Job Queue
#--------------------

resource "aws_batch_job_queue" "job_queue" {
  name     = "${var.module_name}-job-queue"
  state    = "ENABLED"
  priority = 1
  compute_environments = [
    aws_batch_compute_environment.compute_environment.arn,
  ]
}

#--------------------
# Job Definition
#--------------------
resource "aws_batch_job_definition" "job_definition" {
  name = "${var.module_name}-job-definition"
  type = "container"

  platform_capabilities = [
    "FARGATE",
  ]

  container_properties = jsonencode({
    image = "${data.terraform_remote_state.ecr.outputs.ecr_registry_url}:latest"

    environment = [
      {
        name  = "TABLE_NAME"
        value = var.table_name
      },
      {
        name  = "BUCKET"
        value = var.bucket
      },
      {
        name  = "FILE_PATH"
        value = var.file_path
      }
    ]

    fargatePlatformConfiguration = {
      platformVersion = "LATEST"
    }

    resourceRequirements = [
      {
        type  = "VCPU"
        value = "1.0"
      },
      {
        type  = "MEMORY"
        value = "2048"
      }
    ]

    executionRoleArn = aws_iam_role.ecs_task_execution_role.arn
    jobRoleArn       = aws_iam_role.job_role.arn
  })
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name               = "${var.module_name}-ecs-task-execution-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "job_role" {
  name               = "${var.module_name}-job-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}

// dynamodb table Write Policy
data "aws_iam_policy_document" "dynamodb_write_policy_document" {
  statement {
    actions = [
      "dynamodb:DeleteItem",
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:BatchWriteItem",
      "dynamodb:UpdateItem"
    ]

    resources = ["arn:aws:dynamodb:${var.aws_region}:${data.aws_caller_identity.current.account_id}:table/${var.table_name}"]

    effect = "Allow"
  }
}

resource "aws_iam_policy" "dynamodb_write_policy" {
  name   = "${var.module_name}-dynamodb-write-policy"
  policy = data.aws_iam_policy_document.dynamodb_write_policy_document.json
}

resource "aws_iam_role_policy_attachment" "dynamodb_write_policy_attachment" {
  role       = aws_iam_role.job_role.name
  policy_arn = aws_iam_policy.dynamodb_write_policy.arn
}

// S3 readonly bucket policy
data "aws_iam_policy_document" "s3_read_only_policy_document" {
  statement {
    actions = [
      "s3:ListObjectsInBucket",
    ]

    resources = ["arn:aws:s3:::${var.bucket}"]

    effect = "Allow"
  }

  statement {
    actions = [
      "s3:GetObject",
    ]

    resources = ["arn:aws:s3:::${var.bucket}/*"]

    effect = "Allow"
  }
}

resource "aws_iam_policy" "s3_readonly_policy" {
  name   = "${var.module_name}-s3-readonly-policy"
  policy = data.aws_iam_policy_document.s3_read_only_policy_document.json
}

resource "aws_iam_role_policy_attachment" "s3_readonly_policy_attachment" {
  role       = aws_iam_role.job_role.name
  policy_arn = aws_iam_policy.s3_readonly_policy.arn
}