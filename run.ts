#!/usr/bin/env ts-node

import {readFileSync} from 'fs'
import * as YAML from 'yaml'

import {Environment, Identity, IdentityMapping, KeyVault} from "./src/models";

const args = process.argv.slice(2)
if (args.length !== 2) {
    console.log('usage: ./run.js [env] [aks_subscription_id]')
    process.exit(1)
}

const env = args[0]
const aksSubscription = args[1]

const {spawnSync} = require('child_process')

function handleKeyVaultUserManagedIdentity(mapping: Identity) {
    if (mapping.keyvaults) {
        mapping.keyvaults.forEach((keyvault: KeyVault) => {
            const run = spawnSync('./run.sh', {
                env: {
                    KEYVAULT_GROUP: `${keyvault.resource_group}-${mapping.env}`,
                    KEYVAULT_NAME: `${keyvault.name}-${mapping.env}`,
                    PRODUCT_SUBSCRIPTION_ID: mapping.subscription_id,

                    ENV: mapping.env,
                    IDENTITY_NAME: mapping.name,
                    AKS_SUBSCRIPTION_ID: aksSubscription
                }
            })

            console.log(`stdout: ${run.stdout.toString()}`);
            console.log(`stderr: ${run.stderr.toString()}`);
            console.log(`exit: ${run.status.toString()}`);

            if (run.status !== 0) {
                process.exit(run.status)
            }
            console.log('----------------------------------------------')
            console.log()
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