output "zones" {
  value = data.cloudflare_zone.zone
}
output "records" {
  value = cloudflare_record.myrecord
}
