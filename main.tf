provider "cloudflare" {
  api_token = local.cloudflare_api.auth.api_token
}

locals {
  cloudflare_api = yamldecode(file("${path.module}/auth.yaml"))
  zones          = yamldecode(file("${path.module}/zones.yaml"))

  zone_data = flatten([
    for zone_name, records in local.zones : [
      for record_type, record_values in records : [
        for record_name, record_value in record_values : {
          zone_name    = zone_name
          record_type  = upper(record_type)
          record_value = record_value
          extra_data   = strcontains(record_name, "/") ? split( "/",record_name)[1] : ""
          record_name  = strcontains(record_name, "/") ? split( "/",record_name)[0] : record_name

        }
      ]
    ]
  ])
}

data "cloudflare_zone" "zone" {
  for_each = local.zones
  name = each.key
}
resource "cloudflare_record" "myrecord" {
for_each = {
  for record in local.zone_data : "${record.record_type}${record.extra_data}-${record.record_name}.${record.zone_name}" => record }

  zone_id = data.cloudflare_zone.zone[each.value.zone_name].id
  name      = "${each.value.record_name}.${each.value.zone_name}" == "@.${each.value.zone_name}" ? each.value.zone_name : "${each.value.record_name}.${each.value.zone_name}"
  type      = each.value.record_type
  value     = each.value.record_value
  ttl       = 300
  priority  = each.value.record_type == "MX" ? tonumber(each.value.extra_data) : 0
}