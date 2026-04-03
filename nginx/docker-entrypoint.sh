#!/bin/bash
set -e

# Determine the location configuration based on IS_DEBUG environment variable
if [ "$IS_DEBUG" = "true" ] || [ "$IS_DEBUG" = "True" ] || [ "$IS_DEBUG" = "1" ]; then
    # Debug mode: Proxy to Vue3 dev servers
    
    # For gohcos.com (port 5174)
    export GOHCOS_LOCATION_CONFIG='proxy_pass https://host.docker.internal:5174;

            # Standard proxy headers
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            
            # Vite HMR (Hot Module Replacement) WebSocket support
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
            
            # Disable SSL verification for local dev server
            proxy_ssl_verify off;
            
            # Increase buffer sizes for large responses
            proxy_buffer_size 128k;
            proxy_buffers 4 256k;
            proxy_busy_buffers_size 256k;'
    

    export GOHCOS_LOCATION_CONFIG='proxy_pass https://host.docker.internal:3000;

            # Standard proxy headers
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            
            # Vite HMR (Hot Module Replacement) WebSocket support
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
            
            # Disable SSL verification for local dev server
            proxy_ssl_verify off;
            
            # Increase buffer sizes for large responses
            proxy_buffer_size 128k;
            proxy_buffers 4 256k;
            proxy_busy_buffers_size 256k;'    
    # For onedash.gohcos.com (port 5173)
    export ONEDASH_LOCATION_CONFIG='proxy_pass https://host.docker.internal:5173;

            # Standard proxy headers
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            
            # Vite HMR (Hot Module Replacement) WebSocket support
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
            
            # Disable SSL verification for local dev server
            proxy_ssl_verify off;
            
            # Increase buffer sizes for large responses
            proxy_buffer_size 128k;
            proxy_buffers 4 256k;
            proxy_busy_buffers_size 256k;'
else
    # Production mode: Serve static files from dist directories
    
    # For gohcos.com - serves from GOHCOSLIVE/dist
    export GOHCOS_LOCATION_CONFIG='root /var/www/GOHCOSLIVE/dist;
            try_files $uri $uri/ /index.html;
            
            # Cache settings for production
            expires 1y;
            add_header Cache-Control "public, immutable";'
    
    # For onedash.gohcos.com - serves from productionFrontend/dist
    export ONEDASH_LOCATION_CONFIG='root /var/www/productionFrontend/dist;
            try_files $uri $uri/ /index.html;
            
            # Cache settings for production
            expires 1y;
            add_header Cache-Control "public, immutable";'
fi

# If install.sh has pre-generated /etc/nginx/conf.d/default.conf (which is
# bind-mounted from ./nginx/conf.d on the host), use it as-is so that any
# dynamic changes made by NginxManager (running inside the backend container)
# survive nginx container restarts.
# Only fall back to template processing when no pre-generated file is present,
# e.g. on a first boot before install.sh has run.
if [ -f /etc/nginx/conf.d/default.conf ]; then
    echo "Using pre-generated nginx config from /etc/nginx/conf.d/default.conf"
else
    # Substitute environment variables in the template
    envsubst '${GOHCOS_LOCATION_CONFIG},${ONEDASH_LOCATION_CONFIG}' < /etc/nginx/templates/default.conf.template > /etc/nginx/conf.d/default.conf
fi

# Execute the original nginx command
exec nginx -g "daemon off;"
