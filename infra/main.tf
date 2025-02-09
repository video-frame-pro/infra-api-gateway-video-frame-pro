######### PROVEDOR AWS #################################################
provider "aws" {
  region = var.aws_region
}

######### DADOS AWS ####################################################
# Obtém informações sobre a conta AWS (ID da conta, ARN, etc.)
data "aws_caller_identity" "current" {}

######### API GATEWAY ##################################################
resource "aws_api_gateway_rest_api" "api" {
  name        = "${var.prefix_name}-api"
  description = "API Gateway para autenticação, orquestração e status de vídeos"
}

######### RECURSOS DO API GATEWAY ######################################
# Criar endpoint base para autenticação (registro/login)
resource "aws_api_gateway_resource" "auth" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "auth"
}

# Criar endpoints específicos para registro e login
resource "aws_api_gateway_resource" "auth_register" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_resource.auth.id
  path_part   = "register"
}

resource "aws_api_gateway_resource" "auth_login" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_resource.auth.id
  path_part   = "login"
}

# Criar endpoint base para vídeos
resource "aws_api_gateway_resource" "video" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "video"
}

# Criar endpoint para orquestração de vídeos (POST)
resource "aws_api_gateway_resource" "orchestrator" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_resource.video.id
  path_part   = "orchestrator"
}

# Criar endpoint para consulta de status de vídeos usando PATH PARAMETER `{video_id}`
resource "aws_api_gateway_resource" "status" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_resource.video.id
  path_part   = "status"
}

resource "aws_api_gateway_resource" "status_video_id" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_resource.status.id
  path_part   = "{video_id}"  # Define o parâmetro no caminho da URL
}

######### MÉTODOS DO API GATEWAY #######################################
# Métodos para autenticação (sem necessidade de autorização)
resource "aws_api_gateway_method" "auth_register_post" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.auth_register.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "auth_login_post" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.auth_login.id
  http_method   = "POST"
  authorization = "NONE"
}

# Método para orquestração de vídeos
resource "aws_api_gateway_method" "orchestrator_post" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.orchestrator.id
  http_method   = "POST"
  authorization = "NONE"
}

# Método para consultar o status de um vídeo usando PATH PARAMETER `{video_id}`
resource "aws_api_gateway_method" "status_get" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.status_video_id.id
  http_method   = "GET"
  authorization = "NONE"
  request_parameters = {
    "method.request.path.video_id" = true  # Permite capturar `video_id`
  }
}

######### INTEGRAÇÕES COM LAMBDA #######################################
# Integração do método GET /video/status/{video_id} com a Lambda de Status
resource "aws_api_gateway_integration" "status_integration" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.status_video_id.id
  http_method             = aws_api_gateway_method.status_get.http_method
  type                    = "AWS_PROXY"
  integration_http_method = "POST"  # API Gateway sempre chama Lambdas com POST
  uri                     = "arn:aws:apigateway:${var.aws_region}:lambda:path/2015-03-31/functions/arn:aws:lambda:${var.aws_region}:${data.aws_caller_identity.current.account_id}:function:${var.prefix_name}-${var.lambda_status_name}-lambda/invocations"

  depends_on = [aws_lambda_permission.allow_api_gateway_status]
}

######### PERMISSÕES PARA O API GATEWAY ################################
# Permissão para a Lambda de Status
resource "aws_lambda_permission" "allow_api_gateway_status" {
  statement_id  = "AllowExecutionFromAPIGatewayStatus"
  action        = "lambda:InvokeFunction"
  function_name = "${var.prefix_name}-${var.lambda_status_name}-lambda"
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api.execution_arn}/*"
}

######### STAGE DO API GATEWAY #########################################
resource "aws_api_gateway_stage" "api_stage" {
  stage_name    = var.stage_name
  rest_api_id   = aws_api_gateway_rest_api.api.id
  deployment_id = aws_api_gateway_deployment.api_deployment.id
}

######### DEPLOY DO API GATEWAY ########################################
resource "aws_api_gateway_deployment" "api_deployment" {
  rest_api_id = aws_api_gateway_rest_api.api.id

  depends_on = [
    aws_api_gateway_method.auth_register_post,
    aws_api_gateway_method.auth_login_post,
    aws_api_gateway_method.orchestrator_post,
    aws_api_gateway_method.status_get,
    aws_api_gateway_integration.status_integration
  ]
}
