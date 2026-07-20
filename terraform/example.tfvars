# Copy to terraform.tfvars (git-ignored) and fill in real values.
# The API token stays out of here — export it instead:
#   export HCLOUD_TOKEN=...        (read directly by the provider), or
#   export TF_VAR_hcloud_token=...

location = "sin"

# SSH key names as registered in the Hetzner Console (Security > SSH keys).
ssh_keys = ["my-laptop"]

# Track B — Docker host. One server plus a 20 GB volume for the app's data.
# Server types: `hcloud server-type list`   Images: `hcloud image list`
nodes = {
  "app-1" = {
    role        = "docker"
    server_type = "cx22" # 2 vCPU / 4 GB — right-sized for a small app
    image       = "ubuntu-24.04"
    volume_size = 20
  }
}

# Track A — Kubernetes lab (uncomment when working the K8s track):
# nodes = {
#   "cp-1"     = { role = "control-plane", server_type = "cx22", image = "ubuntu-24.04" }
#   "worker-1" = { role = "worker",        server_type = "cx22", image = "ubuntu-24.04" }
#   "worker-2" = { role = "worker",        server_type = "cx22", image = "ubuntu-24.04" }
# }
