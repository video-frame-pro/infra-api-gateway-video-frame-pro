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

# Criando o recurso /auth/register no API Gateway para registro de usuário
resource "aws_api_gateway_resource" "auth_register" {
  rest_api_id = aws_api_gateway_rest_api.video_frame_pro_api.id
  parent_id   = aws_api_gateway_resource.auth.id
  path_part   = "register"
}

# Criando o recurso /auth/login no API Gateway para login de usuário
resource "aws_api_gateway_resource" "auth_login" {
  rest_api_id = aws_api_gateway_rest_api.video_frame_pro_api.id
  parent_id   = aws_api_gateway_resource.auth.id
  path_part   = "login"
}

# Criando o método POST para o endpoint /auth/register (registro de usuário)
resource "aws_api_gateway_method" "auth_register_post" {
  rest_api_id   = aws_api_gateway_rest_api.video_frame_pro_api.id
  resource_id   = aws_api_gateway_resource.auth_register.id
  http_method   = "POST"
  authorization = "NONE"  # Nenhuma autorização no POST /register
}

# Definindo a integração para o método POST /auth/register (integração com Lambda)
resource "aws_api_gateway_integration" "auth_register_integration" {
  rest_api_id             = aws_api_gateway_rest_api.video_frame_pro_api.id
  resource_id             = aws_api_gateway_resource.auth_register.id
  http_method             = aws_api_gateway_method.auth_register_post.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"  # Utilizando o proxy para Lambda
  uri                     = "arn:aws:apigateway:${var.aws_region}:lambda:path/2015-03-31/functions/${var.auth_register_lambda_name}/invocations"
}

# Criando o método POST para o endpoint /auth/login (login de usuário)
resource "aws_api_gateway_method" "auth_login_post" {
  rest_api_id   = aws_api_gateway_rest_api.video_frame_pro_api.id
  resource_id   = aws_api_gateway_resource.auth_login.id
  http_method   = "POST"
  authorization = "COGNITO_USER_POOLS"  # Usando o Cognito User Pools para autenticação
  authorizer_id = aws_api_gateway_authorizer.cognito.id  # Referenciando o ID do authorizer correto
}

# Definindo a integração para o método POST /auth/login (integração com Lambda)
resource "aws_api_gateway_integration" "auth_login_integration" {
  rest_api_id             = aws_api_gateway_rest_api.video_frame_pro_api.id
  resource_id             = aws_api_gateway_resource.auth_login.id
  http_method             = aws_api_gateway_method.auth_login_post.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"  # Utilizando o proxy para Lambda
  uri                     = "arn:aws:apigateway:${var.aws_region}:lambda:path/2015-03-31/functions/${var.auth_login_lambda_name}/invocations"
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
    aws_api_gateway_method.auth_register_post,
    aws_api_gateway_method.auth_login_post,
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

# Permissão para o API Gateway invocar a função Lambda de registro
resource "aws_lambda_permission" "allow_api_gateway_register" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = var.auth_register_lambda_name  # Nome da função Lambda (não o ARN completo)
  principal     = "apigateway.amazonaws.com"
  source_arn    = aws_api_gateway_rest_api.video_frame_pro_api.execution_arn  # ARN do API Gateway
}

# Permissão para o API Gateway invocar a função Lambda de login
resource "aws_lambda_permission" "allow_api_gateway_login" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = var.auth_login_lambda_name  # Nome da função Lambda (não o ARN completo)
  principal     = "apigateway.amazonaws.com"
  source_arn    = aws_api_gateway_rest_api.video_frame_pro_api.execution_arn  # ARN do API Gateway
}
