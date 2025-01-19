output "api_gateway_id" {
  description = "ID do API Gateway"
  value       = aws_api_gateway_rest_api.video_frame_pro_api.id
}

output "api_gateway_url" {
  description = "URL do API Gateway"
  value       = "https://${aws_api_gateway_rest_api.video_frame_pro_api.id}.execute-api.${var.aws_region}.amazonaws.com/${var.stage_name}"
}

output "resource_ids" {
  description = "IDs dos recursos criados no API Gateway"
  value = {
    for k, v in aws_api_gateway_resource.resources :
    k => v.id
  }
}
