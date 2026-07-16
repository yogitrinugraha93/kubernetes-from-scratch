# Copy to terraform.tfvars (git-ignored) and fill in real values.
# OAuth2 credentials stay out of here - export them as env vars:
#   export TF_VAR_contabo_oauth2_client_id=...
#   export TF_VAR_contabo_oauth2_client_secret=...
#   export TF_VAR_contabo_oauth2_user=...
#   export TF_VAR_contabo_oauth2_pass=...

region = "SIN"

# Look up with: cntb get secrets
ssh_key_ids = [00000000]

# product_id / image_id are placeholders. Find real ones with:
#   cntb get products
#   cntb get images --standard
nodes = {
  "control-plane" = {
    role       = "control-plane"
    product_id = "V45"
    image_id   = "00000000-0000-0000-0000-000000000000"
  }
  "worker-1" = {
    role       = "worker"
    product_id = "V45"
    image_id   = "00000000-0000-0000-0000-000000000000"
  }
  "worker-2" = {
    role       = "worker"
    product_id = "V45"
    image_id   = "00000000-0000-0000-0000-000000000000"
  }
}
