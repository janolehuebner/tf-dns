output "zones" {
  value = length(local.zones)
}
output "zone_ids" {
  value = { for name, zone in hetznerdns_zone.zone : name => zone.id }
}
