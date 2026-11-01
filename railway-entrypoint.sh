#!/bin/sh
# Railway boot for ZITADEL. Required variables (set by the template):
#   ZITADEL_MASTERKEY            exactly 32 characters
#   ZITADEL_ADMIN_PASSWORD       password of the console admin (login name printed below)
#   PGHOST PGPASSWORD            the Postgres service (PGUSER defaults to postgres; superuser for init and runtime)
# Optional: RAILWAY_PUBLIC_DOMAIN (public host), PORT (listen port, defaults to 8080).
set -eu
PGUSER="${PGUSER:-postgres}"

PORT="${PORT:-8080}"
DOMAIN="${ZITADEL_EXTERNALDOMAIN:-${RAILWAY_PUBLIC_DOMAIN:-localhost}}"
DATA="${ZITADEL_DATA_DIR:-/zitadel-data}"

if [ "${#ZITADEL_MASTERKEY}" -ne 32 ]; then
  echo "railway-entrypoint: ZITADEL_MASTERKEY must be exactly 32 characters (got ${#ZITADEL_MASTERKEY})" >&2
  exit 1
fi

mkdir -p "$DATA"
PAT_FILE="$DATA/railway-agent.pat"

export ZITADEL_PORT="$PORT"
export ZITADEL_EXTERNALDOMAIN="$DOMAIN"
export ZITADEL_DATABASE_POSTGRES_HOST="${PGHOST:?PGHOST is required}"
export ZITADEL_DATABASE_POSTGRES_USER_USERNAME="$PGUSER"
export ZITADEL_DATABASE_POSTGRES_USER_PASSWORD="${PGPASSWORD:?PGPASSWORD is required}"
export ZITADEL_DATABASE_POSTGRES_ADMIN_USERNAME="$PGUSER"
export ZITADEL_DATABASE_POSTGRES_ADMIN_PASSWORD="$PGPASSWORD"
export ZITADEL_FIRSTINSTANCE_ORG_HUMAN_PASSWORD="${ZITADEL_ADMIN_PASSWORD:?ZITADEL_ADMIN_PASSWORD is required}"
export ZITADEL_FIRSTINSTANCE_PATPATH="$PAT_FILE"

# Wait for Postgres so a cold project start does not burn the first init attempt.
i=0
until nc -z -w 2 "$PGHOST" "$ZITADEL_DATABASE_POSTGRES_PORT" >/dev/null 2>&1; do
  i=$((i + 1))
  [ "$i" -ge 60 ] && { echo "railway-entrypoint: postgres $PGHOST unreachable after 120s" >&2; exit 1; }
  sleep 2
done

# Print the API token (first boot writes it; later boots reread the file on the volume).
(
  n=0
  while [ ! -s "$PAT_FILE" ] && [ "$n" -lt 600 ]; do n=$((n + 1)); sleep 2; done
  if [ -s "$PAT_FILE" ]; then
    echo "ZITADEL_ADMIN_LOGIN_NAME=${ZITADEL_FIRSTINSTANCE_ORG_HUMAN_USERNAME}"
    echo "ZITADEL_API_PAT=$(cat "$PAT_FILE")"
  fi
) &

exec "$@"
