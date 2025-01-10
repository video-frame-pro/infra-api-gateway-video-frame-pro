# variables.tf
variable "aws_region" {
  description = "Região da AWS onde os recursos serão criados"
  type        = string
  default     = "us-east-1"
}

variable "cognito_user_pool_id" {
  description = "ID do User Pool do Cognito"
  type        = string
}

variable "cognito_user_pool_arn" {
  description = "ARN do User Pool do Cognito"
  type        = string
}

variable "auth_register_lambda_name" {
  description = "Nome da função Lambda de registro de usuário"
  type        = string
}

variable "auth_register_lambda_arn" {
  description = "ARN da função Lambda de registro de usuário"
  type        = string
}

variable "auth_login_lambda_name" {
  description = "Nome da função Lambda de login de usuário"
  type        = string
}

variable "auth_login_lambda_arn" {
  description = "ARN da função Lambda de login de usuário"
  type        = string
}
