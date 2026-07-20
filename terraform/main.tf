# for_each over the nodes map, so the whole fleet comes from one block.
resource "hcloud_server" "node" {
  for_each = var.nodes

  name        = each.key
  server_type = each.value.server_type
  image       = each.value.image
  location    = var.location
  ssh_keys    = var.ssh_keys

  # Free, and makes nodes greppable in the console / API (and discoverable by a
  # dynamic inventory later). Cheap, so we use it.
  labels = { role = each.value.role }

  # Minimal cloud-init: just enough for Ansible to take over on first boot.
  # All real configuration stays in Ansible — one place to read the setup.
  user_data = file("${path.module}/cloud-init.yaml")
}

# Optional extra disk, only for nodes that ask for one (volume_size > 0).
# The Docker host uses this for the app's data (e.g. Postgres), so it survives
# a rebuilt server. Gating on volume_size keeps it out of nodes that don't need it.
resource "hcloud_volume" "data" {
  for_each = { for name, node in var.nodes : name => node if node.volume_size > 0 }

  name      = "${each.key}-data"
  size      = each.value.volume_size
  server_id = hcloud_server.node[each.key].id
  format    = "ext4"
  automount = false # mounted by Ansible so the mount point is defined in one place
}
