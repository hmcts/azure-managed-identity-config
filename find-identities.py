#!/usr/bin/env python3
import sys
import json
import yaml

# always only one line from terraform
# {"env":"sandbox"}
line = sys.stdin.readline()
query = json.loads(line)


def filter_environment():
    # for identity in identity_mapping:
    #     for environment in identity:
    #         if query['management_group'] in environment.management_group:
    #             add to result
    return filter(lambda x: (query['env'] for x['name']['environments'] in x['environments']), identity_config['mappings'])


with open("identity.yaml", 'r') as stream:
    identity_config = yaml.load(stream, Loader=yaml.FullLoader)

    result = {
        'identities': ';'.join([x['name'] for x in filter_environment()]),
        'keyvault_names': ';'.join(["{}-{}".format(x['keyvault']['name'], query['management_group'].lower()) for x in filter_environment()]),
        'keyvault_rgs': ';'.join(["{}-{}".format(x['keyvault']['resource_group'], query['management_group'].lower()) for x in filter_environment()]),
        'keyvault_subscription_ids': ';'.join(["{}-{}".format(x['keyvault']['resource_group'], query['management_group'].lower()) for x in filter_environment()]),
    }

    print(json.dumps(result))
