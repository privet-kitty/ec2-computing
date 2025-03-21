variable "aws_region" {
  type    = string
  default = "ap-northeast-1"
}

variable "unique_name" {
  type        = string
  description = "unique name to avoid conflict"
}

variable "project_code" {
  type    = string
  default = null
}


variable "allowed_cidr" {
  type    = string
  default = null
}


variable "instance_type" {
  type    = string
  default = "c6i.large"
}
