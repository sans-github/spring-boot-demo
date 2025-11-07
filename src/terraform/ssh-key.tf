# Create a private key in PEM and Openssh PEM format
resource "tls_private_key" "tls_private_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Register the public key with AWS
resource "aws_key_pair" "aws_key_pair" {
  key_name   = var.ec2_key_name
  public_key = tls_private_key.tls_private_key.public_key_openssh
}

# # Output private key for local use
# output "private_key_pem" {
#   value     = tls_private_key.tls_private_key.private_key_pem
#   sensitive = true
# }

# Save the private key inside ~/.ssh and set 400 permission
resource "local_file" "local_file" {
  content         = tls_private_key.tls_private_key.private_key_pem
  filename        = "${pathexpand("~/.ssh/${var.ec2_key_name}.pem")}"
  file_permission = "0400"
}
