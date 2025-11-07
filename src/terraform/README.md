# Resources created

| **Resource Name** | **Purpose** |
|--------------------|-------------|
| `aws_instance.spring-boot-api` | Launches the EC2 instance that runs the Spring Boot application. |
| `aws_key_pair.aws_key_pair` | Provides SSH access credentials for the EC2 instance. |
| `aws_api_gateway_rest_api.author_api` | Creates the REST API container in API Gateway. |
| `aws_api_gateway_resource.author` | Defines the `/author` resource path under the REST API. |
| `aws_api_gateway_method.get_author` | Configures the GET method for the `/author` endpoint. |
| `aws_api_gateway_method.post_author` | Configures the POST method for the `/author` endpoint. |

# Convenience scripts