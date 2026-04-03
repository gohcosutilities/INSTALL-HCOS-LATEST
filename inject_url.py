"""Inject kc-refresh-token URL into websiteFunctions/urls.py"""
import sys

URLS_PATH = '/usr/local/CyberCP/websiteFunctions/urls.py'

with open(URLS_PATH, 'r') as f:
    content = f.read()

if 'kc_refresh_token' in content:
    print('ALREADY INJECTED - skipping')
    sys.exit(0)

# Insert the refresh URL right before the backup SPA route
marker = "    path('<domain>/backups', views.backupManager, name='backupManager'),"
new_line = "    path('<domain>/backups/api/refresh-token', views.kc_refresh_token, name='kc_refresh_token'),\n"

if marker not in content:
    print('ERROR: backupManager URL marker not found')
    sys.exit(1)

content = content.replace(marker, new_line + marker)

with open(URLS_PATH, 'w') as f:
    f.write(content)

print('OK: kc-refresh-token URL added')
