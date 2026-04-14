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

    # ── Overlay HCOS custom templates from CONTROL mount ──
    # The CONTROL source contains customized templates (clickable dashboard cards,
    # no notification banners, sidebar-integrated WordPress/Backup managers).
    # These must be copied on every warm start since the staging volume has the
    # originals from the initial CyberPanel install.
    echo "[warm-start] Applying HCOS template customizations from CONTROL..."
    TEMPLATE_SRC="$CONTROL_MOUNT/baseTemplate/templates"
    TEMPLATE_DST="/usr/local/CyberCP/baseTemplate/templates"
    if [ -d "$TEMPLATE_SRC/baseTemplate" ] && [ -d "$TEMPLATE_DST/baseTemplate" ]; then
        cp -f "$TEMPLATE_SRC/baseTemplate/index.html"    "$TEMPLATE_DST/baseTemplate/index.html"    2>/dev/null && echo "[warm-start]   Applied index.html (no banners)"
        cp -f "$TEMPLATE_SRC/baseTemplate/homePage.html" "$TEMPLATE_DST/baseTemplate/homePage.html" 2>/dev/null && echo "[warm-start]   Applied homePage.html (clickable insights)"
    fi
    WF_TEMPLATE_SRC="$CONTROL_MOUNT/websiteFunctions/templates/websiteFunctions"
    WF_TEMPLATE_DST="/usr/local/CyberCP/websiteFunctions/templates/websiteFunctions"
    if [ -d "$WF_TEMPLATE_SRC" ] && [ -d "$WF_TEMPLATE_DST" ]; then
        cp -f "$WF_TEMPLATE_SRC/wordpressManager.html" "$WF_TEMPLATE_DST/wordpressManager.html" 2>/dev/null && echo "[warm-start]   Applied wordpressManager.html (sidebar)"
        cp -f "$WF_TEMPLATE_SRC/backupManager.html"    "$WF_TEMPLATE_DST/backupManager.html"    2>/dev/null && echo "[warm-start]   Applied backupManager.html (sidebar)"
        cp -f "$WF_TEMPLATE_SRC/website.html"           "$WF_TEMPLATE_DST/website.html"           2>/dev/null && echo "[warm-start]   Applied website.html (WP install link)"
    fi
    # Deploy WordPress & Backup SPA static assets from CONTROL
    WF_STATIC_SRC="$CONTROL_MOUNT/websiteFunctions/static/websiteFunctions"
    WF_STATIC_DST="/usr/local/CyberCP/public/static/websiteFunctions"
    for spa in wordpress backups; do
        if [ -d "$WF_STATIC_SRC/$spa/assets" ]; then
            mkdir -p "$WF_STATIC_DST/$spa/assets"
            cp -f "$WF_STATIC_SRC/$spa/assets/"* "$WF_STATIC_DST/$spa/assets/" 2>/dev/null
            chown -R lscpd:lscpd "$WF_STATIC_DST/$spa/" 2>/dev/null
            find "$WF_STATIC_DST/$spa/" -type d -exec chmod 755 {} \; 2>/dev/null
            find "$WF_STATIC_DST/$spa/" -type f -exec chmod 644 {} \; 2>/dev/null
            echo "[warm-start]   Deployed $spa SPA assets"
        fi
    done
    # Copy HCOS agent scripts
    for agent in hcos_wordpress_agent.py hcos_backup_agent.py hcos_permission_agent.py; do
        if [ -f "$CONTROL_MOUNT/$agent" ]; then
            cp -f "$CONTROL_MOUNT/$agent" "/usr/local/CyberCP/$agent"
            chmod +x "/usr/local/CyberCP/$agent"
            echo "[warm-start]   Applied $agent"
        fi
    done
    # Deploy HCOS-customized CyberPanel Python views from CONTROL
    # These contain resource-limit display logic (reads hcos_resource_limits.json),
    # WordPress/Backup Manager API endpoints, and other HCOS integrations.
    for py_overlay in \
        "baseTemplate/views.py" \
        "websiteFunctions/views.py" \
        "websiteFunctions/website.py"; do
        if [ -f "$CONTROL_MOUNT/$py_overlay" ]; then
            cp -f "$CONTROL_MOUNT/$py_overlay" "/usr/local/CyberCP/$py_overlay"
            echo "[warm-start]   Applied $py_overlay (HCOS customization)"
        fi
    done

    # Deploy authz Keycloak refresh support (views, urls, middleware, settings)
    AUTHZ_SRC="$CONTROL_MOUNT/authz"
    AUTHZ_DST="/usr/local/CyberCP/authz"
    if [ -d "$AUTHZ_SRC" ] && [ -d "$AUTHZ_DST" ]; then
        for f in views.py urls.py middleware.py; do
            if [ -f "$AUTHZ_SRC/$f" ]; then
                cp -f "$AUTHZ_SRC/$f" "$AUTHZ_DST/$f"
            fi
        done
        echo "[warm-start]   Applied authz token refresh (views, urls, middleware)"
    fi
    if [ -f "$CONTROL_MOUNT/CyberCP/settings.py" ]; then
        cp -f "$CONTROL_MOUNT/CyberCP/settings.py" "/usr/local/CyberCP/CyberCP/settings.py"
        echo "[warm-start]   Applied CyberCP/settings.py (middleware registration)"
    fi

    # Fix applicationInstaller.py dbCreation bug (returns int instead of tuple on error)
    APP_INSTALLER_SRC="$CONTROL_MOUNT/plogical/applicationInstaller.py"
    APP_INSTALLER_DST="/usr/local/CyberCP/plogical/applicationInstaller.py"
    if [ -f "$APP_INSTALLER_SRC" ] && [ -d "$(dirname $APP_INSTALLER_DST)" ]; then
        cp -f "$APP_INSTALLER_SRC" "$APP_INSTALLER_DST"
        echo "[warm-start]   Applied applicationInstaller.py (dbCreation fix)"
    fi

    # Ensure HCOS server ID file exists for Backup/WordPress Manager SPAs
    if [ ! -f /etc/cyberpanel/hcos_server_id ]; then
        echo '1' > /etc/cyberpanel/hcos_server_id
        echo "[warm-start] Created /etc/cyberpanel/hcos_server_id = 1"
    fi

    # Ensure 'php' is in PATH for wp-cli (lsphp installs don't always create a 'php' binary)
    if ! command -v php &>/dev/null; then
        for v in 84 83 82 81 80 74; do
            if [ -x "/usr/local/lsws/lsphp${v}/bin/php" ]; then
                ln -sf "/usr/local/lsws/lsphp${v}/bin/php" /usr/local/bin/php
                echo "[warm-start] Created php symlink → lsphp${v}/bin/php"
                break
            elif [ -x "/usr/local/lsws/lsphp${v}/bin/lsphp" ]; then
                ln -sf "/usr/local/lsws/lsphp${v}/bin/lsphp" /usr/local/bin/php
                echo "[warm-start] Created php symlink → lsphp${v}/bin/lsphp"
                break
            fi
        done
    fi

    # Ensure sudoers secure_path includes /usr/local/bin (for wp-cli php symlink)
    # sudo resets PATH to secure_path; without /usr/local/bin, site-user wp-cli calls fail
    if [ -f /etc/sudoers ] && ! grep -q '/usr/local/bin' /etc/sudoers; then
        sed -i 's|^Defaults\s*secure_path\s*=.*|Defaults    secure_path = /usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin|' /etc/sudoers
        echo "[warm-start] Fixed sudoers secure_path to include /usr/local/bin"
    fi

    # Ensure cyberpanel user can run sudo without password
    if [ ! -f /etc/sudoers.d/cyberpanel ]; then
        echo "cyberpanel ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/cyberpanel
        chmod 440 /etc/sudoers.d/cyberpanel
        echo "[warm-start] Created /etc/sudoers.d/cyberpanel"
    fi

    # Install wp-cli if not present (required by hcos_wordpress_agent.py)
    if [ ! -x /usr/local/bin/wp ]; then
        echo "[warm-start] Installing wp-cli..."
        curl -sS https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar -o /usr/local/bin/wp \
            && chmod +x /usr/local/bin/wp \
            && echo "[warm-start] wp-cli installed ($(wp --version --allow-root 2>/dev/null || echo unknown))" \
            || echo "[warm-start] WARNING: wp-cli download failed"
    fi

    # Fix file permissions — staging volume may preserve host-user ownership
    # that the lscpd (uid 992) WSGI worker cannot read (e.g. settings.py 640)
    echo "[warm-start] Fixing file permissions for lscpd readability..."
    find /usr/local/CyberCP -type f ! -perm /o=r -exec chmod o+r {} + 2>/dev/null || true
    find /usr/local/CyberCP -type d ! -perm /o=rx -exec chmod o+rx {} + 2>/dev/null || true

    # Fix virtualenv python symlinks — /usr/local/CyberPanel/ doesn't survive container recreation
    SYS_PYTHON=$(readlink -f /usr/bin/python3)
    if [ ! -e /usr/local/CyberCP/bin/python3 ]; then
        echo "[warm-start] Fixing virtualenv python3 symlink..."
        rm -f /usr/local/CyberCP/bin/python3
        ln -sf "$SYS_PYTHON" /usr/local/CyberCP/bin/python3
    fi
    if [ ! -e /usr/local/CyberCP/bin/python ]; then
        echo "[warm-start] Fixing virtualenv python symlink..."
        rm -f /usr/local/CyberCP/bin/python
        ln -sf "$SYS_PYTHON" /usr/local/CyberCP/bin/python
    fi
    # Always ensure lswsgi wrapper uses the correct CyberCP site-packages
    if [ -f /usr/local/CyberCP/bin/lswsgi ] && ! [ -f /usr/local/CyberCP/bin/lswsgi.bin ]; then
        if ! grep -q "#!/bin/bash" /usr/local/CyberCP/bin/lswsgi; then
            mv /usr/local/CyberCP/bin/lswsgi /usr/local/CyberCP/bin/lswsgi.bin
        fi
    fi
    if [ -f /usr/local/CyberCP/bin/lswsgi.bin ]; then
        echo "[warm-start] Patching lswsgi PYTHONPATH..."
        cat << "EOF" > /usr/local/CyberCP/bin/lswsgi
