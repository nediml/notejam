resource "aws_iam_role" "codebuild_role" {
  name = "${var.proj_name}-${terraform.workspace}-codebuild-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codebuild.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "codebuild_policy" {
  name = "${var.proj_name}-${terraform.workspace}-codebuild-policy"
  role = "${aws_iam_role.codebuild_role.id}"

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
    }
  ]
}
EOF
}

resource "aws_codebuild_project" "test" {
  name          = "${var.proj_name}-${terraform.workspace}-test"
  service_role  = "${aws_iam_role.codebuild_role.arn}"

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type    = "BUILD_GENERAL1_SMALL"
    image           = "python:2.7"
    type            = "LINUX_CONTAINER"
    privileged_mode = true
    

    environment_variable {
      "name"  = "PROJECT"
      "value" = "${var.proj_name}"
    }
    environment_variable {
      "name"  = "ENV"
      "value" = "${terraform.workspace}"
    }
    environment_variable {
      "name"  = "AWS_ACCOUNT"
      "value" = "${local.aws_account_id}"              
    }
    environment_variable {
      "name"  = "APP_PORT"
      "value" = "${lookup(var.worker_port, terraform.workspace)}"
    }
    environment_variable {
      "name"  = "ECR"
      "value" = "${aws_ecr_repository.ecr.repository_url}"
    }
    environment_variable {
      "name"  = "DB_HOST"
      "value" = "${aws_rds_cluster.notejam.endpoint}"
    }
    environment_variable {
      "name"  = "DB_PORT"
      "value" = "${aws_rds_cluster.notejam.port}"
    }
    environment_variable {
      "name"  = "DB_USER"
      "value" = "${aws_rds_cluster.notejam.master_username}"
    }
    environment_variable {
      "name"  = "DB_PASS"
      "value" = "${aws_ssm_parameter.rds_password.name}"
    }  
  }
  
  vpc_config { 
    vpc_id = "${aws_vpc.notejam.id}" 
 
    subnets = [ 
      "${aws_subnet.ecs_a.id}", 
      "${aws_subnet.ecs_b.id}" 
    ] 
     
    security_group_ids = [ 
      "${aws_security_group.worker.id  }" 
    ] 
  } 
  
  source {
    type      = "CODEPIPELINE"
    buildspec = "cicd/test.yaml"
  }
}

resource "aws_codebuild_project" "build" {
  name          = "${var.proj_name}-${terraform.workspace}-build"
  service_role  = "${aws_iam_role.codebuild_role.arn}"

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type    = "BUILD_GENERAL1_SMALL"
    image           = "aws/codebuild/standard:1.0"
    type            = "LINUX_CONTAINER"
    privileged_mode = true

    environment_variable {
      "name"  = "PROJECT"
      "value" = "${var.proj_name}"
    }
    environment_variable {
      "name"  = "ENV"
      "value" = "${terraform.workspace}"
    }
    environment_variable {
      "name"  = "AWS_ACCOUNT"
      "value" = "${local.aws_account_id}"    
    }
    environment_variable {
      "name"  = "APP_PORT"
      "value" = "${lookup(var.worker_port, terraform.workspace)}"
    }
    environment_variable {
      "name"  = "ECR"
      "value" = "${aws_ecr_repository.ecr.repository_url}"
    }
    environment_variable {
      "name"  = "DB_HOST"
      "value" = "${aws_rds_cluster.notejam.endpoint}"
    }
    environment_variable {
      "name"  = "DB_PORT"
      "value" = "${aws_rds_cluster.notejam.port}"
    }
    environment_variable {
      "name"  = "DB_USER"
      "value" = "${aws_rds_cluster.notejam.master_username}"
    }
    environment_variable {
      "name"  = "DB_PASS"
      "value" = "${aws_ssm_parameter.rds_password.name}"
    }   
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "cicd/build.yaml"
  }
}

resource "aws_codebuild_project" "migrate" {
  name          = "${var.proj_name}-${terraform.workspace}-migrate"
  service_role  = "${aws_iam_role.codebuild_role.arn}"

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image        = "python:2.7"
    type         = "LINUX_CONTAINER"

    environment_variable {
      "name"  = "PROJECT"
      "value" = "${var.proj_name}"
    }
    environment_variable {
      "name"  = "ENV"
      "value" = "${terraform.workspace}"
    }
    environment_variable {
      "name"  = "DB_HOST"
      "value" = "${aws_rds_cluster.notejam.endpoint}"
    }
    environment_variable {
      "name"  = "DB_PORT"
      "value" = "${aws_rds_cluster.notejam.port}"
    }
    environment_variable {
      "name"  = "DB_USER"
      "value" = "${aws_rds_cluster.notejam.master_username}"
    }
    environment_variable {
      "name"  = "DB_PASS"
      "value" = "${aws_ssm_parameter.rds_password.name}"
    }
  }

  vpc_config { 
    vpc_id = "${aws_vpc.notejam.id}" 
 
    subnets = [ 
      "${aws_subnet.ecs_a.id}", 
      "${aws_subnet.ecs_b.id}" 
    ] 
     
    security_group_ids = [ 
      "${aws_security_group.worker.id  }" 
    ] 
  } 

  source {
    type      = "CODEPIPELINE"
    buildspec = "cicd/migrate.yaml"
  }
}

