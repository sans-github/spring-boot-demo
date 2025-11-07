resource "aws_security_group" "ec2-spring-boot-api_security_group" {
  name = "ec2-spring-boot-app"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Exposes publicly; restrict for private use
  }

  ingress {
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    ipv6_cidr_blocks = ["::/0"] # Exposes publicly over IPv6; restrict for private use
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Exposes publicly; restrict for private use
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}