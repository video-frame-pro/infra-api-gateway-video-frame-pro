######### API GATEWAY OUTPUTS ##########################################
output "api_gateway_invoke_url" {
  value       = "${aws_api_gateway_deployment.api_deployment.invoke_url}/${var.stage_name}"
  description = "URL base para chamadas no API Gateway"
}

output "api_gateway_authorizer_arn" {
  value       = aws_api_gateway_authorizer.cognito_authorizer.id
  description = "ARN do autorizador Cognito"
}
