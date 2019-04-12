#!/usr/bin/env node

const fs = require('fs')
const YAML = require('yaml')

const args = process.argv.slice(2)
if (args.length !== 2) {
    console.log('usage: ./run.js [env] [aks_subscription_id]')
    process.exit(1)
}

const aks_sub = '50f88971-400a-4855-8924-c38a47112ce4'
const env = 'saat'

const {spawnSync} = require('child_process')

function handleKeyVaultUserManagedIdentity(mapping) {
    if (mapping.keyvaults) {
        mapping.keyvaults.forEach(keyvault => {
            const run = spawnSync('./run.sh', {
                env: {
                    KEYVAULT_GROUP: `${keyvault.resource_group}-${mapping.env}`,
                    KEYVAULT_NAME: `${keyvault.name}-${mapping.env}`,
                    PRODUCT_SUBSCRIPTION_ID: mapping.subscription_id,

                    ENV: mapping.env,
                    IDENTITY_NAME: mapping.name,
                    AKS_SUBSCRIPTION_ID: aks_sub
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

const file = fs.readFileSync('./identity.yaml', 'utf8')

const message = YAML.parse(file);

message.mappings
    .map(mapping => mapping.environments
        .map(environment => {
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
    .filter(mapping => mapping.env === env)
    .forEach(handleKeyVaultUserManagedIdentity)