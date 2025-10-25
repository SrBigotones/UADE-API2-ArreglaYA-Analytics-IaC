# IAM Role for Grafana to access CloudWatch
resource "aws_iam_role" "grafana_cloudwatch" {
  name = "arregla-ya-grafana-cloudwatch"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# Policy to allow Grafana to read CloudWatch metrics and logs
resource "aws_iam_role_policy" "grafana_cloudwatch" {
  name = "arregla-ya-grafana-cloudwatch-policy"
  role = aws_iam_role.grafana_cloudwatch.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:*",
          "logs:*",
          "ec2:DescribeInstances",
          "ec2:DescribeVolumes",
          "tag:GetResources",
          "lambda:List*",
          "lambda:Get*"
        ]
        Resource = "*"
      }
    ]
  })
}

# Instance profile for the Grafana EC2 instance
resource "aws_iam_instance_profile" "grafana" {
  name = "arregla-ya-grafana-profile"
  role = aws_iam_role.grafana_cloudwatch.name
}