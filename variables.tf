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
