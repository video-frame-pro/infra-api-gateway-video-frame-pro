# main.tf
provider "aws" {
  region = var.aws_region
}

# Referenciando o User Pool do Cognito existente
data "aws_cognito_user_pool" "video_frame_pro_pool" {
  provider     = aws
  user_pool_id = var.cognito_user_pool_id
}

# Criando o API Gateway REST API
resource "aws_api_gateway_rest_api" "video_frame_pro_api" {
  name        = "video-frame-pro-api"
  description = "API Gateway para gerenciamento de vídeos"
}

# Criando o recurso /auth no API Gateway para autenticação
resource "aws_api_gateway_resource" "auth" {
  rest_api_id = aws_api_gateway_rest_api.video_frame_pro_api.id
  parent_id   = aws_api_gateway_rest_api.video_frame_pro_api.root_resource_id
  path_part   = "auth"
}

# Criando o método POST para o endpoint /auth/register (registro de usuário)
resource "aws_api_gateway_method" "auth_register" {
  rest_api_id   = aws_api_gateway_rest_api.video_frame_pro_api.id
  resource_id   = aws_api_gateway_resource.auth.id
  http_method   = "POST"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito.id
}

# Definindo a integração para o método POST /auth/register
resource "aws_api_gateway_integration" "auth_register_integration" {
  rest_api_id = aws_api_gateway_rest_api.video_frame_pro_api.id
  resource_id = aws_api_gateway_resource.auth.id
  http_method = aws_api_gateway_method.auth_register.http_method
  type        = "MOCK"
}

# Criando o método GET para o endpoint /auth/login (login de usuário)
resource "aws_api_gateway_method" "auth_login" {
  rest_api_id   = aws_api_gateway_rest_api.video_frame_pro_api.id
  resource_id   = aws_api_gateway_resource.auth.id
  http_method   = "GET"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito.id
}

# Definindo a integração para o método GET /auth/login
resource "aws_api_gateway_integration" "auth_login_integration" {
  rest_api_id = aws_api_gateway_rest_api.video_frame_pro_api.id
  resource_id = aws_api_gateway_resource.auth.id
  http_method = aws_api_gateway_method.auth_login.http_method
  type        = "MOCK"
}

# Criando o Authorizer do Cognito para autenticação das APIs com JWT
resource "aws_api_gateway_authorizer" "cognito" {
  name               = "cognito-authorizer"
  rest_api_id        = aws_api_gateway_rest_api.video_frame_pro_api.id
  identity_source    = "method.request.header.Authorization"
  identity_validation_expression = "^Bearer [A-Za-z0-9-._~+/]+=*$"
  provider_arns      = [var.cognito_user_pool_arn]
  type               = "COGNITO_USER_POOLS"
}

# Criação das APIs do API Gateway
resource "aws_api_gateway_deployment" "video_frame_pro_api_deployment" {
  depends_on = [
    aws_api_gateway_method.auth_register,
    aws_api_gateway_method.auth_login,
    aws_api_gateway_integration.auth_register_integration,
    aws_api_gateway_integration.auth_login_integration
  ]

  rest_api_id = aws_api_gateway_rest_api.video_frame_pro_api.id
}

# Definindo o estágio do API Gateway
resource "aws_api_gateway_stage" "prod" {
  deployment_id = aws_api_gateway_deployment.video_frame_pro_api_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.video_frame_pro_api.id
  stage_name    = "prod"
}