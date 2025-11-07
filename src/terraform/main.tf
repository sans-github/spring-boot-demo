resource "aws_instance" "spring-boot-api" {
  instance_type = "t3.micro"
  # https://aws.amazon.com/ec2/pricing/on-demand/?icmpid=docs_console_unmapped
  ami                    = "ami-0c1a6eb95aba250b6"
  vpc_security_group_ids = [aws_security_group.ec2-spring-boot-api_security_group.id]
  key_name               = aws_key_pair.aws_key_pair.key_name
  user_data = file("setup-app.sh")
  
  tags = {
    Name = "spring-boot-api-instance"
  }
}

output "EC2_IP_Address" {
  description = "EC2 IP Address"
  value       = "http://${aws_instance.spring-boot-api.public_ip}:${var.backend_port}"
}

# REST API (The first "Create API" button)
resource "aws_api_gateway_rest_api" "author_api" {
  name        = "My Author API"
  description = "API Gateway fronting Spring Boot on EC2"
}

# /author Resource (The second step)
resource "aws_api_gateway_resource" "author" {
  rest_api_id = aws_api_gateway_rest_api.author_api.id
  parent_id   = aws_api_gateway_rest_api.author_api.root_resource_id
  path_part   = "author"
}

# GET method on /author (Step numero tres for GET)
resource "aws_api_gateway_method" "get_author" {
  rest_api_id   = aws_api_gateway_rest_api.author_api.id
  resource_id   = aws_api_gateway_resource.author.id
  http_method   = "GET"
  authorization = "NONE"
}

# HTTP_PROXY integration for GET -> forwards query string automatically. Check box on step 3
resource "aws_api_gateway_integration" "get_author_integration" {
  rest_api_id             = aws_api_gateway_rest_api.author_api.id
  resource_id             = aws_api_gateway_resource.author.id
  http_method             = aws_api_gateway_method.get_author.http_method
  integration_http_method = "GET"
  type                    = "HTTP_PROXY"
  uri = "http://${aws_instance.spring-boot-api.public_ip}:${var.backend_port}/${aws_api_gateway_resource.author.path_part}"
  passthrough_behavior    = "WHEN_NO_MATCH"
  connection_type         = "INTERNET"
}

# POST method on /author (Step numero tres for POST)
resource "aws_api_gateway_method" "post_author" {
  rest_api_id   = aws_api_gateway_rest_api.author_api.id
  resource_id   = aws_api_gateway_resource.author.id
  http_method   = "POST"
  authorization = "NONE"
}

# HTTP_PROXY integration for POST -> forwards body and headers automatically. Check box on step 3
resource "aws_api_gateway_integration" "post_author_integration" {
  rest_api_id             = aws_api_gateway_rest_api.author_api.id
  resource_id             = aws_api_gateway_resource.author.id
  http_method             = aws_api_gateway_method.post_author.http_method
  integration_http_method = "POST"
  type                    = "HTTP_PROXY"
  uri = "http://${aws_instance.spring-boot-api.public_ip}:${var.backend_port}/${aws_api_gateway_resource.author.path_part}"
  passthrough_behavior    = "WHEN_NO_MATCH"
  connection_type         = "INTERNET"
}

# Deployment
resource "aws_api_gateway_deployment" "deployment" {
  rest_api_id = aws_api_gateway_rest_api.author_api.id

  depends_on = [
    aws_api_gateway_integration.get_author_integration,
    aws_api_gateway_integration.post_author_integration
  ]
}

# Create "test" stage
resource "aws_api_gateway_stage" "stage" {
  rest_api_id   = aws_api_gateway_rest_api.author_api.id
  deployment_id = aws_api_gateway_deployment.deployment.id
  stage_name    = var.stage_name
}

output "api_invoke_base_url" {
  description = "Base invoke URL; append /author and your query/body as needed"
  value       = "https://${aws_api_gateway_rest_api.author_api.id}.execute-api.us-west-1.amazonaws.com/${aws_api_gateway_stage.stage.stage_name}/${aws_api_gateway_resource.author.path_part}"
}