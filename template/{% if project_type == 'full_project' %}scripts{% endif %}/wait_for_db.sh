#!/bin/sh
# Waits for Postgres to accept connections before continuing.
set -e

host="${DB_HOST:-db}"
port="${DB_PORT:-5432}"

echo "Waiting for Postgres at ${host}:${port}..."
until pg_isready -h "$host" -p "$port" >/dev/null 2>&1; do
    sleep 1
done
echo "Postgres is up."
