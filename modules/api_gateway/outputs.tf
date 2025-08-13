output "invoke_url" {
  description = "URL para invocar la API Gateway."
  value       = aws_api_gateway_stage.prod.invoke_url
}