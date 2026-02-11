variable "cloudflare_api_token" {
  description = "Token for cloudflare"
  type        = string
  sensitive   = true
}

variable "aws_ssh_keys_location" {
  description = "SSH key location for aws"
  type        = string
}

