variable "location" {
  type        = string
  description = "Hetzner location. Singapore is sin (low latency from Indonesia)."
  default     = "sin"
}

# Names of SSH keys already registered in the Hetzner project (Console > Security).
# Simpler than Contabo's numeric secret IDs — just the human-readable names.
variable "ssh_keys" {
  type        = list(string)
  description = "Hetzner SSH key names to inject into every node."
}

# Topology as data. Adding a node is just another map entry; the same map serves
# both the Docker host (role = docker) and, later, the Kubernetes nodes.
variable "nodes" {
  type = map(object({
    role        = string              # docker | control-plane | worker
    server_type = string              # Hetzner type, e.g. cx22 (2 vCPU / 4 GB)
    image       = string              # OS image, e.g. ubuntu-24.04
    volume_size = optional(number, 0) # GB of extra persistent disk; 0 = none
  }))
  description = "Nodes keyed by hostname."

  validation {
    condition = alltrue([
      for n in var.nodes : contains(["docker", "control-plane", "worker"], n.role)
    ])
    error_message = "node role must be docker, control-plane, or worker."
  }
}
