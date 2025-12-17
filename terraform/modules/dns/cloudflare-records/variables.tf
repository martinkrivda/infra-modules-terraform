variable "zone_id" { type = string }
variable "name"    { type = string }
variable "type"    { type = string } # "A", "CNAME"...
variable "value"   { type = string }

variable "proxied" {
  type    = bool
  default = true
}

variable "ttl" {
  type    = number
  default = 1 # auto
}
