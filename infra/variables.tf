######### PREFIXO DO PROJETO ###########################################
variable "prefix_name" {
  description = "Prefixo para nomear todos os recursos do projeto"
}

######### AWS CONFIGURATION ###########################################
variable "aws_region" {
  description = "Região AWS onde os recursos serão provisionados"
}

variable "stage_name" {
  description = "Nome do estágio do API Gateway (ex: 'prod')"
}

######### LAMBDAS INFOS ##########################################
variable "lambda_register_name" {
  description = "Nome da Lambda de registro"
}

variable "lambda_login_name" {
  description = "Nome da Lambda de login"
}

variable "lambda_orchestrator_name" {
  description = "Nome da Lambda de orquestração"
}

variable "lambda_status_name" {
  description = "Nome da Lambda de status"
}

######### COGNITO #####################################################
variable "cognito_user_pool_id_ssm" {
  description = "Caminho no SSM para o ID do User Pool do Cognito"
}
