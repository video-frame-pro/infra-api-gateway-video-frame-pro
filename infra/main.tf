provider "aws" {
  region = var.aws_region
}

# Recuperando o Cognito User Pool ID do SSM
data "aws_ssm_parameter" "cognito_user_pool_id" {
  name = "/video-frame-pro/cognito/user_pool_id"
}

# API Gateway REST API
resource "aws_api_gateway_rest_api" "video_frame_pro_api" {
  name        = "video-frame-pro-api"
  description = "API Gateway para o projeto Video Frame Pro"

  tags = {
    Name        = "video-frame-pro-api"
    Environment = var.environment
  }
}

# Cognito Authorizer
resource "aws_api_gateway_authorizer" "cognito" {
  name                      = "cognito-authorizer"
  rest_api_id               = aws_api_gateway_rest_api.video_frame_pro_api.id
  identity_source           = "method.request.header.Authorization"
  identity_validation_expression = "^Bearer [A-Za-z0-9-._~+/]+=*$"
  provider_arns             = [data.aws_ssm_parameter.cognito_user_pool_id.value]
  type                      = "COGNITO_USER_POOLS"
}

# Recurso raiz (/v1)
resource "aws_api_gateway_resource" "v1" {
  rest_api_id = aws_api_gateway_rest_api.video_frame_pro_api.id
  parent_id   = aws_api_gateway_rest_api.video_frame_pro_api.root_resource_id
  path_part   = "v1"
}

# Configuração dinâmica para endpoints e métodos
locals {
  endpoints = [
    { path = "auth/register", method = "POST", auth = "NONE" },
    { path = "auth/login", method = "POST", auth = "NONE" },
    { path = "upload", method = "POST", auth = "COGNITO_USER_POOLS" },
    { path = "status-query", method = "GET", auth = "COGNITO_USER_POOLS" }
  ]
}

# Recursos dinâmicos
resource "aws_api_gateway_resource" "resources" {
  for_each   = tomap({ for e in local.endpoints : e.path => e })
  rest_api_id = aws_api_gateway_rest_api.video_frame_pro_api.id
  parent_id   = aws_api_gateway_resource.v1.id
  path_part   = split("/", each.value.path)[-1]
}

# Métodos dinâmicos
resource "aws_api_gateway_method" "methods" {
  for_each = tomap({ for e in local.endpoints : e.path => e })

  rest_api_id   = aws_api_gateway_rest_api.video_frame_pro_api.id
  resource_id   = aws_api_gateway_resource.resources[each.key].id
  http_method   = each.value.method
  authorization = each.value.auth == "NONE" ? "NONE" : "COGNITO_USER_POOLS"
  authorizer_id = each.value.auth == "COGNITO_USER_POOLS" ? aws_api_gateway_authorizer.cognito.id : null
}

# Deploy da API Gateway
resource "aws_api_gateway_deployment" "api_deployment" {
  depends_on = [aws_api_gateway_method.methods]
  rest_api_id = aws_api_gateway_rest_api.video_frame_pro_api.id
  stage_name  = var.stage_name
}