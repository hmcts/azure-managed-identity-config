export interface IdentityMapping {
    name: string
    environments: Environment[]
    keyvaults: KeyVault[]
}

export interface Environment {
    name: string
    subscription_id: string
}

export interface KeyVault {
    name: string
    resource_group: string
}

export interface Identity {
    env: string
    subscription_id: string
    name: string
    keyvaults?: KeyVault[]
}