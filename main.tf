locals {
  identity_mapping = "${null_resource.identity_mapping.*.triggers}"
  identities       = "${split(";", data.external.identities.result.identities)}"
  keyvault_names   = "${split(";", data.external.identities.result.keyvault_names)}"
  keyvault_rgs     = "${split(";", data.external.identities.result.keyvault_rgs)}"
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
  }
}

data "external" "identities" {
  program = [
    "python3",
    "${path.module}/find-identities.py",
  ]

  query = {
    env = "${var.env}"
  }
}

output "identity_mapping" {
  value = "${module.azure-identity-management.identity_mapping}"
}
