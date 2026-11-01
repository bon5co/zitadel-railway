# ZITADEL identity server for Railway. Upstream ships a distroless image (no shell), so this wrapper
# copies the static binary onto Alpine and adds a boot script that derives the public domain,
# bootstraps an admin user and an API service account from template variables, and prints the
# service account's personal access token to the deploy log on every boot.
FROM ghcr.io/zitadel/zitadel:v4.20.0@sha256:9ea0e9ecfdc43115da871242e40a0320f2ece864c7cd8b5d41a863a7f4902499 AS upstream

FROM alpine:3.21
RUN apk add --no-cache ca-certificates curl
COPY --from=upstream /app/zitadel /app/zitadel
COPY railway-entrypoint.sh /usr/local/bin/railway-entrypoint.sh
RUN chmod 0755 /usr/local/bin/railway-entrypoint.sh

# Baked literals: a template variable with a literal default publishes as a blank required field.
ENV ZITADEL_TLS_ENABLED=false \
    ZITADEL_EXTERNALPORT=443 \
    ZITADEL_EXTERNALSECURE=true \
    ZITADEL_DEFAULTINSTANCE_FEATURES_LOGINV2_REQUIRED=false \
    ZITADEL_DEFAULTINSTANCE_PASSWORDCOMPLEXITYPOLICY_HASSYMBOL=false \
    ZITADEL_FIRSTINSTANCE_ORG_NAME=ZITADEL \
    ZITADEL_FIRSTINSTANCE_ORG_HUMAN_USERNAME=admin@zitadel.example.com \
    ZITADEL_FIRSTINSTANCE_ORG_HUMAN_EMAIL_ADDRESS=admin@zitadel.example.com \
    ZITADEL_FIRSTINSTANCE_ORG_HUMAN_EMAIL_VERIFIED=true \
    ZITADEL_FIRSTINSTANCE_ORG_HUMAN_PASSWORDCHANGEREQUIRED=false \
    ZITADEL_FIRSTINSTANCE_ORG_MACHINE_MACHINE_USERNAME=railway-agent \
    ZITADEL_FIRSTINSTANCE_ORG_MACHINE_MACHINE_NAME=Railway\ agent \
    ZITADEL_FIRSTINSTANCE_ORG_MACHINE_PAT_EXPIRATIONDATE=2099-01-01T00:00:00Z \
    ZITADEL_DATABASE_POSTGRES_PORT=5432 \
    ZITADEL_DATABASE_POSTGRES_DATABASE=zitadel \
    ZITADEL_DATABASE_POSTGRES_USER_SSL_MODE=disable \
    ZITADEL_DATABASE_POSTGRES_ADMIN_SSL_MODE=disable

EXPOSE 8080
ENTRYPOINT ["/usr/local/bin/railway-entrypoint.sh"]
CMD ["/app/zitadel", "start-from-init", "--masterkeyFromEnv", "--tlsMode", "external"]
