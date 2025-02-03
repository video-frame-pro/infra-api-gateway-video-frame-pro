######### PROVEDOR AWS #################################################
# Configuração do provedor AWS com região dinâmica
provider "aws" {
  region = var.aws_region
}

######### DADOS AWS ####################################################
# Obter informações sobre a conta AWS (ID da conta, ARN, etc.)
data "aws_caller_identity" "current" {}

# Obter o User Pool ID do Cognito armazenado no Parameter Store (SSM)
data "aws_ssm_parameter" "cognito_user_pool_id" {
  name = var.cognito_user_pool_id_ssm
}

######### API GATEWAY ##################################################
# Criação do API Gateway REST
resource "aws_api_gateway_rest_api" "api" {
  name        = "${var.prefix_name}-api"
  description = "API Gateway para gerenciar autenticação, orquestração e status de vídeos"
}

# Autorizador Cognito para validar o token JWT antes das requisições
resource "aws_api_gateway_authorizer" "cognito_authorizer" {
  name          = "${var.prefix_name}-cognito-authorizer"
  type          = "COGNITO_USER_POOLS"
  rest_api_id   = aws_api_gateway_rest_api.api.id
  provider_arns = [data.aws_ssm_parameter.cognito_user_pool_id.value]
}

######### RECURSOS DO API GATEWAY ######################################
# Recurso para autenticação (register/login)
resource "aws_api_gateway_resource" "user" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "user"
}

resource "aws_api_gateway_resource" "user_register" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_resource.user.id
  path_part   = "register"
}

resource "aws_api_gateway_resource" "user_login" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_resource.user.id
  path_part   = "login"
}

# Recurso para orquestração de vídeos
resource "aws_api_gateway_resource" "video" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "video"
}

resource "aws_api_gateway_resource" "orchestrator" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_resource.video.id
  path_part   = "orchestrator"
}

# Recurso para consulta de status de um vídeo
resource "aws_api_gateway_resource" "status" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "status"
}

resource "aws_api_gateway_resource" "status_id" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_resource.status.id
  path_part   = "{video_id}"
}

######### MÉTODOS DO API GATEWAY #######################################
# Métodos para autenticação (sem necessidade de autorização)
resource "aws_api_gateway_method" "user_register_post" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.user_register.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "user_login_post" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.user_login.id
  http_method   = "POST"
  authorization = "NONE"
}

# Método para orquestração com autenticação via Cognito
resource "aws_api_gateway_method" "orchestrator_post" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.orchestrator.id
  http_method   = "POST"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito_authorizer.id
}

# Método para obter status de um vídeo com autenticação via Cognito
resource "aws_api_gateway_method" "status_get" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.status_id.id
  http_method   = "GET"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito_authorizer.id
}

######### DEPLOY DO API GATEWAY ########################################
resource "aws_api_gateway_deployment" "api_deployment" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  stage_name  = var.stage_name

  depends_on = [
    aws_api_gateway_method.user_register_post,
    aws_api_gateway_method.user_login_post,
    aws_api_gateway_method.orchestrator_post,
    aws_api_gateway_method.status_get
  ]
}
