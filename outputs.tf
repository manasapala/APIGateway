output "api_gateway_key" {
  value       = aws_api_gateway_api_key.vg_api_gateway_key.value
  description = "The arn of the application load balancer created"
}
output "authorizer" {
  value = aws_lambda_function.authorizer.id
}
output "aws_api_gateway_client_certificate_id" {
  value = aws_api_gateway_client_certificate.demo.id
}
