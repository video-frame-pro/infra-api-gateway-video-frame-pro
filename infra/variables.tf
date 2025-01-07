# Variável para a região da AWS
variable "aws_region" {
  description = "Região da AWS onde os recursos serão criados"
  type        = string
  default     = "us-east-1"
}
# Variável para o ID do User Pool do Cognito
variable "cognito_user_pool_id" {
  description = "ID do User Pool do Cognito"
  type        = string
}

# Variável para o ARN do User Pool do Cognito
variable "cognito_user_pool_arn" {
  description = "ARN do User Pool do Cognito"
  type        = string
}