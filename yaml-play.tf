locals {
  input          = "identity.yaml"
  identities     = "${split(";", data.external.identities.result.identities)}"
  keyvault_names = "${split(";", data.external.identities.result.keyvault_names)}"
  keyvault_rgs   = "${split(";", data.external.identities.result.keyvault_rgs)}"

  identity_mapping = "${null_resource.identity_mapping.*.triggers}"
}

data "azurerm_subscription" "primary" {}

data "external" "identities" {
  program = [
    "python3",
    "${path.module}/find-identities.py",
  ]

  query = {
    env = "${var.env}"
  }
}

resource "null_resource" "identity_mapping" {
  count = "${length(local.identities)}"

  triggers {
    identity      = "${element(local.identities, count.index)}"
    keyvault_name = "${element(local.keyvault_names, count.index)}"
    keyvault_rg   = "${element(local.keyvault_rgs, count.index)}"
  }
}

resource "azurerm_user_assigned_identity" "team_identity" {
  resource_group_name = "timj-identity-${var.env}"
  location            = "${var.location}"

  name = "${lookup(local.identity_mapping[count.index], "identity")}-${var.env}"

  count = "${length(local.identities)}"
}

resource "azurerm_role_assignment" "identity_permissions" {
  scope                = "${data.azurerm_subscription.primary.id}/resourcegroups/${lookup(local.identity_mapping[count.index], "keyvault_rg")}/providers/Microsoft.KeyVault/vaults/${lookup(local.identity_mapping[count.index], "keyvault_name")}"
  role_definition_name = "Reader"
  principal_id         = "${element(azurerm_user_assigned_identity.team_identity.*.principal_id, count.index)}"

  count = "${length(local.identities)}"
}

data "azurerm_key_vault" "kv" {
  name                = "${lookup(local.identity_mapping[count.index], "keyvault_name")}"
  resource_group_name = "${lookup(local.identity_mapping[count.index], "keyvault_rg")}"

  count = "${length(local.identities)}"
}

resource "azurerm_key_vault_access_policy" "identity_access_policy" {
  key_vault_id = "${element(data.azurerm_key_vault.kv.*.id, count.index)}"

  object_id = "${element(azurerm_user_assigned_identity.team_identity.*.principal_id, count.index)}"
  tenant_id = "${var.tenant_id}"

  certificate_permissions = [
    "get",
    "list",
  ]

  key_permissions = [
    "get",
    "list",
  ]

  secret_permissions = [
    "get",
    "list",
  ]

  count = "${length(local.identities)}"
}


output "normal" {
  value = "${local.identity_mapping}"
}
