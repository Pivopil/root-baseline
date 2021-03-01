import os
import logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)


def generate_policy(principal_id, effect, resource):
    return {
        'principalId': principal_id,
        'policyDocument': {
            'Version': '2012-10-17',
            'Statement': [
                {
                    "Action": "execute-api:Invoke",
                    "Effect": effect,
                    "Resource": resource
                }
            ]
        }
    }


def auth(event, context):
    whole_auth_token = event.get('authorizationToken')
    if not whole_auth_token:
        raise Exception('Unauthorized')

    effect = 'Deny'

    if whole_auth_token.lower() == os.environ['token']:
        effect = 'Allow'
        logger.info(event)

    try:
        return generate_policy("User", effect, event['methodArn'])
    except Exception as e:
        logger.info(f'Exception encountered: {e}')
        raise Exception('Unauthorized')
