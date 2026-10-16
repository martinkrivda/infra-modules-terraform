mock_provider "cloudflare" {}

variables {
  account_id = "00000000000000000000000000000000"
  zones = {
    "example.invalid" = { type = "full", paused = false }
  }
  dns_records = {
    stable_id = {
      zone     = "example.invalid"
      name     = "_sip._tcp.example.invalid"
      type     = "SRV"
      ttl      = 300
      data     = { priority = 1, weight = 5, port = 443, target = "service.example.invalid" }
      settings = { ipv4_only = false }
      tags     = ["owner:example"]
    }
  }
}

run "preserve_structured_records_and_zone_reference" {
  command = apply
  assert {
    condition     = cloudflare_dns_record.managed["stable_id"].data.port == 443
    error_message = "Structured DNS data must be retained."
  }
  assert {
    condition     = cloudflare_dns_record.managed["stable_id"].zone_id == cloudflare_zone.managed["example.invalid"].id
    error_message = "DNS records must use the actual managed zone ID."
  }
}
