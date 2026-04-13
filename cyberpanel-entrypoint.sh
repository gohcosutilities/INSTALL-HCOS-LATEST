#!/bin/bash
# ═══════════════════════════════════════════════════════════════════
#  CyberPanel container entrypoint
#
#  Runs BEFORE systemd (/usr/sbin/init) on every container start.
#  Three modes:
#    1. HOT START  – CyberPanel fully present in container layer → just start systemd
#    2. WARM START – Volumes have CyberPanel data but container is fresh
#                    (after docker-compose down/up) → restore from staging volume,
#                    re-install RPMs, re-register systemd services, recreate users
#    3. COLD START – First-ever boot → full CyberPanel install from CONTROL
#
#  IMPORTANT: /usr/local/CyberCP is NOT directly volume-mounted because the
#  CyberPanel installer's shutil.move breaks when the target is a mount point.
#  Instead, a staging volume at /mnt/cyberpanel_persist stores a backup copy.
#  On warm start, the staging data is restored to /usr/local/CyberCP.
# ═══════════════════════════════════════════════════════════════════

CONTROL_MOUNT="/usr/local/CONTROL"       # ro bind-mount from host
CONTROL_WORK="/usr/local/CONTROL_WORK"   # writable copy inside container
INSTALL_MARKER="/etc/cyberpanel/.installed"  # on persisted cyberpanel_etc volume
PERSIST_DIR="/mnt/cyberpanel_persist"    # staging volume for /usr/local/CyberCP

# -- Guard: CONTROL mount must exist --
if [ ! -d "$CONTROL_MOUNT" ] || [ ! -f "$CONTROL_MOUNT/install.sh" ]; then
    echo "[entrypoint] WARNING: $CONTROL_MOUNT/install.sh not found. Skipping CyberPanel auto-install."
    exec /usr/sbin/init
fi

# ── HOT START: everything still in container layer (docker-compose stop/start) ──
if [ -f "$INSTALL_MARKER" ] && [ -f "/usr/local/CyberCP/CyberCP/wsgi.py" ] && command -v mariadbd &>/dev/null; then
    echo "[entrypoint] CyberPanel fully present (hot start). Starting systemd..."
    exec /usr/sbin/init
fi

