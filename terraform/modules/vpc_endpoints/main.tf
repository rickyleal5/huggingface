# VPC Endpoints
resource "aws_vpc_endpoint" "execute_api" {
  vpc_id             = var.vpc_id
  service_name       = "com.amazonaws.${var.region}.execute-api"
  vpc_endpoint_type  = "Interface"
  subnet_ids         = var.private_subnet_ids
  security_group_ids = [var.vpc_endpoints_security_group_id]

  private_dns_enabled = true

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-execute-api-endpoint"
    }
  )
} 