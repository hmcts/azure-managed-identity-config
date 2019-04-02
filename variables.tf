provider "azurerm" {
  version = "=1.23.0"
}

provider "external" {
  version = "=1.1"
}

provider "null" {
  version = "=2.1"
}

variable "env" {
  default = "saat"
}

variable "location" {
  default = "UK South"
}

variable "tenant_id" {
  default = "a0d77fc4-df1e-4b0d-8e35-46750ca5a672"
}
