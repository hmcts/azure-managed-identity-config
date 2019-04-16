import {readFileSync} from 'fs'
import * as YAML from 'yaml'

import * as pulumi from "@pulumi/pulumi"
import * as azure from "@pulumi/azure"

import {Environment, Identity, IdentityMapping, KeyVault} from "./src/models";
import {AccessPolicy} from "@pulumi/azure/keyvault";

const env = process.env.ENV

function handleKeyVaultUserManagedIdentity(mapping: Identity) {
    if (mapping.keyvaults) {
        // ARM_SUBSCRIPTION_ID env variable needs to point to the subscription that this will go into
        const identity = new azure.msi.UserAssignedIdentity(mapping.name, {
            name: mapping.name,
            location: 'uksouth',
            resourceGroupName: `managed-identities-${mapping.env}`,
        })

        const productProvider = new azure.Provider(mapping.name, {
            clientId: process.env.ARM_CLIENT_ID,
            clientSecret: process.env.ARM_CLIENT_SECRET,
            subscriptionId: mapping.subscription_id
        });

        mapping.keyvaults.forEach((keyVault: KeyVault) => {
            const keyVaultRg = `${keyVault.resource_group}-${mapping.env}`;
            const keyVaultName = `${keyVault.name}-${mapping.env}`
            let keyVaultId = `/subscriptions/${mapping.subscription_id}/resourcegroups/${keyVaultRg}/providers/Microsoft.KeyVault/vaults/${keyVaultName}`;
            new azure.role.Assignment(`${keyVaultName}-reader`, {
                principalId: identity.principalId,
                roleDefinitionName: "Reader",
                scope: keyVaultId
            }, {
                provider: productProvider
            })

            const current = pulumi.output(azure.core.getClientConfig({}))
            new AccessPolicy(keyVaultName,
                {
                    objectId: identity.principalId,
                    tenantId: current.tenantId,
                    certificatePermissions: ['get', 'list'],
                    keyPermissions: ['get', 'list'],
                    secretPermissions: ['get', 'list'],
                    keyVaultId
                }, {
                    provider: productProvider
                })
        })
    }
}

const file = readFileSync('./identity.yaml', 'utf8')

const mappings: IdentityMapping[] = YAML.parse(file).mappings;

mappings
    .map((mapping: IdentityMapping) => mapping.environments
        .map((environment: Environment) => {
                return {
                    env: environment.name,
                    subscription_id: environment.subscription_id,
                    name: `${mapping.name}-${environment.name}`,
                    keyvaults: mapping.keyvaults
                }
            }
        )
    )
    .flat()
    .filter((mapping: Identity) => mapping.env === env)
    .forEach(handleKeyVaultUserManagedIdentity)
