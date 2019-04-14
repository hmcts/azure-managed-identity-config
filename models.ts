export class IdentityMapping {
    name: string
    environments: Environment[]
    keyvaults: KeyVault[]
}

export class Environment {
    name: string
    subscription_id: string
}

export class KeyVault {
    name: string
    resource_group: string
}

export class Identity {
    env: string
    subscription_id: string
    name: string
    keyvaults?: KeyVault[]
}