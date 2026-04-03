# Stage 1: Build the optimized Keycloak image
FROM quay.io/keycloak/keycloak:latest AS builder

# Enable health and metrics (optional but recommended for production)
ENV KC_HEALTH_ENABLED=true
ENV KC_METRICS_ENABLED=true

# Set build-time database vendor
ENV KC_DB=postgres

WORKDIR /opt/keycloak

# Copy custom themes and providers BEFORE building
COPY --chown=keycloak:keycloak themes/ /opt/keycloak/themes/
COPY --chown=keycloak:keycloak providers/ /opt/keycloak/providers/

# Run the build command to pre-configure the server
RUN /opt/keycloak/bin/kc.sh build

# Stage 2: Final runtime image
FROM quay.io/keycloak/keycloak:latest
COPY --from=builder /opt/keycloak/ /opt/keycloak/

# Entrypoint for production
ENTRYPOINT ["/opt/keycloak/bin/kc.sh"]
