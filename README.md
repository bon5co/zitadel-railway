# zitadel-railway

ZITADEL v4.20.0 wrapper image for the Railway template.

Upstream ships a distroless image with no shell. This image copies the static binary onto Alpine
and adds `railway-entrypoint.sh`, which derives the public domain from `RAILWAY_PUBLIC_DOMAIN`,
bootstraps a console admin from `ZITADEL_ADMIN_PASSWORD` and an IAM_OWNER service account, and prints the
service account's personal access token (`ZITADEL_API_PAT`) to the deploy log on every boot. Login V1 is
used (`ZITADEL_DEFAULTINSTANCE_FEATURES_LOGINV2_REQUIRED=false`) so one service serves console, login and API.

Mount a volume at `/zitadel-data`; it holds the token file.
