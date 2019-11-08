variable "worker_autoscaling_min_count" { type = "map" }
variable "worker_autoscaling_max_count" { type = "map" }
variable "worker_autoscaling_up_cooldown" { type = "map" }
variable "worker_autoscaling_up_adjustment" { type = "map" }
variable "worker_autoscaling_down_cooldown" { type = "map" }
variable "worker_autoscaling_down_adjustment" { type = "map" }
variable "worker_autoscaling_cpu_low_threshold" { type = "map" }
variable "worker_autoscaling_cpu_low_period" { type = "map" }
variable "worker_autoscaling_cpu_low_period_counts" { type = "map" }
variable "worker_autoscaling_cpu_high_period_counts" { type = "map" }
variable "worker_autoscaling_cpu_high_period" { type = "map" }
variable "worker_autoscaling_cpu_high_threshold" { type = "map" }

data "aws_iam_role" "ecs_auto_scale" {
  name = "AWSServiceRoleForApplicationAutoScaling_ECSService"
}

# Autoscaling target
resource "aws_appautoscaling_target" "target" {
  service_namespace  = "ecs"
  resource_id        = "service/${aws_ecs_cluster.cluster.name}/${aws_ecs_service.worker.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  role_arn           = "${data.aws_iam_role.ecs_auto_scale.arn}"
  min_capacity       = "${lookup(var.worker_autoscaling_min_count, terraform.workspace)}"
  max_capacity       = "${lookup(var.worker_autoscaling_max_count, terraform.workspace)}"
}

# Scaling up policy 
resource "aws_appautoscaling_policy" "up" {
  name               = "${var.proj_name}-${terraform.workspace}-worker-scale-up"
  service_namespace  = "ecs"
  resource_id        = "service/${aws_ecs_cluster.cluster.name}/${aws_ecs_service.worker.name}"
  scalable_dimension = "ecs:service:DesiredCount"

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = "${lookup(var.worker_autoscaling_up_cooldown, terraform.workspace)}"
    metric_aggregation_type = "Maximum"

    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment          = "${lookup(var.worker_autoscaling_up_adjustment, terraform.workspace)}"
    }
  }

  depends_on = ["aws_appautoscaling_target.target"]
}

# Automatically scale capacity down by one
resource "aws_appautoscaling_policy" "down" {
  name               = "${var.proj_name}-${terraform.workspace}-worker-scale-down"
  service_namespace  = "ecs"
  resource_id        = "service/${aws_ecs_cluster.cluster.name}/${aws_ecs_service.worker.name}"
  scalable_dimension = "ecs:service:DesiredCount"

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = "${lookup(var.worker_autoscaling_down_cooldown, terraform.workspace)}"
    metric_aggregation_type = "Maximum"

    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment          = "${lookup(var.worker_autoscaling_down_adjustment, terraform.workspace)}"
    }
  }

  depends_on = ["aws_appautoscaling_target.target"]
}

# CloudWatch alarm that triggers the autoscaling up policy
resource "aws_cloudwatch_metric_alarm" "service_cpu_high" {
  alarm_name          = "${var.proj_name}-${terraform.workspace}-worker-cpu-high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  statistic           = "Average"
  threshold           = "${lookup(var.worker_autoscaling_cpu_high_threshold, terraform.workspace)}"
  period              = "${lookup(var.worker_autoscaling_cpu_high_period, terraform.workspace)}"
  evaluation_periods  = "${lookup(var.worker_autoscaling_cpu_high_period_counts, terraform.workspace)}"

  dimensions = {
    ClusterName = "${aws_ecs_cluster.cluster.name}"
    ServiceName = "${aws_ecs_service.worker.name}"
  }

  alarm_actions = ["${aws_appautoscaling_policy.up.arn}"]
}

# CloudWatch alarm that triggers the autoscaling down policy
resource "aws_cloudwatch_metric_alarm" "service_cpu_low" {
  alarm_name          = "${var.proj_name}-${terraform.workspace}-worker-cpu-low"
  comparison_operator = "LessThanOrEqualToThreshold"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  statistic           = "Average"
  threshold           = "${lookup(var.worker_autoscaling_cpu_low_threshold, terraform.workspace)}"
  period              = "${lookup(var.worker_autoscaling_cpu_low_period, terraform.workspace)}"
  evaluation_periods  = "${lookup(var.worker_autoscaling_cpu_low_period_counts, terraform.workspace)}"
  
  dimensions = {
    ClusterName = "${aws_ecs_cluster.cluster.name}"
    ServiceName = "${aws_ecs_service.worker.name}"
  }

  alarm_actions = ["${aws_appautoscaling_policy.down.arn}"]
}