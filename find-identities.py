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
    identity_config = yaml.load(stream, Loader=yaml.FullLoader)

    result = {'identities': ';'.join([x['name'] for x in filter_for_env()])}
    result['keyvault_names'] = ';'.join(["{}-{}".format(x['keyvault']['name'], query['env']) for x in filter_for_env()])
    result['keyvault_rgs'] = ';'.join(["{}-{}".format(x['keyvault']['resource_group'], query['env']) for x in filter_for_env()])

    print(json.dumps(result))
