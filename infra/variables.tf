variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Ambiente (prod, dev, etc.)"
  type        = string
  default     = "prod"
}

variable "stage_name" {
  description = "Nome do estágio da API (prod, dev, etc.)"
  type        = string
  default     = "prod"
}
