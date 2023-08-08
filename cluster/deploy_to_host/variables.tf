variable "buildkite_agent_token" {
  type = string
  sensitive = true
}

variable "http_proxy_url" {
  type = string
}

variable "root_password" {
  type = object({
    bcrypt_hash = string
  })

  sensitive = true
}

variable "storage_pool" {
  type = string
  default = "default"
}
