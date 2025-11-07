variable "ec2_key_name" {
  description = "Name for the EC2 SSH key"
  type        = string
  default     = "tf_ec2_key"
}

variable "backend_port" {
  type    = string
  default = "8080"
}

variable "stage_name" {
  type    = string
  default = "test"
}
