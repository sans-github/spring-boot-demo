output "api_invoke_base_url" {
  description = "Base invoke URL; append /author and your query/body as needed"
  value       = "https://${aws_api_gateway_rest_api.author_api.id}.execute-api.us-west-1.amazonaws.com/${aws_api_gateway_stage.stage.stage_name}/${aws_api_gateway_resource.author.path_part}"
}

output "EC2_IP_Address" {
  description = "EC2 IP Address"
  value       = "${aws_instance.spring-boot-api.public_ip}"
}

output "EC2_API_PATH" {
  description = "EC2 API PATH"
  value       = "http://${aws_instance.spring-boot-api.public_ip}:${var.backend_port}"
}
