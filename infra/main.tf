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

# Criar endpoint correto para consulta de status de um vídeo específico por ID (GET)
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
  resource_id   = aws_api_gateway_resource.status_id.id
  http_method   = "GET"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito_authorizer.id
}

######### PERMISSÕES DO API GATEWAY ####################################
# Criar uma Role IAM para o API Gateway acessar as Lambdas e o Cognito
resource "aws_iam_role" "api_gateway_role" {
  name = "${var.prefix_name}-api-gateway-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
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
      },
      {
        # Permissão para validar tokens JWT no Cognito
        Action   = ["cognito-idp:GetUser"],
        Effect   = "Allow",
        Resource = ["arn:aws:cognito-idp:${var.aws_region}:${data.aws_caller_identity.current.account_id}:userpool/${data.aws_ssm_parameter.cognito_user_pool_id.value}"]
      },
      {
        # Permissão para criar e enviar logs para o CloudWatch
        Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"],
        Effect   = "Allow",
        Resource = "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/api-gateway/*"
      }
    ]
  })
}

# Anexar a política IAM à role do API Gateway
resource "aws_iam_role_policy_attachment" "api_gateway_policy_attachment" {
  role       = aws_iam_role.api_gateway_role.name
  policy_arn = aws_iam_policy.api_gateway_policy.arn
}
