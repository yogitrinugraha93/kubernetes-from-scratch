# for_each over the nodes map so the whole fleet comes from one block.
resource "contabo_instance" "node" {
  for_each = var.nodes

  display_name = each.key
  product_id   = each.value.product_id
  image_id     = each.value.image_id
  region       = var.region
  ssh_keys     = var.ssh_key_ids
}
