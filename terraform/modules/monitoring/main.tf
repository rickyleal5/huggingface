# CloudWatch Log Group for Model Server
resource "aws_cloudwatch_log_group" "model_server" {
  name              = "/${var.name_prefix}/model-server"
  retention_in_days = var.log_retention_days

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-model-server-logs"
    }
  )
}

# CloudWatch Log Group for API Gateway
resource "aws_cloudwatch_log_group" "api_gateway" {
  name              = "/${var.name_prefix}/api-gateway"
  retention_in_days = var.log_retention_days

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-api-gateway-logs"
    }
  )
}

# CloudWatch Alarms

# CloudWatch Metric Alarm for Model Server CPU Utilization
resource "aws_cloudwatch_metric_alarm" "model_server_cpu" {
  alarm_name          = "${var.name_prefix}-model-server-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "Model server CPU utilization is high"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    ClusterName = var.cluster_name
    ServiceName = "model-server"
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-model-server-cpu-alarm"
    }
  )
}

# CloudWatch Metric Alarm for API Gateway CPU Utilization
resource "aws_cloudwatch_metric_alarm" "api_gateway_cpu" {
  alarm_name          = "${var.name_prefix}-api-gateway-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "API gateway CPU utilization is high"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    ClusterName = var.cluster_name
    ServiceName = "api-gateway"
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-api-gateway-cpu-alarm"
    }
  )
}

# SNS Topic for Alerts
resource "aws_sns_topic" "alerts" {
  name = "${var.name_prefix}-alerts"

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-alerts-topic"
    }
  )
}

# SNS Topic Policy
resource "aws_sns_topic_policy" "alerts" {
  arn = aws_sns_topic.alerts.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "cloudwatch.amazonaws.com"
        }
        Action   = "SNS:Publish"
        Resource = aws_sns_topic.alerts.arn
      }
    ]
  })
}

# SNS Topic Subscription
resource "aws_sns_topic_subscription" "alerts" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}
