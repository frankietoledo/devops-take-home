
resource "aws_lb" "nlb" {
  name               = "${var.project_name}-nlb"
  internal           = true
  load_balancer_type = "network"
  subnets            = [var.subnet_id]
}

resource "aws_lb_target_group" "app_tg" {
  name     = "${var.project_name}-tg"
  port     = 3000
  protocol = "TCP"
  vpc_id   = var.vpc_id
  target_type = "instance"
  
  health_check {
    protocol = "TCP"
  }
}

resource "aws_lb_target_group_attachment" "app_attach" {
  target_group_arn = aws_lb_target_group.app_tg.arn
  target_id        = var.target_instance_id
  port             = 3000
}

resource "aws_lb_listener" "app_listener" {
  load_balancer_arn = aws_lb.nlb.arn
  port              = "3000"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}

resource "aws_api_gateway_vpc_link" "main" {
  name        = "${var.project_name}-vpc-link"
  target_arns = [aws_lb.nlb.arn]
}

resource "aws_api_gateway_rest_api" "app_api" {
  name = "${var.project_name}-api"
}

locals {
  private_integration = {
    type                    = "HTTP_PROXY"
    integration_http_method = "ANY"
    connection_type         = "VPC_LINK"
    connection_id           = aws_api_gateway_vpc_link.main.id
    uri                     = aws_lb_listener.app_listener.arn
  }
}


# --- Recursos y Métodos de la API ---
resource "aws_api_gateway_resource" "webhook" {
  rest_api_id = aws_api_gateway_rest_api.app_api.id
  parent_id   = aws_api_gateway_rest_api.app_api.root_resource_id
  path_part   = "webhook"
}
resource "aws_api_gateway_resource" "oauth" {
  rest_api_id = aws_api_gateway_rest_api.app_api.id
  parent_id   = aws_api_gateway_rest_api.app_api.root_resource_id
  path_part   = "oauth"
}
resource "aws_api_gateway_resource" "oauth_authorize" {
  rest_api_id = aws_api_gateway_rest_api.app_api.id
  parent_id   = aws_api_gateway_resource.oauth.id
  path_part   = "authorize"
}
resource "aws_api_gateway_resource" "oauth_callback" {
  rest_api_id = aws_api_gateway_rest_api.app_api.id
  parent_id   = aws_api_gateway_resource.oauth.id
  path_part   = "callback"
}

# --- Métodos e Integraciones ---
resource "aws_api_gateway_method" "root_get" {
  rest_api_id   = aws_api_gateway_rest_api.app_api.id
  resource_id   = aws_api_gateway_rest_api.app_api.root_resource_id
  http_method   = "GET"
  authorization = "NONE"
}
resource "aws_api_gateway_integration" "root_get_integration" {
  rest_api_id             = aws_api_gateway_rest_api.app_api.id
  resource_id             = aws_api_gateway_rest_api.app_api.root_resource_id
  http_method             = aws_api_gateway_method.root_get.http_method
  integration_http_method = "GET"
  passthrough_behavior    = "WHEN_NO_TEMPLATES"
  type                    = local.private_integration.type
  connection_type         = local.private_integration.connection_type
  connection_id           = local.private_integration.connection_id
  uri                     = "http://${var.instance_private_ip}:3000/"
}

resource "aws_api_gateway_method" "webhook_post" {
  rest_api_id   = aws_api_gateway_rest_api.app_api.id
  resource_id   = aws_api_gateway_resource.webhook.id
  http_method   = "POST"
  authorization = "NONE"
}
resource "aws_api_gateway_integration" "webhook_post_integration" {
  rest_api_id             = aws_api_gateway_rest_api.app_api.id
  resource_id             = aws_api_gateway_resource.webhook.id
  http_method             = aws_api_gateway_method.webhook_post.http_method
  integration_http_method = "POST"
  passthrough_behavior    = "WHEN_NO_TEMPLATES"
  type                    = local.private_integration.type
  connection_type         = local.private_integration.connection_type
  connection_id           = local.private_integration.connection_id
  uri                     = "http://${var.instance_private_ip}:3000/webhook"
}


resource "aws_api_gateway_method" "oauth_authorize_get" {
  rest_api_id   = aws_api_gateway_rest_api.app_api.id
  resource_id   = aws_api_gateway_resource.oauth_authorize.id
  http_method   = "GET"
  authorization = "NONE"
}
resource "aws_api_gateway_integration" "oauth_authorize_integration" {
  rest_api_id             = aws_api_gateway_rest_api.app_api.id
  resource_id             = aws_api_gateway_resource.oauth_authorize.id
  http_method             = aws_api_gateway_method.oauth_authorize_get.http_method
  integration_http_method = "GET"
  passthrough_behavior    = "WHEN_NO_TEMPLATES"
  type                    = local.private_integration.type
  connection_type         = local.private_integration.connection_type
  connection_id           = local.private_integration.connection_id
  uri                     = "http://${var.instance_private_ip}:3000/oauth/authorize"
}


resource "aws_api_gateway_method" "oauth_callback_get" {
  rest_api_id   = aws_api_gateway_rest_api.app_api.id
  resource_id   = aws_api_gateway_resource.oauth_callback.id
  http_method   = "GET"
  authorization = "NONE"
}
resource "aws_api_gateway_integration" "oauth_callback_integration" {
  rest_api_id             = aws_api_gateway_rest_api.app_api.id
  resource_id             = aws_api_gateway_resource.oauth_callback.id
  http_method             = aws_api_gateway_method.oauth_callback_get.http_method
  integration_http_method = "GET"
  passthrough_behavior    = "WHEN_NO_TEMPLATES"
  type                    = local.private_integration.type
  connection_type         = local.private_integration.connection_type
  connection_id           = local.private_integration.connection_id
  uri                     = "http://${var.instance_private_ip}:3000/oauth/callback"
}


resource "aws_api_gateway_deployment" "app_deployment" {
  rest_api_id = aws_api_gateway_rest_api.app_api.id
  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.webhook.id,
      aws_api_gateway_resource.oauth_authorize.id,
      aws_api_gateway_resource.oauth_callback.id
    ]))
  }
  lifecycle { create_before_destroy = true }
}

resource "aws_api_gateway_stage" "prod" {
  deployment_id = aws_api_gateway_deployment.app_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.app_api.id
  stage_name    = "prod"
}