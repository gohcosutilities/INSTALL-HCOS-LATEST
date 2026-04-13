#!/bin/bash
# ═══════════════════════════════════════════════════════════════════
#  HCOS Deployment System — One-Line Installer
#  Architecture: Web UI (Docker) + Host-side deployment (bash)
#
#  Usage:
#    curl -fsSL https://raw.githubusercontent.com/gohcosutilities/install-hcos/main/install.sh | bash
#
#  Flow:
#    1. Install prerequisites (Docker, certbot, nginx, jq, git)
#    2. Build & start the ONETIME Setup UI container (port 9090)
#    3. User fills in config via web browser
#    4. User clicks Deploy → UI saves deploy-config.json
#    5. This script detects the config file and runs deployment
#    6. All phases run ON THE HOST with native tool access
#    7. Progress is written to deploy-status.json → UI shows it
# ═══════════════════════════════════════════════════════════════════

set -euo pipefail

# ── Colors ──
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# ── Globals ──
BASE_DIR="/opt/hcos_stack"
CONFIG_FILE="$BASE_DIR/deploy-config.json"
STATUS_FILE="$BASE_DIR/deploy-status.json"
SETUP_CONTAINER="hcos_setup_ui"
SETUP_IMAGE="hcos-setup"
SETUP_PORT=9090
REPO_URL="https://github.com/gohcosutilities/install-hcos.git"
REPO_DIR="/tmp/install-hcos"

declare -a LOG_ENTRIES=()

# ═══════════════════════════════════════════════
#  STATUS UPDATES (written to JSON for the UI)
# ═══════════════════════════════════════════════

update_status() {
    local phase="$1"
    local message="$2"
    local is_error="${3:-false}"
    local is_complete="${4:-false}"

    local ts
    ts=$(date -u +%Y-%m-%dT%H:%M:%S.%3NZ 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)
    LOG_ENTRIES+=("[$ts] $message")

    # Build log JSON array with jq
    local log_json
    log_json=$(printf '%s\n' "${LOG_ENTRIES[@]}" | jq -R -s 'split("\n") | map(select(length > 0))')

    cat > "$STATUS_FILE" <<STATUSEOF
{
  "phase": "$phase",
  "message": "$message",
  "log": $log_json,
  "complete": $is_complete,
  "error": $is_error
}
STATUSEOF

    # Also print to terminal
    if [[ "$is_error" == "true" ]]; then
        echo -e "${RED}[$phase] $message${NC}"
    else
        echo -e "${GREEN}[$phase] $message${NC}"
    fi
}

# ═══════════════════════════════════════════════
#  HELPER: Read config values with jq
# ═══════════════════════════════════════════════

cfg() {
    jq -r "$1 // empty" "$CONFIG_FILE" 2>/dev/null || echo ""
}

cfg_array() {
    jq -r "$1 // [] | .[]" "$CONFIG_FILE" 2>/dev/null || true
}

# ═══════════════════════════════════════════════
#  HELPER: Run command with logging
# ═══════════════════════════════════════════════

run_cmd() {
    local cmd="$1"
    local allow_failure="${2:-false}"
    local ts
    ts=$(date -u +%Y-%m-%dT%H:%M:%S.%3NZ 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)
    LOG_ENTRIES+=("[$ts] \$ $cmd")
    echo -e "${CYAN}\$ $cmd${NC}"

    local output=""
    if output=$(eval "$cmd" 2>&1); then
        if [[ -n "$output" ]]; then
            # Truncate long output
            local truncated="${output:0:2000}"
            LOG_ENTRIES+=("[$ts] $truncated")
        fi
        return 0
    else
        local exit_code=$?
        LOG_ENTRIES+=("[$ts] ERROR: $output")
        echo -e "${RED}ERROR: $output${NC}"
        if [[ "$allow_failure" == "true" ]]; then
            return 0
        fi
        return $exit_code
    fi
}

# ═══════════════════════════════════════════════
#  STEP 1: PREREQUISITES
# ═══════════════════════════════════════════════

install_prerequisites() {
    echo -e "${BOLD}${CYAN}═══ Step 1: Installing Prerequisites ═══${NC}"

    # Must be root
    if [[ "$EUID" -ne 0 ]]; then
        echo -e "${RED}This script must be run as root. Use: sudo bash install.sh${NC}"
        exit 1
    fi

    mkdir -p "$BASE_DIR"

    # Detect package manager
    if command -v apt-get &>/dev/null; then
        PKG_INSTALL="apt-get install -y -qq"
        apt-get update -qq
    elif command -v yum &>/dev/null; then
        PKG_INSTALL="yum install -y -q"
    elif command -v dnf &>/dev/null; then
        PKG_INSTALL="dnf install -y -q"
    else
        echo -e "${RED}Unsupported package manager. Install Docker, git, jq, curl, certbot, nginx manually.${NC}"
        exit 1
    fi

    # Core tools
    echo -e "${YELLOW}Installing core packages...${NC}"
    $PKG_INSTALL curl git jq net-tools lsof ca-certificates gnupg 2>/dev/null || true

    # Docker
    if ! command -v docker &>/dev/null || ! systemctl is-active --quiet docker; then
        echo -e "${YELLOW}Installing/Starting Docker...${NC}"
        if command -v dnf &>/dev/null; then
            dnf install -y dnf-plugins-core
            dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
            dnf install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin docker-buildx-plugin
            systemctl enable --now docker
        elif command -v yum &>/dev/null; then
            yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
            yum install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin docker-buildx-plugin
            systemctl enable --now docker
        else
            curl -fsSL https://get.docker.com | sh
        fi
        
        # Ensure docker daemon is actually running
        systemctl enable --now docker
        sleep 3
    fi
    echo -e "${GREEN}✓ Docker $(docker --version | awk '{print $3}')${NC}"

    # Docker Compose (v2 plugin or standalone)
    COMPOSE_CMD=""
    if docker compose version &>/dev/null 2>&1; then
        COMPOSE_CMD="docker compose"
    elif command -v docker-compose &>/dev/null; then
        COMPOSE_CMD="docker-compose"
    else
        echo -e "${YELLOW}Installing Docker Compose plugin...${NC}"
        mkdir -p /usr/local/lib/docker/cli-plugins
        local compose_url="https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)"
        curl -fsSL "$compose_url" -o /usr/local/lib/docker/cli-plugins/docker-compose
        chmod +x /usr/local/lib/docker/cli-plugins/docker-compose
        if docker compose version &>/dev/null 2>&1; then
            COMPOSE_CMD="docker compose"
        else
            # Fallback: standalone binary
            cp /usr/local/lib/docker/cli-plugins/docker-compose /usr/local/bin/docker-compose
            COMPOSE_CMD="docker-compose"
        fi
    fi
    echo -e "${GREEN}✓ Compose: $COMPOSE_CMD${NC}"

    # Certbot with Cloudflare DNS plugin
    if ! command -v certbot &>/dev/null; then
        echo -e "${YELLOW}Installing certbot...${NC}"
        $PKG_INSTALL certbot python3-certbot-dns-cloudflare 2>/dev/null || {
            # Fallback: pip install
            $PKG_INSTALL python3-pip 2>/dev/null || true
            pip3 install certbot certbot-dns-cloudflare 2>/dev/null || true
        }
    fi
    echo -e "${GREEN}✓ Certbot $(certbot --version 2>&1 | tail -1)${NC}"

    # Detect public IP and save for the UI
    echo -e "${YELLOW}Detecting public IP...${NC}"
    local ip=""
    ip=$(curl -s -4 --connect-timeout 5 ifconfig.me 2>/dev/null) || \
    ip=$(curl -s -4 --connect-timeout 5 icanhazip.com 2>/dev/null) || \
    ip=$(curl -s -4 --connect-timeout 5 ipinfo.io/ip 2>/dev/null) || \
    ip=""
    if [[ -n "$ip" ]]; then
        echo "$ip" > "$BASE_DIR/server-ip.txt"
        echo -e "${GREEN}✓ Public IP: $ip${NC}"
    fi

    echo -e "${GREEN}✓ All prerequisites installed${NC}"
    echo ""
}

# ═══════════════════════════════════════════════
#  STEP 2: BUILD & START THE SETUP UI
# ═══════════════════════════════════════════════

start_setup_ui() {
    echo -e "${BOLD}${CYAN}═══ Step 2: Starting Setup UI ═══${NC}"

    # Clone the install-hcos repo (contains ONETIME folder)
    if [[ -d "$REPO_DIR" ]]; then
        echo -e "${YELLOW}Updating existing repo...${NC}"
        cd "$REPO_DIR" && git pull --ff-only 2>/dev/null || true
    else
        echo -e "${YELLOW}Cloning install-hcos repo...${NC}"
        git clone "$REPO_URL" "$REPO_DIR"
    fi

    # Stop existing setup container if running
    docker rm -f "$SETUP_CONTAINER" 2>/dev/null || true

    # Build the setup UI image
    echo -e "${YELLOW}Building Setup UI image (this takes ~60s)...${NC}"
    docker build \
        --progress=plain \
        -t "$SETUP_IMAGE" \
        -f "$REPO_DIR/ONETIME/server/Dockerfile" \
        "$REPO_DIR/ONETIME"

    # Run it — mount BASE_DIR as /project for config/status file exchange
    echo -e "${YELLOW}Starting Setup UI container...${NC}"
    docker run -d \
        --name "$SETUP_CONTAINER" \
        -p "${SETUP_PORT}:9090" \
        -v "$BASE_DIR:/project" \
        -e "PROJECT_DIR=/project" \
        "$SETUP_IMAGE"

    # Wait for it to be healthy
    local attempts=0
    while [[ $attempts -lt 15 ]]; do
        if curl -sf "http://localhost:${SETUP_PORT}/api/health" &>/dev/null; then
            echo -e "${GREEN}✓ Setup UI is running${NC}"
            break
        fi
        sleep 2
        attempts=$((attempts + 1))
    done

    if [[ $attempts -ge 15 ]]; then
        echo -e "${RED}Setup UI failed to start. Checking logs:${NC}"
        docker logs "$SETUP_CONTAINER" 2>&1 | tail -20
        exit 1
    fi

    local server_ip
    server_ip=$(cat "$BASE_DIR/server-ip.txt" 2>/dev/null || echo "YOUR_SERVER_IP")

    echo ""
    echo -e "${BOLD}══════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}  ${GREEN}HCOS Setup UI is ready!${NC}"
    echo -e "${BOLD}  ${CYAN}Open: http://${server_ip}:${SETUP_PORT}${NC}"
    echo -e "${BOLD}══════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${YELLOW}Fill in all configuration fields, then click Deploy.${NC}"
    echo -e "${YELLOW}This script will automatically start the deployment.${NC}"
    echo ""
}

