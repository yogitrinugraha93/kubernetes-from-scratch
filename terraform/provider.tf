# Hetzner Cloud API token — one token, versus Contabo's four OAuth2 fields.
# TODO: Securely load this value from an environment variable or secrets vault. Do not hardcode.
#   export HCLOUD_TOKEN=...        (the provider reads this directly), or
#   export TF_VAR_hcloud_token=...
variable "hcloud_token" {
  type      = string
  sensitive = true
  default   = null # null lets the provider fall back to HCLOUD_TOKEN
}

provider "hcloud" {
  token = var.hcloud_token
}
