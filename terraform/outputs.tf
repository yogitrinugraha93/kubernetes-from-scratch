# Node -> public IP. Paste these into the Ansible inventory in Phase 2.
output "node_ips" {
  value = { for name, inst in contabo_instance.node : name => inst.ip_config[0].v4[0].ip }
}

output "control_plane_ips" {
  value = {
    for name, inst in contabo_instance.node : name => inst.ip_config[0].v4[0].ip
    if var.nodes[name].role == "control-plane"
  }
}

output "worker_ips" {
  value = {
    for name, inst in contabo_instance.node : name => inst.ip_config[0].v4[0].ip
    if var.nodes[name].role == "worker"
  }
}
