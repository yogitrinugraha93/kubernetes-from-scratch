# Contabo API credentials (OAuth2). Values come from a git-ignored terraform.tfvars
# or environment variables. Never hardcode secrets here.
variable "contabo_oauth2_client_id" {
  type      = string
  sensitive = true
}

variable "contabo_oauth2_client_secret" {
  type      = string
  sensitive = true
}

variable "contabo_oauth2_user" {
  type      = string
  sensitive = true
}

variable "contabo_oauth2_pass" {
  type      = string
  sensitive = true
}

provider "contabo" {
  oauth2_client_id     = var.contabo_oauth2_client_id
  oauth2_client_secret = var.contabo_oauth2_client_secret
  oauth2_user          = var.contabo_oauth2_user
  oauth2_pass          = var.contabo_oauth2_pass
}
