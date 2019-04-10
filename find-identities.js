#!/usr/bin/env node

const fs = require('fs')
const YAML = require('yaml')

const readline = require('readline');
const rl = readline.createInterface({
    input: process.stdin
})

// always only one line from terraform
// {"env":"sandbox"}
rl.on('line', (line) => {
    const env = JSON.parse(line).env

    const file = fs.readFileSync('./identity.yaml', 'utf8')

    const message = YAML.parse(file);

    const filtered_map = message.mappings
        .map(mapping => {
                return mapping.environments
                    .map(environment => {
                            return {
                                env: environment.name,
                                subscription_id: environment.subscription_id,
                                name: `${mapping.name}-${environment.name}`,
                                keyvault_name: `${mapping.keyvault.name}-${environment.name}`,
                                keyvault_rg: `${mapping.keyvault.resource_group}-${environment.name}`
                            }
                        }
                    )

            }
        )
        .flat()
        .filter(mapping => mapping.env === env)

    const result = {
        subscription_ids: filtered_map.map(mapping => mapping.subscription_id).join(';'),
        identities: filtered_map.map(mapping => mapping.name).join(';'),
        keyvault_names: filtered_map.map(mapping => mapping.keyvault_name).join(';'),
        keyvault_rgs: filtered_map.map(mapping => mapping.keyvault_rg).join(';'),
    }

    console.log(JSON.stringify(result))
})