# ── WARM START: staging volume has data but container is fresh (docker-compose down/up) ──
if [ -f "$INSTALL_MARKER" ] && [ -f "$PERSIST_DIR/CyberCP/wsgi.py" ]; then
    echo "[entrypoint] Detected CyberPanel on staging volume. Performing warm start..."

    # Swap curl-minimal if present (fresh AlmaLinux 9 container)
    if rpm -q curl-minimal &>/dev/null; then
        echo "[warm-start] Replacing curl-minimal with full curl..."
        dnf swap -y curl-minimal curl --allowerasing 2>/dev/null || true
    fi

    # Restore /usr/local/CyberCP from staging volume (use cp -a since rsync isn't in base image)
    echo "[warm-start] Restoring /usr/local/CyberCP from staging volume..."
    rm -rf /usr/local/CyberCP
    cp -a "$PERSIST_DIR" /usr/local/CyberCP
    echo "[warm-start] Restored $(du -sh /usr/local/CyberCP/ | cut -f1) to /usr/local/CyberCP/"

    # Fix virtualenv python symlink — /usr/local/CyberPanel/ doesn't survive container recreation
    if [ -L /usr/local/CyberCP/bin/python3 ] && ! [ -e /usr/local/CyberCP/bin/python3 ]; then
        echo "[warm-start] Fixing virtualenv python symlink..."
        SYS_PYTHON=$(readlink -f /usr/bin/python3)
        rm -f /usr/local/CyberCP/bin/python3
        ln -s "$SYS_PYTHON" /usr/local/CyberCP/bin/python3
    fi

    # Regenerate lscpd SSL certs if they are dangling symlinks
    if [ -L /usr/local/lscp/conf/cert.pem ] && ! [ -e /usr/local/lscp/conf/cert.pem ]; then
        echo "[warm-start] Regenerating lscpd SSL certificates..."
        rm -f /usr/local/lscp/conf/cert.pem /usr/local/lscp/conf/key.pem
        SSL_CN="${HOSTNAME_FOR_SSL:-localhost}"
        openssl req -x509 -nodes -days 3650 -newkey rsa:2048 \
            -keyout /usr/local/lscp/conf/key.pem \
            -out /usr/local/lscp/conf/cert.pem \
            -subj "/C=US/ST=State/L=City/O=CyberPanel/CN=${SSL_CN}" 2>/dev/null
    fi

    # Re-install RPMs and restore services in background (needs systemd)
    (
        OFFLINE_REPO="$CONTROL_MOUNT/offline/repos/el9/packages"

        for i in $(seq 1 60); do
            if systemctl is-system-running 2>/dev/null | grep -qE "running|degraded"; then break; fi
            sleep 2
        done
        echo "[warm-start] systemd ready. Re-installing RPMs..."

        # ── Configure offline DNF repo (fast, no internet needed) ──
        if [ -d "$OFFLINE_REPO/repodata" ]; then
            echo "[warm-start] Configuring offline DNF repo..."
            cat > /etc/yum.repos.d/cyberpanel-offline.repo << REPOEOF
[cyberpanel-offline]
name=CyberPanel Offline Packages
baseurl=file://$OFFLINE_REPO
enabled=1
gpgcheck=0
module_hotfixes=1
priority=1
REPOEOF
        fi

        # Add LiteSpeed repo (fallback for packages not in offline repo)
        if [ ! -f /etc/yum.repos.d/litespeed.repo ]; then
            rpm -Uvh https://rpms.litespeedtech.com/centos/litespeed-repo-1.4-1.el9.noarch.rpm 2>/dev/null || true
        fi

        # Add MariaDB repo (fallback for packages not in offline repo)
        if [ ! -f /etc/yum.repos.d/mariadb.repo ]; then
            cat > /etc/yum.repos.d/mariadb.repo << 'REPOEOF'
[mariadb]
name = MariaDB
baseurl = https://rpm.mariadb.org/10.11/rhel/$releasever/$basearch
gpgkey = https://rpm.mariadb.org/RPM-GPG-KEY-MariaDB
gpgcheck = 1
module_hotfixes = 1
REPOEOF
        fi

        # ── Install all required RPMs (matches repair_cyberpanel_server) ──
        PACKAGES="libxcrypt-compat procps-ng psmisc MariaDB-server MariaDB-client \
            MariaDB-common MariaDB-shared MariaDB-compat galera-4 rsync cronie \
            net-tools openssh-clients openssl socat postfix wget which zip unzip \
            tar gzip python3-pip python3-devel gcc bind bind-utils pure-ftpd sudo"

        # Try offline repo first (fast, no internet)
        if [ -d "$OFFLINE_REPO/repodata" ]; then
            echo "[warm-start] Installing RPMs from offline repo..."
            dnf install -y --disablerepo='*' --enablerepo='cyberpanel-offline' \
                --skip-broken $PACKAGES 2>&1 | tail -10
            # Fallback to all repos for anything that was missing offline
            dnf install -y --skip-broken $PACKAGES 2>&1 | tail -5
        else
            # No offline repo — install from saved list or essentials
            if [ -f /etc/cyberpanel/rpm-list.txt ]; then
                PKG_NAMES=$(sed 's/-[0-9].*$//' /etc/cyberpanel/rpm-list.txt | sort -u)
                echo "[warm-start] Re-installing $(echo "$PKG_NAMES" | wc -l) packages..."
                dnf install -y --skip-broken $PKG_NAMES $PACKAGES 2>&1 | tail -5
            else
                echo "[warm-start] Installing essential packages..."
                dnf install -y --skip-broken $PACKAGES 2>&1 | tail -5
            fi
        fi

        # Install OpenLiteSpeed if binary missing
        if ! [ -x /usr/local/lsws/bin/openlitespeed ]; then
            echo "[warm-start] Installing OpenLiteSpeed..."
            dnf install -y --enablerepo='cyberpanel-offline' --skip-broken openlitespeed 2>&1 | tail -5 || \
                rpm -ivh --nodeps "$OFFLINE_REPO"/openlitespeed-*.rpm 2>&1 | tail -3 || true
            dnf install -y --enablerepo='cyberpanel-offline' --skip-broken libnsl2 2>&1 | tail -3 || true
        fi

        # ── Install PHP shared library dependencies ──
        if [ -d "$OFFLINE_REPO" ]; then
            echo "[warm-start] Installing PHP shared library dependencies..."
            rpm -ivh --nodeps --force \
                "$OFFLINE_REPO"/libargon2-*.rpm \
                "$OFFLINE_REPO"/libsodium-*.rpm \
                "$OFFLINE_REPO"/libmemcached-awesome-*.rpm \
                "$OFFLINE_REPO"/libxslt-*.rpm \
                "$OFFLINE_REPO"/libzip-*.rpm \
                "$OFFLINE_REPO"/enchant-*.rpm \
                "$OFFLINE_REPO"/unixODBC-*.rpm \
                "$OFFLINE_REPO"/aspell-*.rpm \
                "$OFFLINE_REPO"/libtidy-*.rpm \
                "$OFFLINE_REPO"/libtool-ltdl-*.x86_64.rpm \
                "$OFFLINE_REPO"/liblzf-*.rpm \
                2>&1 | tail -10 || true
        fi

        # Install sudo directly from offline repo (CyberPanel requires it)
        if [ -d "$OFFLINE_REPO" ]; then
            rpm -ivh --nodeps --force "$OFFLINE_REPO"/sudo-*.rpm 2>&1 | tail -3 || true
        fi

        echo "[warm-start] RPMs installed. $(rpm -qa | wc -l) total packages."

        # ── Fix Python dependencies (lost on container recreation) ──
        echo "[warm-start] Re-installing Python dependencies..."
        dnf install -y --skip-broken python3-devel gcc MariaDB-devel zlib-devel openssl-devel
        pip3 install Django==3.2.19 mysqlclient==2.1.1 djangorestframework==3.14.0
        pip3 install -r /usr/local/CyberCP/requirments.txt 2>/dev/null || true
        pip3 install Django==3.2.19 mysqlclient==2.1.1 djangorestframework==3.14.0 --force-reinstall

        # ── Recreate system users/groups if missing ──
        id -u cyberpanel &>/dev/null 2>&1 || useradd -r -d /usr/local/CyberCP cyberpanel 2>/dev/null
        id -u lscpd &>/dev/null 2>&1    || useradd -r -s /sbin/nologin -d /usr/local/lscp lscpd 2>/dev/null
        id -u ftpuser &>/dev/null 2>&1   || useradd -r -s /sbin/nologin ftpuser 2>/dev/null
        getent group lscpd    &>/dev/null || groupadd lscpd 2>/dev/null
        getent group docker   &>/dev/null || groupadd docker 2>/dev/null
        getent group ftpgroup &>/dev/null || groupadd ftpgroup 2>/dev/null
        usermod -a -G docker cyberpanel 2>/dev/null || true
        usermod -a -G lscpd,lsadm,nobody lscpd 2>/dev/null || true

        # ── Create PHP session directories ──
        for v in 74 80 81 82 83; do
            mkdir -p /var/lib/lsphp/session/lsphp$v
        done
        chmod 1733 /var/lib/lsphp/session/lsphp* 2>/dev/null
        chown nobody:nobody /var/lib/lsphp/session/lsphp* 2>/dev/null

        # ── Create lscpd socket directory ──
        mkdir -p /usr/local/lscpd/admin
        chown -R lscpd:lscpd /usr/local/lscpd 2>/dev/null

        # ── Re-register systemd service files from backed-up copies on volumes ──
        if [ -f /usr/local/CyberCP/install/lscpd/lscpd.service ]; then
            cp -f /usr/local/CyberCP/install/lscpd/lscpd.service /etc/systemd/system/lscpd.service
        fi
        if [ -f /usr/local/lsws/openlitespeed.service.bak ]; then
            cp -f /usr/local/lsws/openlitespeed.service.bak /etc/systemd/system/openlitespeed.service
        elif [ -f /usr/local/lsws/admin/misc/lshttpd.service ]; then
            cp -f /usr/local/lsws/admin/misc/lshttpd.service /etc/systemd/system/openlitespeed.service
        fi

        systemctl daemon-reload
        systemctl enable mariadb lscpd openlitespeed 2>/dev/null || true

        # ── Start MariaDB ──
        echo "[warm-start] Starting MariaDB..."
        systemctl start mariadb 2>/dev/null || {
            echo "[warm-start] MariaDB failed, trying mysql_install_db..."
            mysql_install_db --user=mysql 2>/dev/null
            systemctl start mariadb 2>/dev/null
        }
        sleep 2

        # ── Fix MySQL root auth (ensure unix_socket) and sync cyberpanel password ──
        MYSQL_PW=""
        if [ -f /etc/cyberpanel/mysqlPassword ]; then
            MYSQL_PW=$(cat /etc/cyberpanel/mysqlPassword 2>/dev/null | tr -d '[:space:]')
        fi
        if [ -n "$MYSQL_PW" ]; then
            echo "[warm-start] Syncing MySQL cyberpanel password..."
            # Ensure root can log in via unix_socket
            mysql -u root -e "SELECT 1" &>/dev/null || {
                echo "[warm-start] Fixing MySQL root auth via skip-grant-tables..."
                systemctl stop mariadb
                mysqld_safe --skip-grant-tables --skip-networking &
                sleep 4
                mysql -e "FLUSH PRIVILEGES; ALTER USER 'root'@'localhost' IDENTIFIED VIA unix_socket; FLUSH PRIVILEGES;" 2>/dev/null
                kill $(pgrep mariadbd) 2>/dev/null; sleep 2
                systemctl start mariadb; sleep 2
            }
            mysql -u root -e "
                CREATE USER IF NOT EXISTS 'cyberpanel'@'localhost' IDENTIFIED BY '$MYSQL_PW';
                ALTER USER 'cyberpanel'@'localhost' IDENTIFIED BY '$MYSQL_PW';
                GRANT ALL PRIVILEGES ON *.* TO 'cyberpanel'@'localhost';
                ALTER USER 'root'@'localhost' IDENTIFIED BY '$MYSQL_PW';
                FLUSH PRIVILEGES;" 2>/dev/null
            # Patch .env with correct password
            if [ -f /usr/local/CyberCP/.env ]; then
                sed -i "s|^DB_PASSWORD=.*|DB_PASSWORD=$MYSQL_PW|" /usr/local/CyberCP/.env
                sed -i "s|^ROOT_DB_PASSWORD=.*|ROOT_DB_PASSWORD=$MYSQL_PW|" /usr/local/CyberCP/.env
            fi
            chmod 640 /etc/cyberpanel/mysqlPassword 2>/dev/null
            chown root:cyberpanel /etc/cyberpanel/mysqlPassword 2>/dev/null
            echo "[warm-start] MySQL password synchronized."
        fi

        # ── Start lscpd, then wait for socket before starting OLS ──
        echo "[warm-start] Starting lscpd..."
        systemctl restart lscpd 2>/dev/null
        sleep 3
        echo "[warm-start] Starting OpenLiteSpeed..."
        systemctl start openlitespeed 2>/dev/null

        # ── Restore persisted Let's Encrypt certificates (if available) ──
        PERSIST_CERT_DIR="/mnt/cyberpanel_persist/ssl_certs"
        if [ -f "${PERSIST_CERT_DIR}/fullchain.pem" ] && [ -f "${PERSIST_CERT_DIR}/privkey.pem" ]; then
            echo "[warm-start] Restoring persisted SSL certificates..."
            LSCP_CONF="/usr/local/lscp/conf"
            OLS_CONF="/usr/local/lsws/admin/conf"
            if [ -d "${LSCP_CONF}" ]; then
                cp -f "${PERSIST_CERT_DIR}/fullchain.pem" "${LSCP_CONF}/cert.pem"
                cp -f "${PERSIST_CERT_DIR}/privkey.pem"   "${LSCP_CONF}/key.pem"
                chmod 600 "${LSCP_CONF}/key.pem"
            fi
            if [ -d "${OLS_CONF}" ]; then
                cp -f "${PERSIST_CERT_DIR}/fullchain.pem" "${OLS_CONF}/webadmin.crt"
                cp -f "${PERSIST_CERT_DIR}/privkey.pem"   "${OLS_CONF}/webadmin.key"
                chmod 600 "${OLS_CONF}/webadmin.key"
            fi
            systemctl restart lscpd openlitespeed 2>/dev/null || true
            echo "[warm-start] SSL certificates restored and services reloaded."
        fi

        # ── Verify services ──
        echo "[warm-start] Service status:"
        echo "  lscpd: $(systemctl is-active lscpd)"
        echo "  mariadb: $(systemctl is-active mariadb)"
        echo "  openlitespeed: $(systemctl is-active openlitespeed)"
        echo "[warm-start] CyberPanel services restored."
    ) &

    exec /usr/sbin/init
