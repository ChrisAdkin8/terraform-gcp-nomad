resource "google_compute_firewall" "rules" {
  for_each = local.firewall_rules

  name        = "${var.name_prefix}-${replace(each.key, "_", "-")}"
  network     = google_compute_network.default.name
  direction   = each.value.direction
  description = each.value.description
  
  dynamic "allow" {
    for_each = each.value.rules
    content {
      protocol = allow.value.protocol
      ports    = allow.value.ports
    }
  }

  source_ranges = lookup(each.value, "source_ranges", null)
  source_tags   = lookup(each.value, "source_tags", null)
  target_tags   = each.value.target_tags
}