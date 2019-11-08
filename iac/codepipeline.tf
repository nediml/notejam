resource "aws_iam_role" "pipeline_role" {
  name = "${var.proj_name}-${terraform.workspace}-pipelines-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codepipeline.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}


resource "aws_iam_role" "cw_role" {
  name = "${var.proj_name}-${terraform.workspace}-cw-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "events.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "pipeline_policy" {
  name = "${var.proj_name}-${terraform.workspace}-pipelines-policy"
  role = "${aws_iam_role.pipeline_role.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect":"Allow",
      "Action": [
        "s3:*",
        "codedeploy:*",
        "codebuild:*",
        "codebuild:*",
        "cloudwatch:*",
        "autoscaling:*",
        "ecs:*",
        "ec2:*",
        "logs:*",
        "ecr:*",
        "ssm:GetParameter"
      ],
      "Resource": [
        "*"
      ]
    },
    {
        "Action": [
            "iam:PassRole"
        ],
        "Resource": "*",
        "Effect": "Allow",
        "Condition": {
            "StringEqualsIfExists": {
                "iam:PassedToService": [
                    "ec2.amazonaws.com",
                    "ecs-tasks.amazonaws.com"
                ]
            }
        }
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "cw_policy" {
  name = "${var.proj_name}-${terraform.workspace}-cw-policy"
  role = "${aws_iam_role.cw_role.id}"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "codepipeline:StartPipelineExecution"
            ],
            "Resource": [
                "*"
            ]
        }
    ]
}
EOF
}

# S3 bucket for CodePipeline artifacts
resource "aws_s3_bucket" "pipeline_artifacts" {
  bucket = "${var.proj_name}-${terraform.workspace}-pipeline-artifacts"
  acl    = "private"
  
  server_side_encryption_configuration {
      rule {
        apply_server_side_encryption_by_default {
          sse_algorithm     = "AES256"
        }
      }
  }
}

# Cloudwatch rule to trigger the pipeline when file on S3 bucket changes
resource "aws_cloudwatch_event_rule" "pipeline_trigger" {
  name        = "${var.proj_name}-${terraform.workspace}-pipeline-trigger"
  is_enabled  = true

  event_pattern = <<PATTERN
{
  "source": [
    "aws.s3"
  ],
  "detail-type": [
    "AWS API Call via CloudTrail"
  ],
  "detail": {
    "eventSource": [
      "s3.amazonaws.com"
    ],
    "eventName": [
      "PutObject",
      "CompleteMultipartUpload",
      "CopyObject"
    ],
    "requestParameters": {
      "bucketName": [
        "${local.gitlab_code_bucket}"
      ],
      "key": [
        "${local.gitlab_code_path}"
      ]
    }
  }
}
PATTERN
}

resource "aws_cloudwatch_event_target" "pipeline_trigger" {
  target_id = "new-file-incoming-trigger-target"
  rule      = "${aws_cloudwatch_event_rule.pipeline_trigger.name}"
  arn       = "${aws_codepipeline.notejam.arn}"
  role_arn  = "${aws_iam_role.cw_role.arn}"
}

# CodePipeline 
resource "aws_codepipeline" "notejam" {
  name     = "${var.proj_name}-${terraform.workspace}-notejam"
  role_arn = "${aws_iam_role.pipeline_role.arn}"

  artifact_store {
    location = "${aws_s3_bucket.pipeline_artifacts.bucket}"
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "S3"
      version          = "1"
      output_artifacts = ["AppSource"]

      configuration = {
        S3Bucket	 = "${local.gitlab_code_bucket}"
        S3ObjectKey  = "${local.gitlab_code_path}"
        PollForSourceChanges = "false"
      }
    }
  }
  
  stage {
    name = "Test"

    action {
      name             = "Test"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["AppSource"]
      output_artifacts = []

      configuration = {
        # get only codebuild project name
        ProjectName = "${element(split("/", aws_codebuild_project.test.id), 1)}"
      }
    }
  }
  stage {
    name = "Build"
    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["AppSource"]
      output_artifacts = ["AppBuild"]

      configuration = {
        # get only codebuild project name
        ProjectName = "${element(split("/", aws_codebuild_project.build.id), 1)}"
      }
    }
  }

  stage {
    name = "Migrations"

    action {
      name             = "Migrations"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["AppSource"]
      output_artifacts = []

      configuration = {
        # get only codebuild project name
        ProjectName = "${element(split("/", aws_codebuild_project.migrate.id), 1)}"
      }
    }
  }

  stage {
    name = "Deploy"
    action {
      name             = "DeployWorker"
      category         = "Deploy"
      owner            = "AWS"
      provider         = "ECS"
      version          = "1"
      input_artifacts  = ["AppBuild"]
      output_artifacts = []

      configuration   = {
        ClusterName   = "${aws_ecs_cluster.cluster.id}"
        ServiceName   = "${aws_ecs_service.worker.name}"
        FileName      = "image-definitions.json"
      }
    }
  }

}