#!/bin/bash
unset PYTHONHOME
unset LS_PYTHONBIN
export PYTHONPATH=/usr/local/CyberCP/lib/python3.9/site-packages:/usr/local/CyberCP/lib64/python3.9/site-packages:/usr/local/CyberCP
exec /usr/local/CyberCP/bin/lswsgi.bin "$@"
EOF
        chmod +x /usr/local/CyberCP/bin/lswsgi
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

        # ── Re-check php symlink after RPM install (lsphp may now be available) ──
        if ! command -v php &>/dev/null; then
            for v in 84 83 82 81 80 74; do
                if [ -x "/usr/local/lsws/lsphp${v}/bin/php" ]; then
                    ln -sf "/usr/local/lsws/lsphp${v}/bin/php" /usr/local/bin/php
                    echo "[warm-start] Created php symlink → lsphp${v}/bin/php (post-RPM)"
                    break
                elif [ -x "/usr/local/lsws/lsphp${v}/bin/lsphp" ]; then
                    ln -sf "/usr/local/lsws/lsphp${v}/bin/lsphp" /usr/local/bin/php
                    echo "[warm-start] Created php symlink → lsphp${v}/bin/lsphp (post-RPM)"
                    break
                fi
            done
        fi

        # ── Recreate system users/groups if missing ──
        id -u cyberpanel &>/dev/null 2>&1 || useradd -r -d /usr/local/CyberCP cyberpanel 2>/dev/null
        id -u lscpd &>/dev/null 2>&1    || useradd -r -s /sbin/nologin -d /usr/local/lscp lscpd 2>/dev/null
        id -u ftpuser &>/dev/null 2>&1   || useradd -r -s /sbin/nologin ftpuser 2>/dev/null
        getent group lscpd    &>/dev/null || groupadd lscpd 2>/dev/null
        getent group docker   &>/dev/null || groupadd docker 2>/dev/null
        getent group ftpgroup &>/dev/null || groupadd ftpgroup 2>/dev/null
        usermod -a -G docker cyberpanel 2>/dev/null || true
        usermod -a -G lscpd,lsadm,nobody lscpd 2>/dev/null || true

        # ── Create /home/cyberpanel/ (used for temp status files by virtualHostUtilities) ──
        mkdir -p /home/cyberpanel
        chown cyberpanel:cyberpanel /home/cyberpanel
        chmod 700 /home/cyberpanel

        # ── Recreate website system users and home directories from DB ──
        # MariaDB data volume persists across container recreation, but /etc/passwd does not.
        # Query the DB for all website externalApp users and recreate them.
        # NOTE: Moved to after MariaDB start below (needs DB access).

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
                ALTER USER 'root'@'localhost' IDENTIFIED VIA unix_socket OR mysql_native_password USING PASSWORD('$MYSQL_PW');
                FLUSH PRIVILEGES;" 2>/dev/null
            # Patch .env with correct password
            if [ -f /usr/local/CyberCP/.env ]; then
                sed -i "s|^DB_PASSWORD=.*|DB_PASSWORD=$MYSQL_PW|" /usr/local/CyberCP/.env
                sed -i "s|^ROOT_DB_PASSWORD=.*|ROOT_DB_PASSWORD=$MYSQL_PW|" /usr/local/CyberCP/.env
                chmod 644 /usr/local/CyberCP/.env 2>/dev/null
            fi
            chmod 644 /etc/cyberpanel/mysqlPassword 2>/dev/null
            echo "[warm-start] MySQL password synchronized."
        fi

        # ── Recreate website system users and home directories from DB ──
        # MariaDB data volume persists, but /etc/passwd does not survive container recreation.
        echo "[warm-start] Recreating website system users from database..."
        MYSQL_PW_WEB=""
        if [ -f /etc/cyberpanel/mysqlPassword ]; then
            MYSQL_PW_WEB=$(cat /etc/cyberpanel/mysqlPassword 2>/dev/null | tr -d '[:space:]')
        fi
        if [ -n "$MYSQL_PW_WEB" ]; then
            mysql -u root -p"$MYSQL_PW_WEB" -N -B -e \
                "SELECT domain, externalApp FROM cyberpanel.websiteFunctions_websites" 2>/dev/null | \
            while IFS=$'\t' read -r domain extapp; do
                if [ -n "$extapp" ] && ! id -u "$extapp" &>/dev/null; then
                    useradd -r -d "/home/$domain" -s /sbin/nologin "$extapp" 2>/dev/null
                    echo "[warm-start]   Created user $extapp for $domain"
                fi
                # Ensure home directory structure exists with correct ownership
                mkdir -p "/home/$domain/public_html" "/home/$domain/logs"
                chown -R "$extapp:$extapp" "/home/$domain" 2>/dev/null
                chmod 750 "/home/$domain" 2>/dev/null
            done
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

        # ── Install and configure PowerDNS (authoritative DNS for hosted zones) ──
        if ! command -v pdns_server &>/dev/null; then
            echo "[warm-start] Installing PowerDNS from offline repo..."
            rpm -ivh --nodeps --force \
                "$OFFLINE_REPO"/pdns-4.8.4-*.rpm \
                "$OFFLINE_REPO"/pdns-backend-mysql-4.8.4-*.rpm \
                2>&1 | tail -5 || true
        fi
        if command -v pdns_server &>/dev/null; then
            PDNS_PW=$(cat /etc/cyberpanel/mysqlPassword 2>/dev/null | tr -d '[:space:]')
            cat > /etc/pdns/pdns.conf << PDNSEOF
