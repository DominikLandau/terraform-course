variable "nsg_resource_group_name" {
  type        = string
  description = "The name of the Resource Group in which to create the Network Security Group."
  default = "kurs1"
}

variable "nsg_location" {
  type        = string
  description = "The region where the Network Security Group is created."
  default     = "Germany West Central"
}

variable "nsg_name" {
  type        = string
  description = "The name of the Network Security Group."
  default = "nsg1"
}

variable "nsg_predefined_rules" {
  type        = list(any)
  default     = []
  description = "List of predefined rules for the Network Security Group"
}
