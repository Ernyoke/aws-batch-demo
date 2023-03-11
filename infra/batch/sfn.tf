resource "aws_sfn_state_machine" "sfn_state_machine" {
  name     = "${var.module_name}-sfn"
  role_arn = aws_iam_role.sfn_role.arn

  definition = <<EOF
{
    "Comment": "Run AWS Batch job",
    "StartAt": "Submit Batch Job",
    "TimeoutSeconds": 3600,
    "States": {
        "Submit Batch Job": {
            "Type": "Task",
            "Resource": "arn:aws:states:::batch:submitJob.sync",
            "Parameters": {
                "JobName": "ImportMovies",
                "JobQueue": "${aws_batch_job_queue.job_queue.arn}",
                "JobDefinition": "${aws_batch_job_definition.job_definition.arn}"
            },
            "End": true
        }
    }
}
EOF
}

resource "aws_iam_role" "sfn_role" {
  name               = "${var.module_name}-sfn-role"
  assume_role_policy = data.aws_iam_policy_document.sfn_assume_role.json
}

data "aws_iam_policy_document" "sfn_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["states.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "sfn_policy" {
  statement {
    actions = [
      "batch:SubmitJob",
      "batch:DescribeJobs",
      "batch:TerminateJob"
    ]

    resources = ["*"]

    effect = "Allow"
  }

  statement {
    actions = [
      "events:PutTargets",
      "events:PutRule",
      "events:DescribeRule"
    ]

    resources = ["arn:aws:events:${var.aws_region}:${data.aws_caller_identity.current.account_id}:rule/StepFunctionsGetEventsForBatchJobsRule"]

    effect = "Allow"
  }
}

resource "aws_iam_policy" "sfn_policy" {
  name   = "${var.module_name}-sfn-policy"
  policy = data.aws_iam_policy_document.sfn_policy.json
}

resource "aws_iam_role_policy_attachment" "sfn_policy_attachment" {
  role       = aws_iam_role.sfn_role.name
  policy_arn = aws_iam_policy.sfn_policy.arn
}