# PowerDNS configuration — managed by cyberpanel-entrypoint.sh
launch=gmysql
gmysql-host=127.0.0.1
gmysql-port=3306
gmysql-dbname=cyberpanel
gmysql-user=root
gmysql-password=$PDNS_PW
setuid=pdns
setgid=pdns
local-address=0.0.0.0
local-port=53
api=yes
api-key=hcos-pdns-internal-key
webserver=yes
webserver-address=0.0.0.0
webserver-port=8081
webserver-allow-from=0.0.0.0/0,::0/0
log-dns-details=no
loglevel=3
PDNSEOF
            chmod 640 /etc/pdns/pdns.conf
            chown root:pdns /etc/pdns/pdns.conf 2>/dev/null || true
            systemctl enable pdns 2>/dev/null || true
            systemctl restart pdns 2>/dev/null || true
            echo "[warm-start] PowerDNS: $(systemctl is-active pdns)"

            # Ensure PowerDNS 4.8 schema compatibility (older CyberPanel tables may lack columns)
            mysql -u root -e "ALTER TABLE cyberpanel.domains ADD COLUMN options TEXT DEFAULT NULL;" 2>/dev/null || true
            mysql -u root -e "ALTER TABLE cyberpanel.domains ADD COLUMN catalog VARCHAR(255) DEFAULT NULL;" 2>/dev/null || true
            # Fix unquoted TXT records (CyberPanel creates them without quotes but PDNS 4.8 requires them)
            mysql -u root -e "UPDATE cyberpanel.records SET content = CONCAT('\"', content, '\"') WHERE type='TXT' AND content NOT LIKE '\"%%';" 2>/dev/null || true
        fi

        # HCOS: Fix static file permissions for lscpd restricted bits policy
        if [ -d "/usr/local/CyberCP/public/static" ]; then
            echo "[warm-start] Applying HCOS restricted bits policy for lscpd static maps..."
            chown -R lscpd:lscpd "/usr/local/CyberCP/public/static" 2>/dev/null || true
            find "/usr/local/CyberCP/public/static" -type d -exec chmod 755 {} \; 2>/dev/null || true
            find "/usr/local/CyberCP/public/static" -type f -exec chmod 644 {} \; 2>/dev/null || true
        fi
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
            rm -f /usr/local/CyberCP/bin/python3 /usr/local/CyberCP/bin/python
            ln -sf "$SYS_PYTHON" /usr/local/CyberCP/bin/python3
            ln -sf "$SYS_PYTHON" /usr/local/CyberCP/bin/python
            echo "[entrypoint] Fixed virtualenv python symlink → $SYS_PYTHON"
        fi
        # Ensure lswsgi wrapper uses correct CyberCP site-packages
        if [ -f /usr/local/CyberCP/bin/lswsgi ] && ! [ -f /usr/local/CyberCP/bin/lswsgi.bin ]; then
            if ! grep -q "#!/bin/bash" /usr/local/CyberCP/bin/lswsgi; then
                mv /usr/local/CyberCP/bin/lswsgi /usr/local/CyberCP/bin/lswsgi.bin
            fi
        fi
        if [ -f /usr/local/CyberCP/bin/lswsgi.bin ]; then
            echo "[entrypoint] Patching lswsgi PYTHONPATH..."
            cat << "EOF" > /usr/local/CyberCP/bin/lswsgi
