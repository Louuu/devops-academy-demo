variable "location" {
    type = string
    default = "UK South"
}

variable "image_name" {
  type = string
}

variable "image_version" {
  type = string
}

variable "security_rules" {
  type    = map(any)
  default = {}
}

variable "admin_username" {
    type = string
    default = "admin_user"
}

variable "gitlab_url" {
  type = string
  sensitive = true
}

variable "gitlab_runner_token" {
  type = string
  sensitive = true
}

variable "gitlab_runner_name" {
  type = string
  default = "gitlab runner"
}