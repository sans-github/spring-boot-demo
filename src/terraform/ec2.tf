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