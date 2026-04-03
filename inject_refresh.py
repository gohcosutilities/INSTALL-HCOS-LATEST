"""Inject kc_refresh_token view into websiteFunctions/views.py"""
import sys

VIEWS_PATH = '/usr/local/CyberCP/websiteFunctions/views.py'
REFRESH_PATH = '/tmp/kc_refresh_view.py'

with open(VIEWS_PATH, 'r') as f:
    content = f.read()

# Check if already injected
if 'kc_refresh_token' in content:
    print('ALREADY INJECTED - skipping')
    sys.exit(0)

with open(REFRESH_PATH, 'r') as f:
    new_code = f.read()

marker = 'def backupManager(request, domain, subpath=None):'
if marker not in content:
    print('ERROR: backupManager marker not found')
    sys.exit(1)

content = content.replace(marker, new_code + '\n\n' + marker)

with open(VIEWS_PATH, 'w') as f:
    f.write(content)

print('OK: kc_refresh_token view injected before backupManager')
