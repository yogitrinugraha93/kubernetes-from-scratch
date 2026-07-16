variable "region" {
  type        = string
  description = "Contabo region code. Singapore is SIN."
  default     = "SIN"
}

# SSH public key secret IDs from Contabo. Real IDs go in terraform.tfvars.
variable "ssh_key_ids" {
  type        = list(number)
  description = "Contabo secret IDs of the SSH keys to inject into every node."
  default     = []
}

# Cluster topology as data. Adding a node is just another map entry.
variable "nodes" {
  type = map(object({
    role       = string # control-plane | worker
    product_id = string # Contabo VPS size, e.g. V45
    image_id   = string # OS image (Ubuntu 22.04)
  }))
  description = "Cluster nodes keyed by hostname."

  validation {
    condition = alltrue([
      for n in var.nodes : contains(["control-plane", "worker"], n.role)
    ])
    error_message = "node role must be control-plane or worker."
  }
}