# ═══════════════════════════════════════════════
#  STEP 3: WAIT FOR CONFIG FROM UI
# ═══════════════════════════════════════════════

wait_for_config() {
    echo -e "${BOLD}${CYAN}═══ Step 3: Waiting for configuration... ═══${NC}"

    # Remove stale config file
    rm -f "$CONFIG_FILE"

    local dots=""
    while true; do
        if [[ -f "$CONFIG_FILE" ]]; then
            # Validate it's valid JSON with required fields
            if jq -e '.deployment.githubToken' "$CONFIG_FILE" &>/dev/null; then
                echo ""
                echo -e "${GREEN}✓ Configuration received from web UI!${NC}"
                break
            fi
        fi
        dots="${dots}."
        if [[ ${#dots} -gt 30 ]]; then dots="."; fi
        printf "\r${YELLOW}Waiting for configuration from web UI${dots}   ${NC}"
        sleep 2
    done
    echo ""
}

# ═══════════════════════════════════════════════
#  DEPLOYMENT PHASES
# ═══════════════════════════════════════════════

phase_write_env() {
    update_status "writing_env" "Phase 1: Writing .env file..."

    local env_file="$BASE_DIR/.env"
    > "$env_file"  # truncate

    # Helper: write key=value if value is non-empty
    add_env() {
        local key="$1"
        local json_path="$2"
        local val
        val=$(cfg "$json_path")
        if [[ -n "$val" && "$val" != "null" ]]; then
            echo "${key}=${val}" >> "$env_file"
        fi
    }

    # Helper: write key=comma-separated-array
    add_env_array() {
        local key="$1"
        local json_path="$2"
        local val
        val=$(jq -r "($json_path // []) | join(\",\")" "$CONFIG_FILE" 2>/dev/null || echo "")
        if [[ -n "$val" ]]; then
            echo "${key}=${val}" >> "$env_file"
        fi
    }

    # Core
    add_env "DJANGO_SECRET_KEY" ".core.secretKey"
    add_env "DEBUG" ".core.debug"
    add_env "SITE" ".core.siteUrl"
    add_env "SITE_DOMAIN" ".core.siteDomain"
    add_env "APP_NAME" ".core.appName"
    add_env "SYSTEM_PIN" ".core.systemPin"
    add_env "SYSTEM_PIN_CODE_LENGTH" ".core.systemPinLength"
    add_env "DISABLE_DNS_VERIFICATION" ".core.disableDnsVerification"
    add_env "FRONTEND_URL" ".core.frontendUrl"

    # Database
    add_env "POSTGRES_DB" ".database.name"
    add_env "BACKEND_DB" ".database.name"
    add_env "POSTGRES_USER" ".database.user"
    add_env "BACKEND_USER" ".database.user"
    add_env "POSTGRES_PASSWORD" ".database.password"
    add_env "BACKEND_PASSWORD" ".database.password"
    add_env "POSTGRES_HOST" ".database.host"
    add_env "POSTGRES_PORT" ".database.port"

    # Keycloak
    add_env "KEYCLOAK_SERVER_URL" ".keycloak.serverUrl"
    add_env "KEYCLOAK_PUBLIC_URL" ".keycloak.publicUrl"
    add_env "KEYCLOAK_REALM_NAME" ".keycloak.realmName"
    add_env "KEYCLOAK_CLIENT_ID" ".keycloak.clientId"
    add_env "KEYCLOAK_CLIENT_SECRET" ".keycloak.clientSecret"
    add_env "KEYCLOAK_REGISTRATION_CLIENT_ID" ".keycloak.registrationClientId"
    add_env "KEYCLOAK_REGISTRATION_CLIENT_SECRET" ".keycloak.registrationClientSecret"
    add_env "KEYCLOAK_ADMIN_USERNAME" ".keycloak.adminUsername"
    add_env "KEYCLOAK_ADMIN_PASSWORD" ".keycloak.adminPassword"
    add_env "KEYCLOAK_ADMIN_CLIENT_ID" ".keycloak.adminClientId"
    add_env "KEYCLOAK_FRONTEND_CLIENT_ID" ".keycloak.frontendClientId"
    add_env "AUTH_FRONTEND_CLIENT_ID" ".keycloak.authFrontendClient"
    add_env "AUTHENTICATION_FRONTEND_CLIENT_ID" ".keycloak.authFrontendClient"
    add_env "JWT_CLOCK_SKEW_LEEWAY" ".keycloak.jwtLeeway"
    add_env "KEYCLOAK_AUTO_SYNC_PERMISSIONS" ".keycloak.autoSyncPermissions"
    add_env "KEYCLOAK_ENABLED" ".keycloak.enabled"
    add_env "SSO_CLIENT_ID" ".keycloak.ssoClientId"
    add_env "SSO_CLIENT_SECRET" ".keycloak.ssoClientSecret"
    add_env "SSO_PROVIDER_DISCOVERY_URI" ".keycloak.ssoDiscoveryUri"

    # Keycloak — settings consumed by deploy_utils.py when provisioning
    # CyberPanel servers.  Without these the remote .env gets wrong defaults.
    add_env "KEYCLOAK_VERIFY_SSL" ".keycloak.verifySSL"
    add_env_array "KEYCLOAK_ACCEPTED_AUDIENCES" ".keycloak.acceptedAudiences"
    add_env "KEYCLOAK_PUBLIC_KEY" ".keycloak.publicKey"
    add_env "AUTH_BACKEND" ".keycloak.authBackend"

    # Fallback: ensure KEYCLOAK_VERIFY_SSL is always present (CyberPanel
    # servers need SSL verification disabled when calling back to Keycloak
    # over the internet with Let's Encrypt certs).
    if ! grep -q '^KEYCLOAK_VERIFY_SSL=' "$env_file" 2>/dev/null; then
        echo "KEYCLOAK_VERIFY_SSL=false" >> "$env_file"
    fi

    # Email
    add_env "EMAIL_BACKEND" ".email.backend"
    add_env "EMAIL_HOST" ".email.host"
    add_env "EMAIL_PORT" ".email.port"
    add_env "EMAIL_USE_TLS" ".email.useTls"
    add_env "EMAIL_USE_SSL" ".email.useSsl"
    add_env "EMAIL_HOST_USER" ".email.username"
    add_env "EMAIL_HOST_PASSWORD" ".email.password"
    add_env "DEFAULT_FROM_EMAIL" ".email.fromEmail"

    # Redis
    add_env "REDIS_HOST" ".redis.host"
    add_env "REDIS_PORT" ".redis.port"
    add_env "CHANNELS_REDIS_HOST" ".redis.host"
    add_env "CHANNELS_REDIS_PORT" ".redis.port"

    # Celery
    add_env "CELERY_BROKER_URL" ".celery.brokerUrl"
    add_env "CELERY_RESULT_BACKEND" ".celery.resultBackend"

    # Stripe
    add_env "STRIPE_LIVE_MODE" ".stripe.liveMode"
    add_env "STRIPE_TEST_PUBLIC_KEY" ".stripe.testPublicKey"
    add_env "STRIPE_TEST_SECRET_KEY" ".stripe.testSecretKey"
    add_env "STRIPE_LIVE_PUBLIC_KEY" ".stripe.livePublicKey"
    add_env "STRIPE_LIVE_SECRET_KEY" ".stripe.liveSecretKey"
    add_env "STRIPE_CONNECT_TEST_CLIENT_ID" ".stripe.connectTestClientId"
    add_env "STRIPE_CONNECT_LIVE_CLIENT_ID" ".stripe.connectLiveClientId"
    add_env "SYSTEM_STRIPE_ACCOUNT_ID" ".stripe.systemAccountId"
    add_env "DJSTRIPE_WEBHOOK_SECRET" ".stripe.webhookSecret"
    add_env "STRIPE_APPLICATION_FEE_PERCENT" ".stripe.applicationFee"

    # PayPal
    add_env "PAYPAL_MODE" ".paypal.mode"
    add_env "PAYPAL_TEST_CLIENT_ID" ".paypal.testClientId"
    add_env "PAYPAL_TEST_SECRET" ".paypal.testSecret"
    add_env "PAYPAL_LIVE_CLIENT_ID" ".paypal.liveClientId"
    add_env "PAYPAL_LIVE_SECRET" ".paypal.liveSecret"
    add_env "PAYPAL_WEBHOOK_ID" ".paypal.webhookId"

    # Oscar / E-commerce
    add_env "OSCAR_SHOP_NAME" ".oscar.shopName"
    add_env "OSCAR_DEFAULT_CURRENCY" ".oscar.defaultCurrency"
    add_env "OSCAR_SYSTEM_CURRENCY" ".oscar.systemCurrency"
    add_env "SHOP_TAX_RATE" ".oscar.taxRate"
    add_env "TRIAL_PERIOD_DAYS" ".oscar.trialDays"
    add_env "DEFAULT_REGISTRAR" ".oscar.defaultRegistrar"
    add_env "ORDER_PAID_STATUS" ".oscar.paidOrderStatus"

    # Security / CORS
    add_env_array "ALLOWED_DOMAINS" ".security.allowedDomains"
    add_env_array "ALLOWED_HOSTS"   ".security.allowedHosts"
    add_env "SESSION_COOKIE_AGE"    ".security.sessionCookieAge"

    # ── Build CORS_ALLOWED_ORIGINS comprehensively ────────────────────────────
    # Start with any explicitly configured origins from the deploy config, then
    # union with ALL api, frontend, homepage and root domains so that every
    # origin is always allowed — even if the operator forgot to add it to
    # .security.corsOrigins.
    local _cors_base
    _cors_base=$(jq -r '(.security.corsOrigins // []) | .[]' "$CONFIG_FILE" 2>/dev/null)

    declare -A _cors_seen=()
    local _cors_list=""

    _cors_add() {
        local _origin="$1"
        [[ -z "$_origin" || "${_cors_seen[$_origin]+_}" ]] && return
        _cors_seen["$_origin"]=1
        _cors_list+="${_cors_list:+,}${_origin}"
    }

    # Explicit origins from config
    while IFS= read -r o; do [[ -n "$o" ]] && _cors_add "$o"; done <<< "$_cors_base"

    # API domains (backend endpoints)
    while IFS= read -r d; do [[ -n "$d" ]] && _cors_add "https://${d}"; done \
        < <(jq -r '.deployment.apiDomains // [] | .[]' "$CONFIG_FILE" 2>/dev/null)

    # Frontend dashboard domains
    while IFS= read -r d; do [[ -n "$d" ]] && _cors_add "https://${d}"; done \
        < <(jq -r '.deployment.frontendDomains // [] | .[]' "$CONFIG_FILE" 2>/dev/null)

    # Homepage domains (public marketing site — origin of unauthenticated POSTs)
    while IFS= read -r d; do [[ -n "$d" ]] && _cors_add "https://${d}"; done \
        < <(jq -r '.deployment.homepageDomains // [] | .[]' "$CONFIG_FILE" 2>/dev/null)
        
    # GohcosWeb domains 
    while IFS= read -r d; do [[ -n "$d" ]] && _cors_add "https://${d}"; done \
        < <(jq -r '.deployment.gohcosDomains // [] | .[]' "$CONFIG_FILE" 2>/dev/null)

    # Root / apex domains
    while IFS= read -r d; do [[ -n "$d" ]] && _cors_add "https://${d}"; done \
        < <(jq -r '.deployment.rootDomains // [] | .[].domain' "$CONFIG_FILE" 2>/dev/null)

    [[ -n "$_cors_list" ]] && echo "CORS_ALLOWED_ORIGINS=${_cors_list}" >> "$env_file"
    unset _cors_seen _cors_list _cors_base
    # ─────────────────────────────────────────────────────────────────────────

    # Logging
    add_env "LOGSTASH_HOST" ".logging.logstashHost"
    add_env "LOGSTASH_PORT" ".logging.logstashPort"
    add_env "LOGSTASH_ENABLED" ".logging.logstashEnabled"

    # Helpdesk
    add_env "ESCALATION_ENABLED" ".helpdesk.escalationEnabled"
    add_env "ESCALATION_DAYS" ".helpdesk.escalationDays"
    add_env "ESCALATION_MINUTES" ".helpdesk.escalationMinutes"
    add_env "ON_HOLD_ESCALATION_MINUTES" ".helpdesk.onHoldEscalationMinutes"
    add_env "AUTO_CLOSE_ENABLED" ".helpdesk.autoCloseEnabled"
    add_env "AUTO_CLOSE_DAYS" ".helpdesk.autoCloseDays"
    add_env "INCLUDE_INITIAL_FOLLOWUP_TICKET_STAFF" ".helpdesk.includeStaffInitialFollowup"

    # Invoicing
    add_env "INVOICE_PREFIX" ".invoicing.prefix"
    add_env "INVOICE_NUMBER_START" ".invoicing.numberStart"
    add_env "INVOICE_DEFAULT_DUE_DAYS" ".invoicing.defaultDueDays"
    add_env "INVOICE_DUE_DAYS" ".invoicing.dueDays"
    add_env "MINIMUM_HOURLY_BALANCE" ".invoicing.minimumHourlyBalance"

    # Business
    add_env "BUSINESS_COUNTRY_CODE" ".business.countryCode"
    add_env "BUSINESS_PROVINCE_STATE" ".business.provinceState"
    add_env "BUSINESS_VAT_NUMBER" ".business.vatNumber"

    # Policies
    add_env "SHOULD_SUSPEND_SERVICES_FOR_NON_PAYMENT" ".policies.suspendForNonPayment"
    add_env "PAST_DUE_DAYS_BEFORE_SUSPENSION" ".policies.daysBeforeSuspension"
    add_env "USERS_CAN_EDIT_ADDRESS" ".policies.usersCanEditAddress"
    add_env "FRAUD_DETECTION_ENABLED" ".policies.fraudDetectionEnabled"

    # AWS
    add_env "AWS_ACCESS_KEY_ID" ".aws.accessKeyId"
    add_env "AWS_SECRET_ACCESS_KEY" ".aws.secretAccessKey"
    add_env "AWS_DEFAULT_REGION" ".aws.region"

    # Cloudflare
    add_env "CLOUDFLARE_FULL_API_KEY" ".cloudflare.fullApiKey"
    add_env "CLOUDFLARE_API_KEY" ".cloudflare.apiKey"
    add_env "CLOUDFLARE_API_TOKEN" ".cloudflare.apiToken"
    add_env "CLOUDFLARE_API_EMAIL" ".cloudflare.apiEmail"
    add_env "CLOUDFLARE_ACCOUNT_ID" ".cloudflare.accountId"
    add_env "CLOUDFLARE_ZONE_ID" ".cloudflare.zoneId"
    add_env "CLOUDFLARE_TUNNEL_ID" ".cloudflare.tunnelId"
    add_env "CLOUDFLARE_TUNNEL_SECRET" ".cloudflare.tunnelSecret"
    add_env "CLOUDFLARE_CONNECTOR_ID" ".cloudflare.connectorId"
    add_env "SUBDOMAIN_SERVICE_URL" ".cloudflare.subdomainServiceUrl"
    add_env "SYSTEM_SUBDOMAIN_BASE" ".cloudflare.subdomainBase"

    # Nginx
    add_env "NGINX_TEMPLATE_PATH" ".nginx.templatePath"
    add_env "NGINX_CONTAINER_NAME" ".nginx.containerName"
    add_env "NGINX_SSL_CERT_PATH" ".nginx.sslCertPath"
    add_env "NGINX_SSL_KEY_PATH" ".nginx.sslKeyPath"
    # NGINX_CONFIG_PATH — path inside the backend container that maps to
    # the same bind-mount used by nginx_main (/etc/nginx/conf.d).
    # This lets NginxManager read/write the live nginx config without
    # needing to exec into the nginx container.
    echo "NGINX_CONFIG_PATH=/etc/nginx-conf/default.conf" >> "$env_file"

    # SSL
    add_env "WILDCARD_SSL_ENABLED" ".ssl.wildcardEnabled"
    add_env "CERTBOT_LETSENCRYPT_EMAIL" ".ssl.letsencryptEmail"

    # System
    add_env "SYSTEM_MAIN_HOSTNAME" ".system.mainHostname"
    add_env "SYSTEM_ALTERNATE_HOSTNAME" ".system.alternateHostname"
    add_env "SYSTEM_MAIN_IP_ADDRESS" ".system.mainIpAddress"
    add_env_array "SYSTEM_ALL_DOMAINS" ".system.allDomains"
    add_env "USE_SYSTEM_IP_FOR_TENANT_DNS" ".system.useSystemIpForTenantDns"
    add_env "DEVELOPMENT_IP_ADDRESS" ".system.developmentIp"
    add_env "PRODUCTION_IP_ADDRESS" ".system.productionIp"
    add_env "PRODUCTION_HOSTNAME" ".system.productionHostname"
    add_env "SYSTEM_MAIN_IP_ADDRESS" ".deployment.serverIp"

    # Chat
    add_env "SHOW_CHAT_SEEN_STATUS" ".chat.showSeenStatus"
    add_env "CHAT_MESSAGE_MAX_LENGTH" ".chat.maxMessageLength"

    # Django settings module
    echo "DJANGO_SETTINGS_MODULE=hcos.settings" >> "$env_file"

    update_status "writing_env" "Phase 1: .env written ($( wc -l < "$env_file" ) lines)"
}

phase_cloudflare_creds() {
    update_status "cloudflare_creds" "Phase 2: Configuring Cloudflare credentials..."

    local api_token
    api_token=$(cfg ".cloudflare.apiToken")

    if [[ -z "$api_token" ]]; then
        api_token=$(cfg ".deployment.cloudflareApiToken")
    fi

    if [[ -n "$api_token" ]]; then
        mkdir -p /opt
        cat > /opt/cf_creds.ini <<CFEOF
dns_cloudflare_api_token = $api_token
CFEOF
        chmod 400 /opt/cf_creds.ini
        update_status "cloudflare_creds" "Phase 2: Cloudflare credentials configured"
    else
        update_status "cloudflare_creds" "Phase 2: No Cloudflare API token — skipping"
    fi
}

phase_clone_repos() {
    update_status "cloning" "Phase 3: Cloning repositories..."

    local github_user github_token
    github_user=$(cfg ".deployment.githubUser")
    github_token=$(cfg ".deployment.githubToken")

    # URL-encode user and token to handle special chars (@ in email, etc.)
    local safe_user safe_token
    safe_user=$(python3 -c "import urllib.parse; print(urllib.parse.quote('${github_user}', safe=''))" 2>/dev/null || echo "$github_user")
    safe_token=$(python3 -c "import urllib.parse; print(urllib.parse.quote('${github_token}', safe=''))" 2>/dev/null || echo "$github_token")

    # Read repositories array
    local repo_count
    repo_count=$(jq '.deployment.repositories | length' "$CONFIG_FILE")

    for ((i=0; i<repo_count; i++)); do
        local url folder repo_type
        url=$(jq -r ".deployment.repositories[$i].url" "$CONFIG_FILE")
        folder=$(jq -r ".deployment.repositories[$i].folder" "$CONFIG_FILE")
        repo_type=$(jq -r ".deployment.repositories[$i].type" "$CONFIG_FILE")
        local full_path="$BASE_DIR/$folder"

        # Remove existing
        if [[ -d "$full_path" ]]; then
            update_status "cloning" "Removing existing $folder..."
            rm -rf "$full_path"
        fi

        # Build authenticated URL
        local auth_url="${url/https:\/\//https://${safe_user}:${safe_token}@}"
        update_status "cloning" "Cloning $url → $folder"
        run_cmd "git clone '$auth_url' '$full_path'" "false" || {
            update_status "cloning" "FATAL: Failed to clone $folder" "true"
            return 1
        }

        # ── Flatten nested repo structure ──
        # Some repos (e.g. HCOS-V8.0) contain the project in a subfolder
        # (e.g. HCOS-V8.0/BACKEND-API-HCOM/Dockerfile). Detect this and
        # move the inner folder contents up to the clone root.
        # For backend: manage.py is the definitive Django marker. A repo
        # root may have a stub Dockerfile (2 bytes) while the real one
        # lives in a subfolder.
        if [[ "$repo_type" == "backend" && ! -f "$full_path/manage.py" ]]; then
            # Look for a subfolder that contains manage.py (Django project root)
            local inner=""
            for candidate in "$full_path"/*/; do
                if [[ -f "${candidate}manage.py" ]]; then
                    inner="$candidate"
                    break
                fi
            done
            if [[ -n "$inner" ]]; then
                update_status "cloning" "  Flattening nested backend: $(basename "$inner") → $folder"
                local tmp_dir="${full_path}.__tmp_flatten"
                mv "$inner" "$tmp_dir"
                rm -rf "$full_path"
                mv "$tmp_dir" "$full_path"
            fi
        elif [[ "$repo_type" == "frontend" && ! -f "$full_path/package.json" ]]; then
            # Look for a subfolder that contains package.json
            local inner=""
            for candidate in "$full_path"/*/; do
                if [[ -f "${candidate}package.json" ]]; then
                    inner="$candidate"
                    break
                fi
            done
            if [[ -n "$inner" ]]; then
                update_status "cloning" "  Flattening nested frontend: $(basename "$inner") → $folder"
                local tmp_dir="${full_path}.__tmp_flatten"
                mv "$inner" "$tmp_dir"
                rm -rf "$full_path"
                mv "$tmp_dir" "$full_path"
            fi
        elif [[ "$repo_type" == "homepage" && ! -f "$full_path/package.json" && ! -f "$full_path/index.html" ]]; then
            local inner=""
            for candidate in "$full_path"/*/; do
                if [[ -f "${candidate}package.json" || -f "${candidate}index.html" ]]; then
                    inner="$candidate"
                    break
                fi
            done
            if [[ -n "$inner" ]]; then
                update_status "cloning" "  Flattening nested homepage: $(basename "$inner") → $folder"
                local tmp_dir="${full_path}.__tmp_flatten"
                mv "$inner" "$tmp_dir"
                rm -rf "$full_path"
                mv "$tmp_dir" "$full_path"
            fi
        elif [[ "$repo_type" == "gohcos" && ! -f "$full_path/package.json" && ! -f "$full_path/index.html" ]]; then
            local inner=""
            for candidate in "$full_path"/*/; do
                if [[ -f "${candidate}package.json" || -f "${candidate}index.html" ]]; then
                    inner="$candidate"
                    break
                fi
            done
            if [[ -n "$inner" ]]; then
                update_status "cloning" "  Flattening nested gohcosweb: $(basename "$inner") → $folder"
                local tmp_dir="${full_path}.__tmp_flatten"
                mv "$inner" "$tmp_dir"
                rm -rf "$full_path"
                mv "$tmp_dir" "$full_path"
            fi
        fi
    done

    # Copy .env to backend folder
    local backend_folder
    backend_folder=$(jq -r '.deployment.repositories[] | select(.type=="backend") | .folder' "$CONFIG_FILE")
    if [[ -n "$backend_folder" && -d "$BASE_DIR/$backend_folder" ]]; then
        cp "$BASE_DIR/.env" "$BASE_DIR/$backend_folder/.env"
        update_status "cloning" "Phase 3: Repositories cloned, .env copied to $backend_folder"
    else
        update_status "cloning" "Phase 3: Repositories cloned"
    fi

    # ── Copy auxiliary files from install-hcos repo to stack dir ──
    # keycloak/ (Dockerfile + providers/ + themes/)
    if [[ -d "$REPO_DIR/keycloak" ]]; then
        rm -rf "$BASE_DIR/keycloak"
        cp -r "$REPO_DIR/keycloak" "$BASE_DIR/keycloak"
        update_status "cloning" "  Copied keycloak/ build context"
    fi
    # init-multiple-databases.sh (creates keycloakdb in postgres)
    if [[ -f "$REPO_DIR/init-multiple-databases.sh" ]]; then
        cp "$REPO_DIR/init-multiple-databases.sh" "$BASE_DIR/init-multiple-databases.sh"
        chmod +x "$BASE_DIR/init-multiple-databases.sh"
        update_status "cloning" "  Copied init-multiple-databases.sh"
    fi
    # cyberpanel-entrypoint.sh
    if [[ -f "$REPO_DIR/cyberpanel-entrypoint.sh" ]]; then
        cp "$REPO_DIR/cyberpanel-entrypoint.sh" "$BASE_DIR/cyberpanel-entrypoint.sh"
        chmod +x "$BASE_DIR/cyberpanel-entrypoint.sh"
        update_status "cloning" "  Copied cyberpanel-entrypoint.sh"
    fi
    # nginx config scaffolding (docker-entrypoint.sh, front.conf)
    mkdir -p "$BASE_DIR/nginx/templates"
    if [[ -d "$REPO_DIR/nginx" ]]; then
        cp -r "$REPO_DIR/nginx/"* "$BASE_DIR/nginx/" 2>/dev/null || true
        [[ -f "$BASE_DIR/nginx/docker-entrypoint.sh" ]] && chmod +x "$BASE_DIR/nginx/docker-entrypoint.sh"
        update_status "cloning" "  Copied nginx/ config scaffolding"
    fi
}

phase_ssl() {
    update_status "ssl" "Phase 4: Generating SSL certificates..."

    local email
    email=$(cfg ".ssl.letsencryptEmail")
    if [[ -z "$email" ]]; then
        email=$(cfg ".deployment.letsencryptEmail")
    fi

    local root_count
    root_count=$(jq '.deployment.rootDomains // [] | length' "$CONFIG_FILE" 2>/dev/null || echo "0")

    if [[ "$root_count" -eq 0 ]]; then
        update_status "ssl" "Phase 4: No root domains configured — skipping SSL"
        return 0
    fi

    for ((i=0; i<root_count; i++)); do
        local domain cf_token
        domain=$(jq -r ".deployment.rootDomains[$i].domain" "$CONFIG_FILE")
        cf_token=$(jq -r ".deployment.rootDomains[$i].cloudflareToken" "$CONFIG_FILE")

        if [[ -z "$domain" || "$domain" == "null" ]]; then continue; fi

        local cert_dir="/etc/letsencrypt/live/$domain"
        
        if [[ -n "$cf_token" && "$cf_token" != "null" && -n "$email" && "$email" != "null" ]]; then
            # Create temporary creds file for this domain
            local creds_file="/opt/cf_creds_${domain}.ini"
            echo "dns_cloudflare_api_token = $cf_token" > "$creds_file"
            chmod 600 "$creds_file"

            update_status "ssl" "Generating wildcard cert for $domain and *.$domain ..."
            if certbot certonly \
                --non-interactive \
                --agree-tos \
                --email "$email" \
                --dns-cloudflare \
                --dns-cloudflare-credentials "$creds_file" \
                --dns-cloudflare-propagation-seconds 60 \
                -d "$domain" \
                -d "*.$domain" 2>&1; then
                update_status "ssl" "SSL cert generated for $domain"
            else
                update_status "ssl" "WARNING: SSL cert generation failed for $domain. Generating self-signed fallback..."
                mkdir -p "$cert_dir"
                openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
                    -keyout "$cert_dir/privkey.pem" \
                    -out "$cert_dir/fullchain.pem" \
                    -subj "/CN=${domain}/O=HCOS/C=US" 2>/dev/null
            fi
            rm -f "$creds_file"
        else
            update_status "ssl" "Missing Cloudflare token or email for $domain. Generating self-signed fallback..."
            mkdir -p "$cert_dir"
            openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
                -keyout "$cert_dir/privkey.pem" \
                -out "$cert_dir/fullchain.pem" \
                -subj "/CN=${domain}/O=HCOS/C=US" 2>/dev/null
        fi
    done
}

phase_ensure_ssl() {
    # Ensure /etc/letsencrypt exists for docker mounts
    mkdir -p /etc/letsencrypt

    # Helper to find root domain for a given domain
    get_root_domain_for() {
        local target_domain="$1"
        local root_count
        root_count=$(jq '.deployment.rootDomains // [] | length' "$CONFIG_FILE" 2>/dev/null || echo "0")
        for ((i=0; i<root_count; i++)); do
            local rd
            rd=$(jq -r ".deployment.rootDomains[$i].domain" "$CONFIG_FILE")
            if [[ "$target_domain" == *"$rd" ]]; then
                echo "$rd"
                return
            fi
        done
        # Fallback
        echo "$target_domain" | rev | cut -d. -f1,2 | rev
    }

    # Collect all domains
    local all_domains=()
    local api_count=$(jq '.deployment.apiDomains // [] | length' "$CONFIG_FILE" 2>/dev/null || echo "0")
    for ((i=0; i<api_count; i++)); do all_domains+=("$(jq -r ".deployment.apiDomains[$i]" "$CONFIG_FILE")"); done
    
    local fe_count=$(jq '.deployment.frontendDomains // [] | length' "$CONFIG_FILE" 2>/dev/null || echo "0")
    for ((i=0; i<fe_count; i++)); do all_domains+=("$(jq -r ".deployment.frontendDomains[$i]" "$CONFIG_FILE")"); done
    
    local kc_count=$(jq '.deployment.keycloakDomains // [] | length' "$CONFIG_FILE" 2>/dev/null || echo "0")
    for ((i=0; i<kc_count; i++)); do all_domains+=("$(jq -r ".deployment.keycloakDomains[$i]" "$CONFIG_FILE")"); done
    
    local hp_count=$(jq '.deployment.homepageDomains // [] | length' "$CONFIG_FILE" 2>/dev/null || echo "0")
    for ((i=0; i<hp_count; i++)); do all_domains+=("$(jq -r ".deployment.homepageDomains[$i]" "$CONFIG_FILE")"); done
    
    local gohcos_count=$(jq '.deployment.gohcosDomains // [] | length' "$CONFIG_FILE" 2>/dev/null || echo "0")
    for ((i=0; i<gohcos_count; i++)); do all_domains+=("$(jq -r ".deployment.gohcosDomains[$i]" "$CONFIG_FILE")"); done

    local root_count=$(jq '.deployment.rootDomains // [] | length' "$CONFIG_FILE" 2>/dev/null || echo "0")
    for ((i=0; i<root_count; i++)); do all_domains+=("$(jq -r ".deployment.rootDomains[$i].domain" "$CONFIG_FILE")"); done

    local unique_domains=($(echo "${all_domains[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' '))

    for domain in "${unique_domains[@]}"; do
        if [[ -z "$domain" || "$domain" == "null" ]]; then continue; fi
        local rd
        rd=$(get_root_domain_for "$domain")
        local cert_dir="/etc/letsencrypt/live/$rd"
        
        if [[ ! -f "$cert_dir/fullchain.pem" || ! -f "$cert_dir/privkey.pem" ]]; then
            update_status "ssl" "Missing cert for $rd. Generating self-signed fallback..."
            mkdir -p "$cert_dir"
            openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
                -keyout "$cert_dir/privkey.pem" \
                -out "$cert_dir/fullchain.pem" \
                -subj "/CN=${rd}/O=HCOS/C=US" 2>/dev/null
        fi
    done
}

phase_dns() {
    update_status "dns" "Phase 5: Creating DNS records..."

    local server_ip
    server_ip=$(cfg ".deployment.serverIp")

    if [[ -z "$server_ip" ]]; then
        update_status "dns" "Phase 5: Missing server IP — skipping DNS"
        return 0
    fi

    # Helper: get zone ID for a domain
    get_zone_id() {
        local domain="$1"
        local cf_token="$2"
        local root_domain
        root_domain=$(echo "$domain" | rev | cut -d. -f1,2 | rev)
        local result
        result=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=$root_domain" \
            -H "Authorization: Bearer $cf_token" \
            -H "Content-Type: application/json")
        echo "$result" | jq -r '.result[0].id // empty'
    }

    # Helper: create A record
    create_a_record() {
        local zone_id="$1" name="$2" cf_token="$3"
        curl -s -X POST "https://api.cloudflare.com/client/v4/zones/$zone_id/dns_records" \
            -H "Authorization: Bearer $cf_token" \
            -H "Content-Type: application/json" \
            --data "{\"type\":\"A\",\"name\":\"$name\",\"content\":\"$server_ip\",\"ttl\":120,\"proxied\":false}" >/dev/null 2>&1 || true
        update_status "dns" "  A record: $name → $server_ip"
    }

    # Helper: get root domain token
    get_cf_token_for_domain() {
        local target_domain="$1"
        local root_count
        root_count=$(jq '.deployment.rootDomains // [] | length' "$CONFIG_FILE" 2>/dev/null || echo "0")
        for ((i=0; i<root_count; i++)); do
            local rd token
            rd=$(jq -r ".deployment.rootDomains[$i].domain" "$CONFIG_FILE")
            token=$(jq -r ".deployment.rootDomains[$i].cloudflareToken" "$CONFIG_FILE")
            if [[ "$target_domain" == *"$rd" ]]; then
                echo "$token"
                return
            fi
        done
        echo ""
    }

    # Process all domains
    local all_domains=()
    
    # Collect all domains from the new structure
    local api_count=$(jq '.deployment.apiDomains // [] | length' "$CONFIG_FILE" 2>/dev/null || echo "0")
    for ((i=0; i<api_count; i++)); do all_domains+=("$(jq -r ".deployment.apiDomains[$i]" "$CONFIG_FILE")"); done
    
    local fe_count=$(jq '.deployment.frontendDomains // [] | length' "$CONFIG_FILE" 2>/dev/null || echo "0")
    for ((i=0; i<fe_count; i++)); do all_domains+=("$(jq -r ".deployment.frontendDomains[$i]" "$CONFIG_FILE")"); done
    
    local kc_count=$(jq '.deployment.keycloakDomains // [] | length' "$CONFIG_FILE" 2>/dev/null || echo "0")
    for ((i=0; i<kc_count; i++)); do all_domains+=("$(jq -r ".deployment.keycloakDomains[$i]" "$CONFIG_FILE")"); done
    
    local hp_count=$(jq '.deployment.homepageDomains // [] | length' "$CONFIG_FILE" 2>/dev/null || echo "0")
    for ((i=0; i<hp_count; i++)); do all_domains+=("$(jq -r ".deployment.homepageDomains[$i]" "$CONFIG_FILE")"); done
    
    local gohcos_count=$(jq '.deployment.gohcosDomains // [] | length' "$CONFIG_FILE" 2>/dev/null || echo "0")
    for ((i=0; i<gohcos_count; i++)); do all_domains+=("$(jq -r ".deployment.gohcosDomains[$i]" "$CONFIG_FILE")"); done

    # Also add root domains themselves
    local root_count=$(jq '.deployment.rootDomains // [] | length' "$CONFIG_FILE" 2>/dev/null || echo "0")
    for ((i=0; i<root_count; i++)); do all_domains+=("$(jq -r ".deployment.rootDomains[$i].domain" "$CONFIG_FILE")"); done

    # Remove duplicates
    local unique_domains=($(echo "${all_domains[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' '))

    for domain in "${unique_domains[@]}"; do
        if [[ -z "$domain" || "$domain" == "null" ]]; then continue; fi
        
        local token
        token=$(get_cf_token_for_domain "$domain")
        
        if [[ -z "$token" ]]; then
            update_status "dns" "  WARNING: No Cloudflare token found for $domain"
            continue
        fi

        local zone_id
        zone_id=$(get_zone_id "$domain" "$token")
        if [[ -z "$zone_id" ]]; then
            update_status "dns" "  WARNING: Could not find zone for $domain"
            continue
        fi
        
        create_a_record "$zone_id" "$domain" "$token"
    done

    update_status "dns" "Phase 5: DNS records created"
}

phase_nginx_config() {
    update_status "nginx" "Phase 6: Generating Nginx config..."

    local nginx_dir="$BASE_DIR/nginx/templates"
    mkdir -p "$nginx_dir"

    local conf=""

    # Upstreams & cache
    conf+="upstream keycloak_backend {\n"
    conf+="    server keycloak:3001;\n"
    conf+="}\n\n"
    conf+="proxy_cache_path /tmp/nginx_proxy_cache levels=1:2 keys_zone=nginx_cache:10m max_size=1g\n"
    conf+="                 inactive=60m use_temp_path=off;\n\n"

    # ── CORS origin whitelist map ──────────────────────────────────────────────
    # Maps the incoming Origin header to itself when it is an allowed origin, or
    # to an empty string when it is not.  Django corsheaders handles the actual
    # CORS validation for non-OPTIONS responses; Nginx only uses this for the
    # OPTIONS preflight short-circuit in the API domain location blocks below.
    conf+="# CORS origin whitelist (generated from deployment config)\n"
    conf+="map \$http_origin \$cors_origin {\n"
    conf+="    default  \"\";\n"
    local _cors_root_d
    while IFS= read -r _cors_root_d; do
        [[ -z "$_cors_root_d" || "$_cors_root_d" == "null" ]] && continue
        local _escaped
        _escaped=$(echo "$_cors_root_d" | sed 's/\./\\\\./g')
        conf+="    \"~^https://([\\\\w-]+\\\\.)?${_escaped}\$\"  \$http_origin;\n"
    done < <(jq -r '.deployment.rootDomains // [] | .[].domain' "$CONFIG_FILE" 2>/dev/null)
    conf+="    \"~^https://localhost(:\\\\d+)?\$\"  \$http_origin;\n"
    conf+="    \"~^http://localhost(:\\\\d+)?\$\"   \$http_origin;\n"
    conf+="}\n\n"
    # ──────────────────────────────────────────────────────────────────────────

    # DNS resolver for Docker service discovery
    conf+="resolver 127.0.0.11 valid=30s ipv6=off;\n\n"

    # ── Platform / CyberPanel server block ──
    local primary_domain
    primary_domain=$(jq -r '.deployment.rootDomains[0].domain // "example.com"' "$CONFIG_FILE")
    local primary_api_domain
    primary_api_domain=$(jq -r '.deployment.apiDomains[0] // "api.example.com"' "$CONFIG_FILE")

    conf+="server {\n"
    conf+="    listen 8443 ssl;\n"
    conf+="    server_name platform.${primary_domain};\n"
    conf+="    ssl_certificate /etc/letsencrypt/fullchain.pem;\n"
    conf+="    ssl_certificate_key /etc/letsencrypt/privkey.pem;\n"
    conf+="    ssl_protocols TLSv1.2 TLSv1.3;\n"
    conf+="    ssl_ciphers HIGH:!aNULL:!MD5;\n\n"
    conf+="    location /api/admin/ {\n"
    conf+="        proxy_pass http://backend:5000;\n"
    conf+="        proxy_http_version 1.1;\n"
    conf+="        proxy_set_header Host ${primary_api_domain};\n"
    conf+="        proxy_set_header X-Real-IP \$remote_addr;\n"
    conf+="        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;\n"
    conf+="        proxy_set_header X-Forwarded-Proto \$scheme;\n"
    conf+="    }\n\n"
    conf+="    location / {\n"
    conf+="        proxy_pass https://cyberpanel_host:8090;\n"
    conf+="        proxy_ssl_verify off;\n"
    conf+="        proxy_ssl_server_name on;\n"
    conf+="        proxy_ssl_name platform.${primary_domain};\n"
    conf+="        proxy_set_header Host \$host;\n"
    conf+="        proxy_set_header X-Real-IP \$remote_addr;\n"
    conf+="        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;\n"
    conf+="        proxy_set_header X-Forwarded-Proto \$scheme;\n"
    conf+="        proxy_http_version 1.1;\n"
    conf+="        proxy_set_header Upgrade \$http_upgrade;\n"
    conf+="        proxy_set_header Connection \"upgrade\";\n"
    conf+="    }\n"
    conf+="}\n\n"

    # ── Keycloak Domains (enhanced with http2, session cache, buffer settings) ──
    local kc_domains=""
    local kc_count=$(jq '.deployment.keycloakDomains // [] | length' "$CONFIG_FILE" 2>/dev/null || echo "0")
    for ((i=0; i<kc_count; i++)); do
        local kc_domain
        kc_domain=$(jq -r ".deployment.keycloakDomains[$i]" "$CONFIG_FILE")
        if [[ -n "$kc_domain" && "$kc_domain" != "null" ]]; then
            kc_domains+="${kc_domains:+ }${kc_domain}"
        fi
    done
    if [[ -n "$kc_domains" ]]; then
        conf+="server {\n"
        conf+="    listen 8443 ssl;\n"
        conf+="    listen [::]:8443 ssl;\n"
        conf+="    http2 on;\n"
        conf+="    server_name ${kc_domains};\n"
        conf+="    ssl_certificate /etc/letsencrypt/fullchain.pem;\n"
        conf+="    ssl_certificate_key /etc/letsencrypt/privkey.pem;\n"
        conf+="    ssl_protocols TLSv1.2 TLSv1.3;\n"
        conf+="    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384;\n"
        conf+="    ssl_prefer_server_ciphers off;\n"
        conf+="    ssl_session_cache shared:SSL:10m;\n"
        conf+="    ssl_session_timeout 10m;\n"
        conf+="    proxy_read_timeout 86400;\n"
        conf+="    proxy_send_timeout 86400;\n\n"
        conf+="    location / {\n"
        conf+="        set \$keycloak_upstream http://keycloak:3001;\n"
        conf+="        proxy_pass \$keycloak_upstream;\n"
        conf+="        proxy_set_header Host \$host;\n"
        conf+="        proxy_set_header X-Real-IP \$remote_addr;\n"
        conf+="        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;\n"
        conf+="        proxy_set_header X-Forwarded-Proto \$scheme;\n"
        conf+="        proxy_set_header X-Forwarded-Host \$host;\n"
        conf+="        proxy_set_header X-Forwarded-Port \$server_port;\n"
        conf+="        proxy_set_header X-Forwarded-Server \$host;\n"
        conf+="        proxy_set_header Upgrade \$http_upgrade;\n"
        conf+="        proxy_set_header Connection \"upgrade\";\n"
        conf+="        proxy_buffer_size 128k;\n"
        conf+="        proxy_buffers 4 256k;\n"
        conf+="        proxy_busy_buffers_size 256k;\n"
        conf+="        proxy_connect_timeout 90s;\n"
        conf+="        proxy_send_timeout 90s;\n"
        conf+="        proxy_read_timeout 90s;\n"
        conf+="    }\n"
        conf+="}\n\n"
    fi

    # API Domains
    local api_count=$(jq '.deployment.apiDomains // [] | length' "$CONFIG_FILE" 2>/dev/null || echo "0")
    for ((i=0; i<api_count; i++)); do
        local api_domain
        api_domain=$(jq -r ".deployment.apiDomains[$i]" "$CONFIG_FILE")
        if [[ -z "$api_domain" || "$api_domain" == "null" ]]; then continue; fi

        conf+="server {\n"
        conf+="    listen 8443 ssl;\n"
        conf+="    server_name ${api_domain};\n"
        conf+="    ssl_certificate /etc/letsencrypt/fullchain.pem;\n"
        conf+="    ssl_certificate_key /etc/letsencrypt/privkey.pem;\n\n"
        # WebSocket location
        conf+="    location /ws/ {\n"
        conf+="        proxy_pass http://backend:5000;\n"
        conf+="        proxy_set_header Host \$host;\n"
        conf+="        proxy_set_header X-Real-IP \$remote_addr;\n"
        conf+="        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;\n"
        conf+="        proxy_set_header X-Forwarded-Proto https;\n"
        conf+="        proxy_set_header Origin \$http_origin;\n"
        conf+="        proxy_http_version 1.1;\n"
        conf+="        proxy_set_header Upgrade \$http_upgrade;\n"
        conf+="        proxy_set_header Connection \"upgrade\";\n"
        conf+="        proxy_read_timeout 86400;\n"
        conf+="        proxy_send_timeout 86400;\n"
        conf+="        proxy_buffering off;\n"
        conf+="    }\n\n"
        # Django admin — never cache, always proxy directly to backend
        conf+="    location /admin/ {\n"
        conf+="        proxy_pass http://backend:5000;\n"
        conf+="        proxy_http_version 1.1;\n"
        conf+="        proxy_set_header Host \$host;\n"
        conf+="        proxy_set_header X-Real-IP \$remote_addr;\n"
        conf+="        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;\n"
        conf+="        proxy_set_header X-Forwarded-Proto \$scheme;\n"
        conf+="        proxy_set_header X-Request-From \"nginx\";\n"
        conf+="        proxy_cache off;\n"
        conf+="        proxy_no_cache 1;\n"
        conf+="        proxy_cache_bypass 1;\n"
        conf+="        proxy_pass_header Set-Cookie;\n"
        conf+="        proxy_read_timeout 300s;\n"
        conf+="        proxy_connect_timeout 60s;\n"
        conf+="        proxy_send_timeout 300s;\n"
        conf+="    }\n\n"
        # Regular HTTP/API requests with caching
        conf+="    location / {\n"
        conf+="        if (\$request_method = 'OPTIONS') {\n"
        conf+="            add_header 'Access-Control-Allow-Origin'      \"\$cors_origin\" always;\n"
        conf+="            add_header 'Access-Control-Allow-Credentials' 'true'         always;\n"
        conf+="            add_header 'Access-Control-Allow-Methods'     'GET, POST, PUT, PATCH, DELETE, OPTIONS' always;\n"
        conf+="            add_header 'Access-Control-Allow-Headers'     'Authorization, Content-Type, X-CSRFToken, X-Requested-With, Accept, Origin, X-Request-UUID, Idempotency-Key, Cache-Control, Pragma' always;\n"
        conf+="            add_header 'Access-Control-Max-Age'           '86400'        always;\n"
        conf+="            return 204;\n"
        conf+="        }\n"
        conf+="        proxy_pass http://backend:5000;\n"
        conf+="        proxy_http_version 1.1;\n"
        conf+="        proxy_set_header Host \$host;\n"
        conf+="        proxy_set_header X-Real-IP \$remote_addr;\n"
        conf+="        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;\n"
        conf+="        proxy_set_header X-Forwarded-Proto \$scheme;\n"
        conf+="        proxy_set_header Origin \$http_origin;\n"
        conf+="        proxy_cache nginx_cache;\n"
        conf+="        proxy_cache_valid 200 302 10m;\n"
        conf+="        proxy_cache_valid 404 1m;\n"
        conf+="        proxy_cache_methods GET HEAD;\n"
        conf+="        proxy_cache_use_stale error timeout updating http_500 http_502 http_503 http_504;\n"
        conf+="        add_header X-Proxy-Cache \$upstream_cache_status always;\n"
        conf+="        proxy_read_timeout 300s;\n"
        conf+="        proxy_connect_timeout 60s;\n"
        conf+="        proxy_send_timeout 300s;\n"
        conf+="    }\n"
        conf+="}\n\n"
    done

    # Frontend Domains
    local fe_count=$(jq '.deployment.frontendDomains // [] | length' "$CONFIG_FILE" 2>/dev/null || echo "0")
    for ((i=0; i<fe_count; i++)); do
        local fe_domain
        fe_domain=$(jq -r ".deployment.frontendDomains[$i]" "$CONFIG_FILE")
        if [[ -z "$fe_domain" || "$fe_domain" == "null" ]]; then continue; fi

        conf+="server {\n"
        conf+="    listen 8443 ssl;\n"
        conf+="    server_name ${fe_domain};\n"
        conf+="    ssl_certificate /etc/letsencrypt/fullchain.pem;\n"
        conf+="    ssl_certificate_key /etc/letsencrypt/privkey.pem;\n"
        conf+="    proxy_read_timeout 86400;\n"
        conf+="    proxy_send_timeout 86400;\n"
        conf+="    ssl_protocols TLSv1.2 TLSv1.3;\n"
        conf+="    ssl_ciphers HIGH:!aNULL:!MD5;\n"
        conf+="    root /var/www/onedash;\n"
        conf+="    location / { try_files \$uri \$uri/ /index.html; }\n"
        conf+="}\n\n"
    done

    # Homepage Domains
    local hp_count=$(jq '.deployment.homepageDomains // [] | length' "$CONFIG_FILE" 2>/dev/null || echo "0")
    for ((i=0; i<hp_count; i++)); do
        local hp_domain
        hp_domain=$(jq -r ".deployment.homepageDomains[$i]" "$CONFIG_FILE")
        if [[ -z "$hp_domain" || "$hp_domain" == "null" ]]; then continue; fi

        conf+="server {\n"
        conf+="    listen 8443 ssl;\n"
        conf+="    server_name ${hp_domain};\n"
        conf+="    ssl_certificate /etc/letsencrypt/fullchain.pem;\n"
        conf+="    ssl_certificate_key /etc/letsencrypt/privkey.pem;\n"
        conf+="    proxy_read_timeout 86400;\n"
        conf+="    proxy_send_timeout 86400;\n"
        conf+="    ssl_protocols TLSv1.2 TLSv1.3;\n"
        conf+="    ssl_ciphers HIGH:!aNULL:!MD5;\n"
        conf+="    root /var/www/homepage;\n"
        conf+="    location / { try_files \$uri \$uri/ /index.html; }\n"
        conf+="}\n\n"
    done

    # GohcosWeb / Hosting Homepage Domains
    local gohcos_count=$(jq '.deployment.gohcosDomains // [] | length' "$CONFIG_FILE" 2>/dev/null || echo "0")
    for ((i=0; i<gohcos_count; i++)); do
        local gh_domain
        gh_domain=$(jq -r ".deployment.gohcosDomains[$i]" "$CONFIG_FILE")
        if [[ -z "$gh_domain" || "$gh_domain" == "null" ]]; then continue; fi

        conf+="server {\n"
        conf+="    listen 8443 ssl;\n"
        conf+="    server_name ${gh_domain};\n"
        conf+="    ssl_certificate /etc/letsencrypt/fullchain.pem;\n"
        conf+="    ssl_certificate_key /etc/letsencrypt/privkey.pem;\n"
        conf+="    proxy_read_timeout 86400;\n"
        conf+="    proxy_send_timeout 86400;\n"
        conf+="    ssl_protocols TLSv1.2 TLSv1.3;\n"
        conf+="    ssl_ciphers HIGH:!aNULL:!MD5;\n"
        conf+="    root /var/www/gohcos;\n"
        conf+="    location / { try_files \$uri \$uri/ /index.html; }\n"
        conf+="}\n\n"
    done

    # ── Wildcard catch-all for tenant system subdomains (*.rootDomain) ─────────
    # Every system-generated subdomain (e.g. galaxy.hcos.io) is handled by
    # this block.  Specific server_name entries (request.*, onedash.*, etc.)
    # always win over the wildcard, so they are unaffected.
    local rd_wc_count
    rd_wc_count=$(jq '.deployment.rootDomains // [] | length' "$CONFIG_FILE" 2>/dev/null || echo "0")
    for ((wi=0; wi<rd_wc_count; wi++)); do
        local wc_rd
        wc_rd=$(jq -r ".deployment.rootDomains[$wi].domain" "$CONFIG_FILE")
        [[ -z "$wc_rd" || "$wc_rd" == "null" ]] && continue
        conf+="# Wildcard catch-all for tenant subdomains (*.${wc_rd})\n"
        conf+="server {\n"
        conf+="    listen 8443 ssl;\n"
        conf+="    server_name *.${wc_rd};\n"
        conf+="    ssl_certificate /etc/letsencrypt/fullchain.pem;\n"
        conf+="    ssl_certificate_key /etc/letsencrypt/privkey.pem;\n"
        conf+="    proxy_read_timeout 86400;\n"
        conf+="    proxy_send_timeout 86400;\n"
        conf+="    ssl_protocols TLSv1.2 TLSv1.3;\n"
        conf+="    ssl_ciphers HIGH:!aNULL:!MD5;\n"
        conf+="    root /var/www/onedash;\n"
        conf+="    location / { try_files \$uri \$uri/ /index.html; }\n"
        conf+="}\n\n"
    done
    # ─────────────────────────────────────────────────────────────────────────

    # ── Section for own-domain tenant blocks added at runtime by NginxManager ─
    conf+="# === DYNAMIC TENANT DOMAINS (AUTO-GENERATED) ===\n"
    conf+="# Own-domain tenant blocks are appended here by NginxManager.\n"
    conf+="# DO NOT EDIT THIS SECTION MANUALLY.\n"
    conf+="# === DYNAMIC TENANT DOMAINS (AUTO-GENERATED) ===\n\n"

    # ── HTTP → HTTPS redirect (explicit domain list) ──
    local all_http_domains="platform.${primary_domain}"
    for ((i=0; i<kc_count; i++)); do
        local _kd; _kd=$(jq -r ".deployment.keycloakDomains[$i]" "$CONFIG_FILE")
        [[ -n "$_kd" && "$_kd" != "null" ]] && all_http_domains+=" $_kd"
    done
    for ((i=0; i<fe_count; i++)); do
        local _fd; _fd=$(jq -r ".deployment.frontendDomains[$i]" "$CONFIG_FILE")
        [[ -n "$_fd" && "$_fd" != "null" ]] && all_http_domains+=" $_fd"
    done
    for ((i=0; i<api_count; i++)); do
        local _ad; _ad=$(jq -r ".deployment.apiDomains[$i]" "$CONFIG_FILE")
        [[ -n "$_ad" && "$_ad" != "null" ]] && all_http_domains+=" $_ad"
    done
    conf+="server {\n"
    conf+="    listen 80;\n"
    conf+="    server_name ${all_http_domains};\n"
    conf+="    return 301 https://\$server_name\$request_uri;\n"
    conf+="}\n\n"

    # internal.local HTTP proxy
    conf+="server {\n"
    conf+="    listen 80;\n"
    conf+="    server_name internal.local;\n"
    conf+="    location / {\n"
    conf+="        proxy_pass http://internal.local:9000;\n"
    conf+="    }\n"
    conf+="}\n\n"

    # HTTP catch-all: proxy unknown domains to CyberPanel / OpenLiteSpeed
    conf+="server {\n"
    conf+="    listen 80 default_server;\n"
    conf+="    server_name _;\n"
    conf+="    location / {\n"
    conf+="        proxy_pass http://cyberpanel_host:80;\n"
    conf+="        proxy_http_version 1.1;\n"
    conf+="        proxy_set_header Host \$host;\n"
    conf+="        proxy_set_header X-Real-IP \$remote_addr;\n"
    conf+="        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;\n"
    conf+="        proxy_set_header X-Forwarded-Proto \$scheme;\n"
    conf+="    }\n"
    conf+="}\n"

    # Write config files
    mkdir -p "$BASE_DIR/nginx/conf.d"
    echo -e "$conf" > "$BASE_DIR/nginx/conf.d/default.conf"
    mkdir -p "$nginx_dir"
    echo -e "$conf" > "$nginx_dir/default.conf.template"

    # ── Generate nginx.conf with SNI stream block ──
    # Routes TLS by SNI hostname: infrastructure domains → nginx HTTP (8443),
    # everything else → CyberPanel/OpenLiteSpeed (443)
    local nginx_main_conf=""
    nginx_main_conf+="user  nginx;\nworker_processes  auto;\n\n"
    nginx_main_conf+="error_log  /var/log/nginx/error.log notice;\npid        /run/nginx.pid;\n\n"
    nginx_main_conf+="events {\n    worker_connections  1024;\n}\n\n"
    nginx_main_conf+="stream {\n"
    nginx_main_conf+="    map \$ssl_preread_server_name \$tls_upstream {\n"
    # Add infrastructure domains to SNI map
    nginx_main_conf+="        platform.${primary_domain}    nginx_https;\n"
    for ((i=0; i<kc_count; i++)); do
        local _kd; _kd=$(jq -r ".deployment.keycloakDomains[$i]" "$CONFIG_FILE")
        [[ -n "$_kd" && "$_kd" != "null" ]] && nginx_main_conf+="        ${_kd}    nginx_https;\n"
    done
    for ((i=0; i<api_count; i++)); do
        local _ad; _ad=$(jq -r ".deployment.apiDomains[$i]" "$CONFIG_FILE")
        [[ -n "$_ad" && "$_ad" != "null" ]] && nginx_main_conf+="        ${_ad}    nginx_https;\n"
    done
    for ((i=0; i<fe_count; i++)); do
        local _fd; _fd=$(jq -r ".deployment.frontendDomains[$i]" "$CONFIG_FILE")
        [[ -n "$_fd" && "$_fd" != "null" ]] && nginx_main_conf+="        ${_fd}    nginx_https;\n"
    done
    for ((i=0; i<hp_count; i++)); do
        local _hd; _hd=$(jq -r ".deployment.homepageDomains[$i]" "$CONFIG_FILE")
        [[ -n "$_hd" && "$_hd" != "null" ]] && nginx_main_conf+="        ${_hd}    nginx_https;\n"
    done
    for ((i=0; i<gohcos_count; i++)); do
        local _gd; _gd=$(jq -r ".deployment.gohcosDomains[$i]" "$CONFIG_FILE")
        [[ -n "$_gd" && "$_gd" != "null" ]] && nginx_main_conf+="        ${_gd}    nginx_https;\n"
    done
    # Wildcard subdomains for root domains
    for ((wi=0; wi<rd_wc_count; wi++)); do
        local wc_rd_sni
        wc_rd_sni=$(jq -r ".deployment.rootDomains[$wi].domain" "$CONFIG_FILE")
        [[ -z "$wc_rd_sni" || "$wc_rd_sni" == "null" ]] && continue
        local wc_rd_escaped
        wc_rd_escaped=$(echo "$wc_rd_sni" | sed 's/\./\\./g')
        nginx_main_conf+="        ~^.+\\.${wc_rd_escaped}\$    nginx_https;\n"
    done
    nginx_main_conf+="        default                 cyberpanel_https;\n"
    nginx_main_conf+="    }\n\n"
    nginx_main_conf+="    upstream nginx_https {\n        server 127.0.0.1:8443;\n    }\n\n"
    nginx_main_conf+="    upstream cyberpanel_https {\n        server cyberpanel_host:443;\n    }\n\n"
    nginx_main_conf+="    server {\n"
    nginx_main_conf+="        listen 443;\n        listen [::]:443;\n\n"
    nginx_main_conf+="        ssl_preread  on;\n        proxy_pass   \$tls_upstream;\n\n"
    nginx_main_conf+="        proxy_connect_timeout  10s;\n        proxy_timeout          86400s;\n"
    nginx_main_conf+="    }\n"
    nginx_main_conf+="}\n\n"
    nginx_main_conf+="http {\n"
    nginx_main_conf+="    include       /etc/nginx/mime.types;\n"
    nginx_main_conf+="    default_type  application/octet-stream;\n\n"
    nginx_main_conf+="    log_format  main  '\$remote_addr - \$remote_user [\$time_local] \"\$request\" '\n"
    nginx_main_conf+="                      '\$status \$body_bytes_sent \"\$http_referer\" '\n"
    nginx_main_conf+="                      '\"\$http_user_agent\" \"\$http_x_forwarded_for\"';\n\n"
    nginx_main_conf+="    access_log  /var/log/nginx/access.log  main;\n\n"
    nginx_main_conf+="    sendfile        on;\n    keepalive_timeout  65;\n\n"
    nginx_main_conf+="    include /etc/nginx/conf.d/*.conf;\n"
    nginx_main_conf+="}\n"

    echo -e "$nginx_main_conf" > "$BASE_DIR/nginx/nginx.conf"

    update_status "nginx" "Phase 6: Nginx config and nginx.conf written"
}

phase_docker_compose() {
    update_status "compose" "Phase 7: Generating docker-compose.yml..."

    local backend_dir frontend_dir homepage_dir gohcos_dir primary_kc_domain
    backend_dir=$(jq -r '.deployment.repositories[] | select(.type=="backend") | .folder // "BACKEND-API-HCOM"' "$CONFIG_FILE")
    frontend_dir=$(jq -r '.deployment.repositories[] | select(.type=="frontend") | .folder // "ONEDASH.HCOS.IO"' "$CONFIG_FILE")
    homepage_dir=$(jq -r '.deployment.repositories[] | select(.type=="homepage") | .folder // "HOMEPAGE"' "$CONFIG_FILE")
    gohcos_dir=$(jq -r '.deployment.repositories[] | select(.type=="gohcos") | .folder // "GOHCOSWEB"' "$CONFIG_FILE")
    primary_kc_domain=$(jq -r '.deployment.keycloakDomains[0] // "keycloak.example.com"' "$CONFIG_FILE")

    cat > "$BASE_DIR/docker-compose.yml" <<COMPOSEEOF
services:
  postgres:
    image: postgres:14-alpine
    container_name: postgres
    environment:
      POSTGRES_DB: \${BACKEND_DB:-hcos_db}
      POSTGRES_USER: \${BACKEND_USER:-hcos_db_admin}
      POSTGRES_PASSWORD: \${BACKEND_PASSWORD:-hcos_password}
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./init-multiple-databases.sh:/docker-entrypoint-initdb.d/init-multiple-databases.sh:ro
    networks:
      - hcos_network
    extra_hosts:
      - "postgres.local:host-gateway"
    ports:
      - "5432:5432"

  redis:
    image: redis:alpine
    container_name: redis
    networks:
      - hcos_network

$(if [[ -d "$BASE_DIR/fraud-detection-service" ]]; then
cat <<FRAUDEOF
  fraud_checker:
    build:
      context: ./fraud-detection-service
    container_name: fraud_checker
    networks:
      - hcos_network
FRAUDEOF
fi)

  cyberpanel_host:
    image: almalinux:9.5
    container_name: cyberpanel_alma
    privileged: true
    cgroup: host
    stop_signal: SIGRTMIN+3
    entrypoint: ["/bin/bash", "/opt/cyberpanel-entrypoint.sh"]
    ports:
      - "8090:8090"
      - "7080:7080"
    environment:
      - HOSTNAME_FOR_SSL=platform.hcos.io
      - CLOUDFLARE_API_KEY=\${CLOUDFLARE_FULL_API_KEY}
      - CLOUDFLARE_API_EMAIL=\${CLOUDFLARE_API_EMAIL}
    volumes:
      - /sys/fs/cgroup:/sys/fs/cgroup
      - cyberpanel_data:/var/www
      - cyberpanel_app:/mnt/cyberpanel_persist
      - cyberpanel_lsws:/usr/local/lsws
      - cyberpanel_lscp:/usr/local/lscp
      - cyberpanel_mysql:/var/lib/mysql
      - cyberpanel_etc:/etc/cyberpanel
      - cyberpanel_letsencrypt:/etc/letsencrypt
      - ./${backend_dir}/CONTROL:/usr/local/CONTROL:ro
      - ./cyberpanel-entrypoint.sh:/opt/cyberpanel-entrypoint.sh:ro
    networks:
      hcos_network:
        aliases:
          - platform.hcos.io

  keycloak:
    build:
      context: ./keycloak
    container_name: keycloak
    command: start --optimized
    environment:
      - KC_PROXY_HEADERS=xforwarded
      - KC_HOSTNAME=https://${primary_kc_domain}
      - KC_HOSTNAME_STRICT=true
      - KC_HOSTNAME_BACKCHANNEL_DYNAMIC=true
      - KC_HTTP_ENABLED=true
      - KC_HTTP_PORT=3001
      - KEYCLOAK_ADMIN=admin
      - KEYCLOAK_ADMIN_PASSWORD=\${KEYCLOAK_ADMIN_PASSWORD:-admin}
      - KC_DB=postgres
      - KC_DB_URL=jdbc:postgresql://postgres:5432/keycloakdb
      - KC_DB_USERNAME=\${BACKEND_USER:-hcos_db_admin}
      - KC_DB_PASSWORD=\${BACKEND_PASSWORD:-hcos_password}
    ports:
      - "3001:3001"
    networks:
      - hcos_network
    depends_on:
      - postgres
    extra_hosts:
      - "${primary_kc_domain}:host-gateway"
      - "postgres.local:host-gateway"

  backend:
    build:
      context: ./${backend_dir}
    container_name: backend_service
    command: daphne -b 0.0.0.0 -p 5000 hcos.asgi:application
    env_file: .env
    volumes:
      - ./${backend_dir}:/app
      - /var/run/docker.sock:/var/run/docker.sock
      # Shared nginx config — backend writes here, nginx_main reads from /etc/nginx/conf.d
      - ./nginx/conf.d:/etc/nginx-conf
    environment:
      - DATABASE_URL=postgres://\${BACKEND_USER:-hcos_db_admin}:\${BACKEND_PASSWORD:-hcos_password}@postgres:5432/\${BACKEND_DB:-hcos_db}
      - CELERY_BROKER_URL=redis://redis:6379/0
      - CELERY_RESULT_BACKEND=redis://redis:6379/0
      - CHANNELS_REDIS_HOST=redis
      - CHANNELS_REDIS_PORT=6379
    depends_on:
      - postgres
      - redis
    networks:
      - hcos_network
    extra_hosts:
      - "${primary_kc_domain}:host-gateway"
      - "internal.local:host-gateway"
      - "postgres.local:host-gateway"
    ports:
      - "5000:5000"

  celery:
    build:
      context: ./${backend_dir}
    container_name: celery_worker
    command: celery -A hcos worker -l info -E
    env_file: .env
    volumes:
      - ./${backend_dir}:/app
      - /var/run/docker.sock:/var/run/docker.sock
    environment:
      - DATABASE_URL=postgres://\${BACKEND_USER:-hcos_db_admin}:\${BACKEND_PASSWORD:-hcos_password}@postgres:5432/\${BACKEND_DB:-hcos_db}
      - CELERY_BROKER_URL=redis://redis:6379/0
      - CELERY_RESULT_BACKEND=redis://redis:6379/0
    depends_on:
      - postgres
      - redis
      - backend
    extra_hosts:
      - "internal.local:host-gateway"
      - "postgres.local:host-gateway"
    networks:
      - hcos_network

  celery-beat:
    build:
      context: ./${backend_dir}
    container_name: celery_beat
    command: celery -A hcos beat -l info
    env_file: .env
    volumes:
      - ./${backend_dir}:/app
    environment:
      - DATABASE_URL=postgres://\${BACKEND_USER:-hcos_db_admin}:\${BACKEND_PASSWORD:-hcos_password}@postgres:5432/\${BACKEND_DB:-hcos_db}
      - CELERY_BROKER_URL=redis://redis:6379/0
      - CELERY_RESULT_BACKEND=redis://redis:6379/0
    extra_hosts:
      - "internal.local:host-gateway"
      - "postgres.local:host-gateway"
    depends_on:
      - postgres
      - redis
      - backend
    networks:
      - hcos_network

  nginx_main:
    image: nginx:latest
    container_name: nginx_main
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx/templates:/etc/nginx/templates
      # Custom nginx.conf: adds stream block for SNI-based routing of user domains to CyberPanel
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf:ro
      - ./certbot/conf:/etc/letsencrypt:ro
      - ./${frontend_dir}/dist:/var/www/onedash
      - ./${homepage_dir}/dist:/var/www/homepage
      - ./${gohcos_dir}/dist:/var/www/gohcos
    environment:
      IS_DEBUG: "false"
    depends_on:
      - backend
      - keycloak
    networks:
      hcos_network:
        aliases:
          - onedash.hcos.io
    extra_hosts:
      - "internal.local:host-gateway"

networks:
  hcos_network:
    driver: bridge

volumes:
  postgres_data:
    driver: local
  cyberpanel_data:
  cyberpanel_app:
  cyberpanel_lsws:
  cyberpanel_lscp:
  cyberpanel_mysql:
  cyberpanel_etc:
  cyberpanel_letsencrypt:
COMPOSEEOF

    update_status "compose" "Phase 7: docker-compose.yml written"
}

phase_docker_up() {
    update_status "docker_up" "Phase 8: Starting Docker stack (this may take several minutes)..."

    cd "$BASE_DIR"

    # Stop existing stack
    run_cmd "$COMPOSE_CMD down 2>/dev/null || true" "true"

    # Ensure host Nginx is stopped so it doesn't conflict with container Nginx on ports 80/443
    if command -v systemctl &>/dev/null; then
        systemctl stop nginx 2>/dev/null || true
        systemctl disable nginx 2>/dev/null || true
    fi

    # Build frontend and homepage before starting docker
    local frontend_dir homepage_dir gohcos_dir
    frontend_dir=$(jq -r '.deployment.repositories[] | select(.type=="frontend") | .folder // "ONEDASH.HCOS.IO"' "$CONFIG_FILE")
    homepage_dir=$(jq -r '.deployment.repositories[] | select(.type=="homepage") | .folder // "HOMEPAGE"' "$CONFIG_FILE")
    gohcos_dir=$(jq -r '.deployment.repositories[] | select(.type=="gohcos") | .folder // "GOHCOSWEB"' "$CONFIG_FILE")

    if [[ -d "$BASE_DIR/$frontend_dir" ]]; then
        update_status "docker_up" "Building frontend ($frontend_dir)..."
        cd "$BASE_DIR/$frontend_dir"
        run_cmd "docker run --rm -v \"$BASE_DIR/$frontend_dir\":/app -w /app node:20-alpine sh -c 'npm install && npm run build'" "true"
        cd "$BASE_DIR"
    fi

    if [[ -d "$BASE_DIR/$homepage_dir" ]]; then
        update_status "docker_up" "Building homepage ($homepage_dir)..."
        cd "$BASE_DIR/$homepage_dir"
        run_cmd "docker run --rm -v \"$BASE_DIR/$homepage_dir\":/app -w /app node:20-alpine sh -c 'npm install && npm run build'" "true"
        cd "$BASE_DIR"
    fi

    if [[ -d "$BASE_DIR/$gohcos_dir" ]]; then
        update_status "docker_up" "Building gohcosweb ($gohcos_dir)..."
        cd "$BASE_DIR/$gohcos_dir"
        run_cmd "docker run --rm -v \"$BASE_DIR/$gohcos_dir\":/app -w /app node:20-alpine sh -c 'npm install && npm run build'" "true"
        cd "$BASE_DIR"
    fi

    # Build and start
    update_status "docker_up" "Building and starting containers..."
    run_cmd "$COMPOSE_CMD up -d --build" "false" || {
        update_status "docker_up" "FATAL: docker compose up failed" "true"
        return 1
    }

    update_status "docker_up" "Phase 8: Docker stack started"
}

phase_migrations() {
    update_status "migrations" "Phase 9: Running Django migrations (waiting 20s for services)..."

    cd "$BASE_DIR"
    sleep 20

    run_cmd "$COMPOSE_CMD exec -T backend python manage.py migrate --noinput" "true"
    run_cmd "$COMPOSE_CMD exec -T backend python manage.py create_base_products" "true"
    run_cmd "$COMPOSE_CMD exec -T backend python manage.py collectstatic --noinput" "true"

    update_status "migrations" "Phase 9: Migrations complete"
}

# ═══════════════════════════════════════════════
#  STEP 4: RUN ALL DEPLOYMENT PHASES
# ═══════════════════════════════════════════════

run_deployment() {
    echo -e "${BOLD}${CYAN}═══ Step 4: Running Deployment ═══${NC}"

    phase_write_env       || { update_status "error" "Deployment failed at Phase 1: .env" "true"; return 1; }
    phase_cloudflare_creds || { update_status "error" "Deployment failed at Phase 2: Cloudflare" "true"; return 1; }
    phase_clone_repos      || { update_status "error" "Deployment failed at Phase 3: Clone" "true"; return 1; }
    phase_ssl              || { update_status "error" "Deployment failed at Phase 4: SSL" "true"; return 1; }
    phase_ensure_ssl       # Always ensure cert files exist (self-signed fallback)
    phase_dns              || { update_status "error" "Deployment failed at Phase 5: DNS" "true"; return 1; }
    phase_nginx_config     || { update_status "error" "Deployment failed at Phase 6: Nginx" "true"; return 1; }
    phase_docker_compose   || { update_status "error" "Deployment failed at Phase 7: Compose" "true"; return 1; }
    phase_docker_up        || { update_status "error" "Deployment failed at Phase 8: Docker" "true"; return 1; }
    phase_migrations       || { update_status "error" "Deployment failed at Phase 9: Migrations" "true"; return 1; }

    update_status "complete" "Deployment complete! All services are running." "false" "true"
}

# ═══════════════════════════════════════════════
#  STEP 5: CLEANUP
# ═══════════════════════════════════════════════

cleanup() {
    echo -e "${BOLD}${CYAN}═══ Step 5: Cleanup ═══${NC}"

    # Stop the setup UI container (no longer needed)
    echo -e "${YELLOW}Stopping Setup UI container...${NC}"
    docker stop "$SETUP_CONTAINER" 2>/dev/null || true
    docker rm "$SETUP_CONTAINER" 2>/dev/null || true

    local server_ip
    server_ip=$(cfg ".deployment.serverIp" 2>/dev/null || cat "$BASE_DIR/server-ip.txt" 2>/dev/null || echo "YOUR_SERVER_IP")

    echo ""
    echo -e "${BOLD}${GREEN}══════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}${GREEN}  HCOS DEPLOYMENT COMPLETE!${NC}"
    echo -e "${BOLD}${GREEN}══════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${YELLOW}Base directory:${NC} $BASE_DIR"
    echo -e "${YELLOW}Server IP:${NC}      $server_ip"
    echo ""
    echo -e "${YELLOW}Management commands:${NC}"
    echo -e "  cd $BASE_DIR && $COMPOSE_CMD logs -f"
    echo -e "  cd $BASE_DIR && $COMPOSE_CMD restart"
    echo -e "  cd $BASE_DIR && $COMPOSE_CMD down"
    echo -e "  cd $BASE_DIR && $COMPOSE_CMD up -d"
    echo ""
}

# ═══════════════════════════════════════════════
#  MAIN
# ═══════════════════════════════════════════════

main() {
    echo ""
    echo -e "${BOLD}${GREEN}══════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}${GREEN}  HCOS Deployment System${NC}"
    echo -e "${BOLD}${GREEN}══════════════════════════════════════════════════${NC}"
    echo ""

    install_prerequisites
    start_setup_ui
    wait_for_config
    run_deployment
    cleanup
}

main "$@"
