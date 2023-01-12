variable "workers_count" {
  type        = number
  description = "The number of workers to provision."
  default     = 1
}

variable "cluster_name" {
  type        = string
  description = "The name of the cluster."
  default     = "rik"
}

variable "ip_pool" {
  type        = string
  description = "Pool of public ip"
  default     = "public1"
}