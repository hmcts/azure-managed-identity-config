locals {
  input = "identity.yaml"
}

data "azurerm_subscription" "primary" {}

resource "azurerm_user_assigned_identity" "team_identity" {
  resource_group_name = "${var.resource_group_name}"
  location            = "${var.location}"

  name = "${lookup(var.identity_mapping[count.index], "identity")}-${var.env}"

  count = "${var.number_of_identities}"
}

resource "azurerm_role_assignment" "identity_permissions" {
  scope                = "${data.azurerm_subscription.primary.id}/resourcegroups/${lookup(var.identity_mapping[count.index], "keyvault_rg")}/providers/Microsoft.KeyVault/vaults/${lookup(var.identity_mapping[count.index], "keyvault_name")}"
  role_definition_name = "Reader"
  principal_id         = "${element(azurerm_user_assigned_identity.team_identity.*.principal_id, count.index)}"

  count = "${var.number_of_identities}"
}

data "azurerm_key_vault" "kv" {
  name                = "${lookup(var.identity_mapping[count.index], "keyvault_name")}"
  resource_group_name = "${lookup(var.identity_mapping[count.index], "keyvault_rg")}"

  count = "${var.number_of_identities}"
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

  count = "${var.number_of_identities}"
}

output "identity_mapping" {
  value = "${var.identity_mapping}"
}
