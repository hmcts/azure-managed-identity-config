#!/usr/bin/env bash

set -eu

echo

echo "Starting update user managed identity, config:"

echo -e "ENV:\t\t\t\t $ENV"
echo -e "IDENTITY_NAME:\t\t\t $IDENTITY_NAME"
echo -e "KEYVAULT_NAME:\t\t\t $KEYVAULT_NAME"
echo -e "KEYVAULT_GROUP:\t\t\t $KEYVAULT_GROUP"
echo -e "PRODUCT_SUBSCRIPTION_ID:\t $PRODUCT_SUBSCRIPTION_ID"
echo -e "AKS_SUBSCRIPTION_ID:\t\t $AKS_SUBSCRIPTION_ID"

echo
export AZURE_CONFIG_DIR=.azure/

function create_user_managed_identity() {
    # this is idempotent
    az identity create --resource-group managed-identities-${ENV} --name ${IDENTITY_NAME} --subscription ${AKS_SUBSCRIPTION_ID} --query principalId -o tsv
}

function add_keyvault_reader_role() {
    local PRINCIPAL_ID=${1}

    echo 'Checking if role assignment exists for keyvault'
    set +e
    RESULT=$(az role assignment list --role Reader --assignee ${PRINCIPAL_ID} --subscription ${PRODUCT_SUBSCRIPTION_ID} --scope "/subscriptions/${PRODUCT_SUBSCRIPTION_ID}/resourcegroups/${KEYVAULT_GROUP}/providers/Microsoft.KeyVault/vaults/${KEYVAULT_NAME}" --query "[] | length(@)")
    set -e
    if [[ $? -ne 0 ]] || [[ ${RESULT} -ne 1 ]]  ; then
        echo 'Creating new role assignment for keyvault'
        az role assignment create --role Reader --assignee-object-id ${PRINCIPAL_ID} --subscription ${PRODUCT_SUBSCRIPTION_ID} --scope "/subscriptions/${PRODUCT_SUBSCRIPTION_ID}/resourcegroups/${KEYVAULT_GROUP}/providers/Microsoft.KeyVault/vaults/${KEYVAULT_NAME}"
        echo 'Finished new role assignment for keyvault'
    else
        echo "Role assignment already exists skipping"
    fi
}

function add_access_policy() {
    local PRINCIPAL_ID=${1}

    echo 'Starting Create / Update access policy for keyvault'

    az keyvault set-policy --name ${KEYVAULT_NAME} \
      --secret-permissions get list \
      --certificate-permissions get getissuers list \
      --key-permissions get list  \
      --storage-permissions get getsas list listsas \
      --object-id ${PRINCIPAL_ID} \
      --subscription ${PRODUCT_SUBSCRIPTION_ID}

    echo 'Finished Create / Update access policy for keyvault'
}


echo 'Starting Create / Update user managed identity'
IDENTITY_PRINCIPAL_ID=$(create_user_managed_identity)
echo 'Finished Create / Update user managed identity'

add_keyvault_reader_role ${IDENTITY_PRINCIPAL_ID}
add_access_policy ${IDENTITY_PRINCIPAL_ID}

echo
echo "Finished updating user managed identity"
