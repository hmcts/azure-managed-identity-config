#!/usr/bin/env python3
import sys
import json
import yaml

# always only one line from terraform
# {"env":"sandbox"}
line = sys.stdin.readline()
query = json.loads(line)


def filter_for_env():
    return filter(lambda x: query['env'] in x['environments'], identity_config)


with open("identity.yaml", 'r') as stream:
    identity_config = yaml.load(stream)

    result = {}
    result['identities'] = ';'.join(list(map(lambda f: f['name'], filter_for_env())))
    result['keyvault_names'] = ';'.join(list(map(lambda f: f['keyvault']['name'], filter_for_env())))
    result['keyvault_rgs'] = ';'.join(list(map(lambda f: f['keyvault']['resource_group'], filter_for_env())))

    print(json.dumps(result))
