variable "account_id" {
  description = "Cloudflare Zero Trust account ID."
  type        = string

}

variable "cloudflared_tunnels" {
  description = "Tunnel metadata keyed by stable ID or label; name is independent of the key."
  type        = any
  default     = {}
}

variable "cloudflared_tunnel_configs" {
  description = "Full remote configuration: tunnel key, ingress, origin_request and explicit warp_routing_enabled."
  type        = any
  default     = {}
}

variable "tunnel_routes" {
  description = "Private network CIDR routes: network, tunnel key, optional virtual_network key and comment."
  type        = any
  default     = {}
}

variable "virtual_networks" {
  description = "Virtual networks with name, comment and is_default_network."
  type        = any
  default     = {}
}

variable "access_applications" {
  description = "Full provider application attributes; policies may contain a policy map key or inline application-exclusive policy."
  type        = any
  default     = {}
}

variable "access_policies" {
  description = "Reusable account policies. Optional application and precedence retain compatibility with legacy inputs."
  type        = any
  default     = {}
}

variable "read_tunnel_tokens" {
  description = "Read remote tunnel tokens only when deployment needs them; tokens are stored in state."
  type        = bool
  default     = false
}

