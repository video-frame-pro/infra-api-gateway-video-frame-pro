# Output da URL do API Gateway
output "api_url" {
  description = "URL do API Gateway para consumo das APIs"
  value       = "${aws_api_gateway_deployment.video_frame_pro_api_deployment.invoke_url}/prod"
}
