# Node -> public IP. Paste these into the Ansible inventory before running a playbook.
output "node_ips" {
  value = { for name, server in hcloud_server.node : name => server.ipv4_address }
}

# Convenience views by role, so the inventory groups are easy to fill in.
output "docker_ips" {
  value = {
    for name, server in hcloud_server.node : name => server.ipv4_address
    if var.nodes[name].role == "docker"
  }
}

output "control_plane_ips" {
  value = {
    for name, server in hcloud_server.node : name => server.ipv4_address
    if var.nodes[name].role == "control-plane"
  }
}

output "worker_ips" {
  value = {
    for name, server in hcloud_server.node : name => server.ipv4_address
    if var.nodes[name].role == "worker"
  }
}