#!/bin/bash
unset PYTHONHOME
unset LS_PYTHONBIN
export PYTHONPATH=/usr/local/CyberCP/lib/python3.9/site-packages:/usr/local/CyberCP/lib64/python3.9/site-packages:/usr/local/CyberCP
exec /usr/local/CyberCP/bin/lswsgi.bin "$@"
EOF
            chmod +x /usr/local/CyberCP/bin/lswsgi
        fi

        # ── Ensure MySQL root uses dual auth: unix_socket for CLI + password for CyberPanel Python ──
        # Password will be properly set in the password fix block below
        mysql -u root -e "ALTER USER 'root'@'localhost' IDENTIFIED VIA unix_socket; FLUSH PRIVILEGES;" 2>/dev/null || true

        # ── Auto-fix MySQL password (avoids the 500 error on first login) ──
        echo "[entrypoint] Fixing MySQL 'cyberpanel' user password..."
        MYSQL_PW=""
        if [ -f /etc/cyberpanel/mysqlPassword ]; then
            MYSQL_PW=$(cat /etc/cyberpanel/mysqlPassword 2>/dev/null | tr -d '[:space:]')
        fi
        if [ -n "$MYSQL_PW" ]; then
            mysql -u root -e "ALTER USER 'cyberpanel'@'localhost' IDENTIFIED BY '$MYSQL_PW'; ALTER USER 'root'@'localhost' IDENTIFIED VIA unix_socket OR mysql_native_password USING PASSWORD('$MYSQL_PW'); FLUSH PRIVILEGES;" 2>/dev/null
            if [ -f /usr/local/CyberCP/.env ]; then
                sed -i "s|^DB_PASSWORD=.*|DB_PASSWORD=$MYSQL_PW|" /usr/local/CyberCP/.env
                sed -i "s|^ROOT_DB_PASSWORD=.*|ROOT_DB_PASSWORD=$MYSQL_PW|" /usr/local/CyberCP/.env
                chmod 644 /usr/local/CyberCP/.env 2>/dev/null
            fi
            chmod 644 /etc/cyberpanel/mysqlPassword 2>/dev/null
            systemctl restart lscpd 2>/dev/null
            echo "[entrypoint] MySQL password fix applied."
        else
            echo "[entrypoint] WARNING: Could not read /etc/cyberpanel/mysqlPassword — manual fix may be needed."
        fi

        # ── Sync /usr/local/CyberCP to staging volume AFTER all fixes ──
        # First apply HCOS template customizations from CONTROL mount
        echo "[entrypoint] Applying HCOS template customizations from CONTROL..."
        TEMPLATE_SRC="$CONTROL_WORK/baseTemplate/templates"
        TEMPLATE_DST="/usr/local/CyberCP/baseTemplate/templates"
        if [ -d "$TEMPLATE_SRC/baseTemplate" ] && [ -d "$TEMPLATE_DST/baseTemplate" ]; then
            cp -f "$TEMPLATE_SRC/baseTemplate/index.html"    "$TEMPLATE_DST/baseTemplate/index.html"    2>/dev/null && echo "[entrypoint]   Applied index.html (no banners)"
            cp -f "$TEMPLATE_SRC/baseTemplate/homePage.html" "$TEMPLATE_DST/baseTemplate/homePage.html" 2>/dev/null && echo "[entrypoint]   Applied homePage.html (clickable insights)"
        fi
        WF_TEMPLATE_SRC="$CONTROL_WORK/websiteFunctions/templates/websiteFunctions"
        WF_TEMPLATE_DST="/usr/local/CyberCP/websiteFunctions/templates/websiteFunctions"
        if [ -d "$WF_TEMPLATE_SRC" ] && [ -d "$WF_TEMPLATE_DST" ]; then
            cp -f "$WF_TEMPLATE_SRC/wordpressManager.html" "$WF_TEMPLATE_DST/wordpressManager.html" 2>/dev/null && echo "[entrypoint]   Applied wordpressManager.html (sidebar)"
            cp -f "$WF_TEMPLATE_SRC/backupManager.html"    "$WF_TEMPLATE_DST/backupManager.html"    2>/dev/null && echo "[entrypoint]   Applied backupManager.html (sidebar)"
            cp -f "$WF_TEMPLATE_SRC/website.html"           "$WF_TEMPLATE_DST/website.html"           2>/dev/null && echo "[entrypoint]   Applied website.html (WP install link)"
        fi
        # Deploy WordPress & Backup SPA static assets from CONTROL
        WF_STATIC_SRC="$CONTROL_WORK/websiteFunctions/static/websiteFunctions"
        WF_STATIC_DST="/usr/local/CyberCP/public/static/websiteFunctions"
        for spa in wordpress backups; do
            if [ -d "$WF_STATIC_SRC/$spa/assets" ]; then
                mkdir -p "$WF_STATIC_DST/$spa/assets"
                cp -f "$WF_STATIC_SRC/$spa/assets/"* "$WF_STATIC_DST/$spa/assets/" 2>/dev/null
                chown -R lscpd:lscpd "$WF_STATIC_DST/$spa/" 2>/dev/null
                find "$WF_STATIC_DST/$spa/" -type d -exec chmod 755 {} \; 2>/dev/null
                find "$WF_STATIC_DST/$spa/" -type f -exec chmod 644 {} \; 2>/dev/null
                echo "[entrypoint]   Deployed $spa SPA assets"
            fi
        done
        # Copy HCOS agent scripts
        for agent in hcos_wordpress_agent.py hcos_backup_agent.py hcos_permission_agent.py; do
            if [ -f "$CONTROL_WORK/$agent" ]; then
                cp -f "$CONTROL_WORK/$agent" "/usr/local/CyberCP/$agent"
                chmod +x "/usr/local/CyberCP/$agent"
                echo "[entrypoint]   Applied $agent"
            fi
        done
        # Deploy HCOS-customized CyberPanel Python views from CONTROL
        # These contain resource-limit display logic (reads hcos_resource_limits.json),
        # WordPress/Backup Manager API endpoints, and other HCOS integrations.
        for py_overlay in \
            "baseTemplate/views.py" \
            "websiteFunctions/views.py" \
            "websiteFunctions/website.py"; do
            if [ -f "$CONTROL_WORK/$py_overlay" ]; then
                cp -f "$CONTROL_WORK/$py_overlay" "/usr/local/CyberCP/$py_overlay"
                echo "[entrypoint]   Applied $py_overlay (HCOS customization)"
            fi
        done

        # Deploy authz Keycloak refresh support (views, urls, middleware, settings)
        AUTHZ_SRC="$CONTROL_WORK/authz"
        AUTHZ_DST="/usr/local/CyberCP/authz"
        if [ -d "$AUTHZ_SRC" ] && [ -d "$AUTHZ_DST" ]; then
            for f in views.py urls.py middleware.py; do
                if [ -f "$AUTHZ_SRC/$f" ]; then
                    cp -f "$AUTHZ_SRC/$f" "$AUTHZ_DST/$f"
                fi
            done
            echo "[entrypoint]   Applied authz token refresh (views, urls, middleware)"
        fi
        if [ -f "$CONTROL_WORK/CyberCP/settings.py" ]; then
            cp -f "$CONTROL_WORK/CyberCP/settings.py" "/usr/local/CyberCP/CyberCP/settings.py"
            echo "[entrypoint]   Applied CyberCP/settings.py (middleware registration)"
        fi

        # Fix applicationInstaller.py dbCreation bug (returns int instead of tuple on error)
        APP_INSTALLER_SRC="$CONTROL_WORK/plogical/applicationInstaller.py"
        APP_INSTALLER_DST="/usr/local/CyberCP/plogical/applicationInstaller.py"
        if [ -f "$APP_INSTALLER_SRC" ] && [ -d "$(dirname $APP_INSTALLER_DST)" ]; then
            cp -f "$APP_INSTALLER_SRC" "$APP_INSTALLER_DST"
            echo "[entrypoint]   Applied applicationInstaller.py (dbCreation fix)"
        fi

        # Ensure HCOS server ID file exists for Backup/WordPress Manager SPAs
        if [ ! -f /etc/cyberpanel/hcos_server_id ]; then
            echo '1' > /etc/cyberpanel/hcos_server_id
            echo "[entrypoint] Created /etc/cyberpanel/hcos_server_id = 1"
        fi

        # Ensure 'php' is in PATH for wp-cli
        if ! command -v php &>/dev/null; then
            for v in 84 83 82 81 80 74; do
                if [ -x "/usr/local/lsws/lsphp${v}/bin/php" ]; then
                    ln -sf "/usr/local/lsws/lsphp${v}/bin/php" /usr/local/bin/php
                    echo "[entrypoint] Created php symlink → lsphp${v}/bin/php"
                    break
                elif [ -x "/usr/local/lsws/lsphp${v}/bin/lsphp" ]; then
                    ln -sf "/usr/local/lsws/lsphp${v}/bin/lsphp" /usr/local/bin/php
                    echo "[entrypoint] Created php symlink → lsphp${v}/bin/lsphp"
                    break
                fi
            done
        fi

        # Ensure sudoers secure_path includes /usr/local/bin (for wp-cli php symlink)
        if [ -f /etc/sudoers ] && ! grep -q '/usr/local/bin' /etc/sudoers; then
            sed -i 's|^Defaults\s*secure_path\s*=.*|Defaults    secure_path = /usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin|' /etc/sudoers
            echo "[entrypoint] Fixed sudoers secure_path to include /usr/local/bin"
        fi

        # Ensure cyberpanel user can run sudo without password
        if [ ! -f /etc/sudoers.d/cyberpanel ]; then
            echo "cyberpanel ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/cyberpanel
            chmod 440 /etc/sudoers.d/cyberpanel
            echo "[entrypoint] Created /etc/sudoers.d/cyberpanel"
        fi

        # Install wp-cli if not present (required by hcos_wordpress_agent.py)
        if [ ! -x /usr/local/bin/wp ]; then
            echo "[entrypoint] Installing wp-cli..."
            curl -sS https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar -o /usr/local/bin/wp \
                && chmod +x /usr/local/bin/wp \
                && echo "[entrypoint] wp-cli installed ($(wp --version --allow-root 2>/dev/null || echo unknown))" \
                || echo "[entrypoint] WARNING: wp-cli download failed"
        fi

        # Ensure static files are not violating lscpd security policy
        if [ -d "/usr/local/CyberCP/public/static" ]; then
            echo "[entrypoint] Applying HCOS restricted bits policy for lscpd static maps before sync..."
            chown -R lscpd:lscpd "/usr/local/CyberCP/public/static" 2>/dev/null || true
            find "/usr/local/CyberCP/public/static" -type d -exec chmod 755 {} \; 2>/dev/null || true
            find "/usr/local/CyberCP/public/static" -type f -exec chmod 644 {} \; 2>/dev/null || true
        fi

        # ── Re-sync MySQL password AFTER overlay (settings.py may use a different default) ──
        SETTINGS_PW=$(python3 -c "
import re, os
with open('/usr/local/CyberCP/CyberCP/settings.py') as f:
    m = re.search(r\"'PASSWORD'\\s*:\\s*os\\.getenv\\([^,]+,\\s*'([^']+)'\\)\", f.read())
    print(m.group(1) if m else '')
" 2>/dev/null)
        if [ -n "$SETTINGS_PW" ]; then
            CUR_PW=$(cat /etc/cyberpanel/mysqlPassword 2>/dev/null | tr -d '[:space:]')
            if [ "$SETTINGS_PW" != "$CUR_PW" ]; then
                echo "[entrypoint] Re-syncing MySQL passwords after overlay (settings.py default differs from mysqlPassword file)..."
                mysql -u root -e "ALTER USER 'cyberpanel'@'localhost' IDENTIFIED BY '$SETTINGS_PW'; ALTER USER 'root'@'localhost' IDENTIFIED VIA unix_socket OR mysql_native_password USING PASSWORD('$SETTINGS_PW'); FLUSH PRIVILEGES;" 2>/dev/null
                echo -n "$SETTINGS_PW" > /etc/cyberpanel/mysqlPassword
                chmod 644 /etc/cyberpanel/mysqlPassword 2>/dev/null
                systemctl restart lscpd 2>/dev/null
                echo "[entrypoint] MySQL password re-synced to match settings.py."
            fi
        fi

        # ── Install and configure PowerDNS (authoritative DNS for hosted zones) ──
        OFFLINE_REPO_COLD="$CONTROL_WORK/offline/repos/el9/packages"
        if ! command -v pdns_server &>/dev/null; then
            echo "[entrypoint] Installing PowerDNS from offline repo..."
            rpm -ivh --nodeps --force \
                "$OFFLINE_REPO_COLD"/pdns-4.8.4-*.rpm \
                "$OFFLINE_REPO_COLD"/pdns-backend-mysql-4.8.4-*.rpm \
                2>&1 | tail -5 || true
        fi
        if command -v pdns_server &>/dev/null; then
            PDNS_PW_COLD=$(cat /etc/cyberpanel/mysqlPassword 2>/dev/null | tr -d '[:space:]')
            cat > /etc/pdns/pdns.conf << PDNSEOF
# PowerDNS configuration — managed by cyberpanel-entrypoint.sh
launch=gmysql
gmysql-host=127.0.0.1
gmysql-port=3306
gmysql-dbname=cyberpanel
gmysql-user=root
gmysql-password=$PDNS_PW_COLD
setuid=pdns
setgid=pdns
local-address=0.0.0.0
local-port=53
api=yes
api-key=hcos-pdns-internal-key
webserver=yes
webserver-address=0.0.0.0
webserver-port=8081
webserver-allow-from=0.0.0.0/0,::0/0
log-dns-details=no
loglevel=3
PDNSEOF
            chmod 640 /etc/pdns/pdns.conf
            chown root:pdns /etc/pdns/pdns.conf 2>/dev/null || true
            systemctl enable pdns 2>/dev/null || true
            systemctl restart pdns 2>/dev/null || true
            echo "[entrypoint] PowerDNS: $(systemctl is-active pdns)"

            # Ensure PowerDNS 4.8 schema compatibility (older CyberPanel tables may lack columns)
            mysql -u root -e "ALTER TABLE cyberpanel.domains ADD COLUMN options TEXT DEFAULT NULL;" 2>/dev/null || true
            mysql -u root -e "ALTER TABLE cyberpanel.domains ADD COLUMN catalog VARCHAR(255) DEFAULT NULL;" 2>/dev/null || true
            # Fix unquoted TXT records (CyberPanel creates them without quotes but PDNS 4.8 requires them)
            mysql -u root -e "UPDATE cyberpanel.records SET content = CONCAT('\"', content, '\"') WHERE type='TXT' AND content NOT LIKE '\"%%';" 2>/dev/null || true
        fi

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

