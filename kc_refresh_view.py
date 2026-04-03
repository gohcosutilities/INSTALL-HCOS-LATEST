import json
import logging as pylogging
import urllib.parse
import urllib.request
import ssl

from django.conf import settings
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt

_kc_logger = pylogging.getLogger('websiteFunctions.kc_refresh')

def _kc_refresh_settings():
    server = getattr(settings, 'KEYCLOAK_SERVER_URL', 'https://key.hcos.io').rstrip('/')
    realm = getattr(settings, 'KEYCLOAK_REALM_NAME', 'master')
    client_id = getattr(settings, 'KEYCLOAK_CLIENT_ID', 'hcos-backend')
    client_secret = getattr(settings, 'KEYCLOAK_CLIENT_SECRET', '')
    verify_ssl = getattr(settings, 'KEYCLOAK_VERIFY_SSL', 'true').lower() != 'false'
    token_url = f"{server}/realms/{realm}/protocol/openid-connect/token"
    return client_id, client_secret, token_url, verify_ssl

@csrf_exempt
def kc_refresh_token(request):
    if request.method != 'POST':
        return JsonResponse({'error': 'Method not allowed'}, status=405)

    # Must be logged into CyberPanel
    if 'userID' not in request.session:
        return JsonResponse({'error': 'Not authenticated'}, status=401)

    refresh_token = request.session.get('keycloak_refresh_token', '')
    if not refresh_token:
        return JsonResponse({'error': 'No refresh token in session'}, status=401)

    client_id, client_secret, token_url, verify_ssl = _kc_refresh_settings()

    data = urllib.parse.urlencode({
        'grant_type': 'refresh_token',
        'client_id': client_id,
        'client_secret': client_secret,
        'refresh_token': refresh_token,
    }).encode('utf-8')

    req = urllib.request.Request(
        token_url,
        data=data,
        headers={'Content-Type': 'application/x-www-form-urlencoded'},
    )

    ssl_ctx = None
    if not verify_ssl:
        ssl_ctx = ssl.create_default_context()
        ssl_ctx.check_hostname = False
        ssl_ctx.verify_mode = ssl.CERT_NONE

    try:
        with urllib.request.urlopen(req, context=ssl_ctx) as resp:
            tokens = json.loads(resp.read().decode('utf-8'))
    except urllib.error.HTTPError as e:
        body = e.read().decode('utf-8', errors='replace')
        _kc_logger.error('Keycloak refresh failed: HTTP %s: %s', e.code, body)
        return JsonResponse({'error': 'Token refresh failed'}, status=502)
    except Exception as e:
        _kc_logger.error('Keycloak refresh error: %s', e)
        return JsonResponse({'error': 'Token refresh failed'}, status=502)

    new_access = tokens.get('access_token', '')
    new_refresh = tokens.get('refresh_token', '')
    new_id = tokens.get('id_token', '')

    # Update session with fresh tokens
    if new_access:
        request.session['keycloak_access_token'] = new_access
    if new_refresh:
        request.session['keycloak_refresh_token'] = new_refresh
    if new_id:
        request.session['keycloak_id_token'] = new_id

    return JsonResponse({'access_token': new_access})