fi

# ── COLD START: first-ever installation ──
echo "[entrypoint] CyberPanel not detected. Starting first-boot installation..."

# -- Swap curl-minimal for full curl (AlmaLinux 9 minimal ships curl-minimal which conflicts) --
if rpm -q curl-minimal &>/dev/null; then
    echo "[entrypoint] Replacing curl-minimal with full curl..."
    dnf swap -y curl-minimal curl --allowerasing 2>/dev/null || true
fi

# -- Copy CONTROL to a writable location --
rm -rf "$CONTROL_WORK" 2>/dev/null
cp -a "$CONTROL_MOUNT" "$CONTROL_WORK"

# Fix Windows CRLF line endings on all shell scripts
find "$CONTROL_WORK" -name '*.sh' -type f -exec sed -i 's/\r$//' {} +
chmod +x "$CONTROL_WORK/install.sh" "$CONTROL_WORK/cyberpanel.sh"

# -- Run the installer in the background so systemd can start --
(
    echo "[entrypoint] Waiting for systemd to be ready..."
    for i in $(seq 1 60); do
        if systemctl is-system-running 2>/dev/null | grep -qE "running|degraded"; then
            break
        fi
        sleep 2
    done
    echo "[entrypoint] systemd ready. Launching CyberPanel installer..."

    cd "$CONTROL_WORK"
    bash ./install.sh default > /var/log/cyberpanel-install.log 2>&1
    INSTALL_EXIT=$?

    if [ $INSTALL_EXIT -eq 0 ] && [ -f "/usr/local/CyberCP/CyberCP/wsgi.py" ]; then
        mkdir -p /etc/cyberpanel
        touch "$INSTALL_MARKER"
        echo "[entrypoint] CyberPanel installation completed successfully."

        # ── Save RPM list for future warm starts (all packages, not just MariaDB/OLS) ──
        rpm -qa | sort > /etc/cyberpanel/rpm-list.txt
        echo "[entrypoint] Saved $(wc -l < /etc/cyberpanel/rpm-list.txt) RPM names for warm-start recovery."

        # ── Save OLS service file for warm-start re-registration ──
        if [ -f /etc/systemd/system/openlitespeed.service ]; then
            cp -f /etc/systemd/system/openlitespeed.service /usr/local/lsws/openlitespeed.service.bak
        fi

        # ── Fix virtualenv python symlink to use system python (survives container recreation) ──
        if [ -L /usr/local/CyberCP/bin/python3 ]; then
            SYS_PYTHON=$(readlink -f /usr/bin/python3)
            rm -f /usr/local/CyberCP/bin/python3
            ln -s "$SYS_PYTHON" /usr/local/CyberCP/bin/python3
            echo "[entrypoint] Fixed virtualenv python symlink → $SYS_PYTHON"
        fi

        # ── Ensure MySQL root uses unix_socket auth (needed for warm-start root access) ──
        mysql -u root -e "ALTER USER 'root'@'localhost' IDENTIFIED VIA unix_socket; FLUSH PRIVILEGES;" 2>/dev/null || true

        # ── Auto-fix MySQL password (avoids the 500 error on first login) ──
        echo "[entrypoint] Fixing MySQL 'cyberpanel' user password..."
        MYSQL_PW=""
        if [ -f /etc/cyberpanel/mysqlPassword ]; then
            MYSQL_PW=$(cat /etc/cyberpanel/mysqlPassword 2>/dev/null | tr -d '[:space:]')
        fi
        if [ -n "$MYSQL_PW" ]; then
            mysql -u root -e "ALTER USER 'cyberpanel'@'localhost' IDENTIFIED BY '$MYSQL_PW'; FLUSH PRIVILEGES;" 2>/dev/null
            if [ -f /usr/local/CyberCP/.env ]; then
                sed -i "s|^DB_PASSWORD=.*|DB_PASSWORD=$MYSQL_PW|" /usr/local/CyberCP/.env
                sed -i "s|^ROOT_DB_PASSWORD=.*|ROOT_DB_PASSWORD=$MYSQL_PW|" /usr/local/CyberCP/.env
            fi
            chmod 644 /etc/cyberpanel/mysqlPassword 2>/dev/null
            systemctl restart lscpd 2>/dev/null
            echo "[entrypoint] MySQL password fix applied."
        else
            echo "[entrypoint] WARNING: Could not read /etc/cyberpanel/mysqlPassword — manual fix may be needed."
        fi

        # ── Sync /usr/local/CyberCP to staging volume AFTER all fixes ──
        if [ -d "$PERSIST_DIR" ]; then
            echo "[entrypoint] Syncing CyberCP to staging volume..."
            rsync -a --delete /usr/local/CyberCP/ "$PERSIST_DIR/"
            echo "[entrypoint] Synced $(du -sh "$PERSIST_DIR/" | cut -f1) to staging volume."
        fi

        # ── Provision Let's Encrypt SSL certificate (Cloudflare DNS-01) ──
        # Requires HOSTNAME_FOR_SSL, CLOUDFLARE_API_KEY, CLOUDFLARE_API_EMAIL
        # to be set in the container's environment (docker-compose.yml).
        SSL_SCRIPT="$CONTROL_WORK/provision_ssl.sh"
        if [ -f "$SSL_SCRIPT" ] && [ -n "${HOSTNAME_FOR_SSL:-}" ] && \
           [ -n "${CLOUDFLARE_API_KEY:-}${CLOUDFLARE_FULL_API_KEY:-}" ] && \
           [ -n "${CLOUDFLARE_API_EMAIL:-}" ]; then
            echo "[entrypoint] Provisioning SSL certificate for ${HOSTNAME_FOR_SSL}..."
            sed -i 's/\r$//' "$SSL_SCRIPT"
            chmod +x "$SSL_SCRIPT"
            bash "$SSL_SCRIPT" "${HOSTNAME_FOR_SSL}" >> /var/log/cyberpanel-ssl.log 2>&1 \
                && echo "[entrypoint] SSL provisioning complete. See /var/log/cyberpanel-ssl.log" \
                || echo "[entrypoint] WARNING: SSL provisioning failed. Check /var/log/cyberpanel-ssl.log"
        else
            echo "[entrypoint] Skipping SSL provisioning (HOSTNAME_FOR_SSL or Cloudflare credentials not set)."
        fi
    else
        echo "[entrypoint] CyberPanel installation exited with code $INSTALL_EXIT. Check /var/log/cyberpanel-install.log"
    fi
) &

# -- Hand off to systemd --
exec /usr/sbin/init
