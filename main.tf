

locals {
  api   = yamldecode(file("${path.module}/auth.yaml"))
  zones = yamldecode(file("${path.module}/zones.yaml"))
  nameservers = data.hetznerdns_nameservers.primary.ns





  ns_data = flatten([
    for zone_name, records in local.zones : [
      for ns_entry in local.nameservers : {
        zone_name    = zone_name
        record_type  = "NS"
        record_value = ns_entry.name
        record_name  = "@"
        extra_data   = ""
      }
    ]
  ])

  zone_data = flatten([
    for zone_name, records in local.zones : [
      records == null ? [] : [
      for record_type, record_values in records : [
        for record_name, record_value in record_values : {
          zone_name    = zone_name
          record_type  = upper(record_type)
          record_value = record_value
          extra_data   = strcontains(record_name, "/") ? split( "/",record_name)[1] : ""
          record_name  = strcontains(record_name, "/") ? split( "/",record_name)[0] : record_name

        }
      ]
    ]]
  ])
}

data "hetznerdns_nameservers" "primary" {
  type = "authoritative"
}

resource "hetznerdns_zone" "zone" {
  for_each  = local.zones
  name      = each.key
  ttl       = 300
}

resource "hetznerdns_record" "myrecord" {
for_each = {
  for record in local.zone_data : "${record.record_type}${record.extra_data}-${record.record_name}.${record.zone_name}" => record }

  zone_id = hetznerdns_zone.zone[each.value.zone_name].id
  name    = "${each.value.record_name}"
  type    = each.value.record_type
  value   = each.value.record_type == "MX" ? "${each.value.extra_data} ${each.value.record_value}" : each.value.record_value
  ttl     = 300

}


resource "hetznerdns_record" "ns" {
  for_each = {
    for record in local.ns_data :
      "${record.record_type}-${record.record_name}-${record.zone_name}-${record.record_value}" => record
  }

  zone_id = hetznerdns_zone.zone[each.value.zone_name].id
  name    = each.value.record_name
  type    = each.value.record_type
  value   = each.value.record_value
  ttl     = 300
}