######### OUTPUTS ######################################################

# ID do API Gateway
output "api_gateway_id" {
  description = "ID do API Gateway criado"
  value       = aws_api_gateway_rest_api.api.id
}

# ARN do API Gateway
output "api_gateway_arn" {
  description = "ARN do API Gateway criado"
  value       = aws_api_gateway_rest_api.api.arn
}
