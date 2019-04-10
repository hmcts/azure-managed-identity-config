provider "azurerm" {
  subscription_id = ""

  alias = "user"
}

locals {
  identity_mapping = "${null_resource.identity_mapping.*.triggers}"
  identities       = "${split(";", data.external.identities.result.identities)}"
  keyvault_names   = "${split(";", data.external.identities.result.keyvault_names)}"
  keyvault_rgs     = "${split(";", data.external.identities.result.keyvault_rgs)}"
  subscription_ids     = "${split(";", data.external.identities.result.subscription_ids)}"
}

module "azure-identity-management" {
  source               = "./module"
  identity_mapping     = "${local.identity_mapping}"
  env                  = "${var.env}"
  number_of_identities = "${length(local.identities)}"
  location             = "${var.location}"
  resource_group_name  = "managed-identities-${var.env}" // rg must be pre-created
  tenant_id            = "${var.tenant_id}"
}

resource "null_resource" "identity_mapping" {
  count = "${length(local.identities)}"

  triggers {
    identity      = "${element(local.identities, count.index)}"
    keyvault_name = "${element(local.keyvault_names, count.index)}"
    keyvault_rg   = "${element(local.keyvault_rgs, count.index)}"
    subscription_ids   = "${element(local.subscription_ids, count.index)}"
  }
}

output "identity_mapping_out" {
  value = "${null_resource.identity_mapping.*.triggers}"
}

data "external" "identities" {
  program = [
    "node",
    "${path.module}/find-identities.js",
  ]

  query = {
    env = "${var.env}"
  }
}

//output "identity_mapping" {
//  value = "${module.azure-identity-management.identity_mapping}"
//}
