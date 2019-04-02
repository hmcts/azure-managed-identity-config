variable "env" {}

variable "location" {}

variable "tenant_id" {
  default = "a0d77fc4-df1e-4b0d-8e35-46750ca5a672"
}

variable "identity_mapping" {
  type = "list"
}

variable "number_of_identities" {}

variable "resource_group_name" {}
