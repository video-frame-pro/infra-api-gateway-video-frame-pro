######### PROVEDOR AWS #################################################
# Configuração dinâmica do provedor AWS, usando a região especificada no tfvars
provider "aws" {
  region = var.aws_region
}

######### DADOS AWS ####################################################
# Obtém informações sobre a conta AWS (ID da conta, ARN, etc.)
data "aws_caller_identity" "current" {}

# Obtém o User Pool ID do Cognito armazenado no AWS Systems Manager (SSM)
data "aws_ssm_parameter" "cognito_user_pool_id" {
  name = var.cognito_user_pool_id_ssm
}

######### API GATEWAY ##################################################
# Criar API Gateway REST para expor os endpoints da aplicação
resource "aws_api_gateway_rest_api" "api" {
  name        = "${var.prefix_name}-api"
  description = "API Gateway para autenticação, orquestração e status de vídeos"
}

# Criar autorizador Cognito para validar tokens JWT antes das requisições
resource "aws_api_gateway_authorizer" "cognito_authorizer" {
  name          = "${var.prefix_name}-cognito-authorizer"
  type          = "COGNITO_USER_POOLS"
  rest_api_id   = aws_api_gateway_rest_api.api.id
  provider_arns = ["arn:aws:cognito-idp:${var.aws_region}:${data.aws_caller_identity.current.account_id}:userpool/${data.aws_ssm_parameter.cognito_user_pool_id.value}"]
}

######### RECURSOS DO API GATEWAY ######################################
# Criar endpoint base para autenticação (registro/login)
resource "aws_api_gateway_resource" "user" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "user"
}

# Criar endpoints específicos para registro e login
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

# Criar endpoint base para vídeos
resource "aws_api_gateway_resource" "video" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "video"
}

# Criar endpoint específico para a orquestração de vídeos (POST)
resource "aws_api_gateway_resource" "orchestrator" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_resource.video.id
  path_part   = "orchestrator"
}

# Criar endpoint específico para consulta de status de vídeos (GET)
resource "aws_api_gateway_resource" "status" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_resource.video.id
  path_part   = "status"
}

######### INTEGRAÇÕES COM LAMBDA #######################################
# Integração do método POST /video/orchestrator com a Lambda de Orquestração
resource "aws_api_gateway_integration" "orchestrator_integration" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.orchestrator.id
  http_method             = aws_api_gateway_method.orchestrator_post.http_method
  type                    = "AWS_PROXY"
  integration_http_method = "POST"
  uri                     = "arn:aws:lambda:${var.aws_region}:${data.aws_caller_identity.current.account_id}:function:${var.prefix_name}-${var.lambda_orchestrator_name}-lambda/invocations"
}

# Integração do método GET /video/status com a Lambda de Status
resource "aws_api_gateway_integration" "status_integration" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.status.id
  http_method             = aws_api_gateway_method.status_get.http_method
  type                    = "AWS_PROXY"
  integration_http_method = "POST"  # API Gateway usa POST para chamar Lambdas, mesmo em GET
  uri                     = "arn:aws:lambda:${var.aws_region}:${data.aws_caller_identity.current.account_id}:function:${var.prefix_name}-${var.lambda_status_name}-lambda/invocations"
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

# Método para orquestração de vídeos COM validação de token via Cognito
resource "aws_api_gateway_method" "orchestrator_post" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.orchestrator.id
  http_method   = "POST"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito_authorizer.id
}

# Método para consultar o status de um vídeo COM validação de token via Cognito
resource "aws_api_gateway_method" "status_get" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.status.id
  http_method   = "GET"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito_authorizer.id
}

######### LOGS DO API GATEWAY ##########################################
# Criar grupos de logs no CloudWatch
resource "aws_cloudwatch_log_group" "api_gateway_register_log" {
  name              = "/aws/api-gateway/${var.prefix_name}-register-gateway"
  retention_in_days = var.log_retention_days
}

resource "aws_cloudwatch_log_group" "api_gateway_login_log" {
  name              = "/aws/api-gateway/${var.prefix_name}-login-gateway"
  retention_in_days = var.log_retention_days
}

resource "aws_cloudwatch_log_group" "api_gateway_orchestrator_log" {
  name              = "/aws/api-gateway/${var.prefix_name}-orchestrator-gateway"
  retention_in_days = var.log_retention_days
}

resource "aws_cloudwatch_log_group" "api_gateway_status_log" {
  name              = "/aws/api-gateway/${var.prefix_name}-status-gateway"
  retention_in_days = var.log_retention_days
}

######### STAGE DO API GATEWAY #########################################
# Criando um estágio explícito, pois `stage_name` está obsoleto
resource "aws_api_gateway_stage" "api_stage" {
  stage_name    = var.stage_name
  rest_api_id   = aws_api_gateway_rest_api.api.id
  deployment_id = aws_api_gateway_deployment.api_deployment.id
}

######### PERMISSÕES PARA O API GATEWAY ################################
# Criar uma Role IAM para o API Gateway acessar as Lambdas e o Cognito
resource "aws_iam_role" "api_gateway_role" {
  name = "${var.prefix_name}-api-gateway-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [ {
      Effect = "Allow",
      Principal = { Service = "apigateway.amazonaws.com" },
      Action = "sts:AssumeRole"
    }]
  })
}

# Criar uma política IAM para permitir chamadas às Lambdas, logs e acesso ao Cognito
resource "aws_iam_policy" "api_gateway_policy" {
  name = "${var.prefix_name}-api-gateway-policy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        # Permissão para invocar as funções Lambda associadas ao API Gateway
        Action   = ["lambda:InvokeFunction"],
        Effect   = "Allow",
        Resource = [
          "arn:aws:lambda:${var.aws_region}:${data.aws_caller_identity.current.account_id}:function:${var.prefix_name}-${var.lambda_register_name}-lambda",
          "arn:aws:lambda:${var.aws_region}:${data.aws_caller_identity.current.account_id}:function:${var.prefix_name}-${var.lambda_login_name}-lambda",
          "arn:aws:lambda:${var.aws_region}:${data.aws_caller_identity.current.account_id}:function:${var.prefix_name}-${var.lambda_orchestrator_name}-lambda",
          "arn:aws:lambda:${var.aws_region}:${data.aws_caller_identity.current.account_id}:function:${var.prefix_name}-${var.lambda_status_name}-lambda"
        ]
      }
    ]
  })
}

# Anexar a política IAM à role do API Gateway
resource "aws_iam_role_policy_attachment" "api_gateway_policy_attachment" {
  role       = aws_iam_role.api_gateway_role.name
  policy_arn = aws_iam_policy.api_gateway_policy.arn
}

######### DEPLOY DO API GATEWAY ########################################
# Criação do Deployment do API Gateway
resource "aws_api_gateway_deployment" "api_deployment" {
  rest_api_id = aws_api_gateway_rest_api.api.id

  depends_on = [
    aws_api_gateway_method.user_register_post,
    aws_api_gateway_method.user_login_post,
    aws_api_gateway_method.orchestrator_post,
    aws_api_gateway_method.status_get,
    aws_api_gateway_integration.orchestrator_integration,
    aws_api_gateway_integration.status_integration
  ]
}
