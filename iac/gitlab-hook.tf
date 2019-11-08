
variable "gitlab_project_id" {}

# getting correct values from Gitlab API needed for CodePipeline, triggers etc.
locals {
  gitlab_code_bucket = "${var.proj_name}-${terraform.workspace}-gitlab-code"
  gitlab_repo_path   = "${replace("${data.gitlab_project.notejam.web_url}", "https://gitlab.com/", "")}"
  gitlab_code_path   = "${local.gitlab_repo_path}/${terraform.workspace}/${data.gitlab_project.notejam.path}.zip"
}

# CodePipeline does not natively support pulling code from Gitlab
# Aws reccomends this approach: https://aws.amazon.com/quickstart/architecture/git-to-s3-using-webhooks/ 
resource "aws_cloudformation_stack" "gitlab_code" {
  name         = "${var.proj_name}-${terraform.workspace}-gitlab-code"
  
  # hosted on S3 bucket that is managed by AWS
  template_url = "https://aws-quickstart.s3.amazonaws.com/quickstart-git2s3/templates/git2s3.template"
  
  capabilities = [
    "CAPABILITY_IAM"
  ] 

  parameters = {
    OutputBucketName = "${local.gitlab_code_bucket}"
    GitToken         = "${var.gitlab_token}"
  }

  # ignored this values in order not to show 
  # gitlab token in logs for every run of terraform apply
  lifecycle {
    ignore_changes = [
      "parameters.GitToken"
    ]
  }
}

# getting information from Gitlab API about the Gitlab project
data "gitlab_project" "notejam" {
    id = "${var.gitlab_project_id}"
}

# creating push event on Gitlab repo to trigger API gateway 
# on specific URL (url of the API GW)
resource "gitlab_project_hook" "push_events" {
  project     = "${data.gitlab_project.notejam.id}"
  url         = "${trimspace(aws_cloudformation_stack.gitlab_code.outputs["ZipDownloadWebHookApi"])}"

  # enabling hook only for push events
  push_events = true
}

# Creating Trail for S3 bucket containing the code from Gitlab
resource "aws_cloudtrail" "gitlab_code" {
  name           = "${var.proj_name}-${terraform.workspace}-gitlab-code"
  s3_bucket_name = "codepipeline-cloudtrail-placeholder-bucket-${var.region}"

  event_selector {
    read_write_type           = "All"
    include_management_events = false

    data_resource {
      type = "AWS::S3::Object"
      values = [
        "arn:aws:s3:::${local.gitlab_code_bucket}/${local.gitlab_code_path}"
        ]
    }
  }
}

output "zipdl_url" {
  value       = "${trimspace(aws_cloudformation_stack.gitlab_code.outputs["ZipDownloadWebHookApi"])}"
}