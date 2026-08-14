#!/bin/sh
set -e

/app/scripts/wait_for_db.sh

python manage.py migrate --noinput

if [ "$DJANGO_SETTINGS_MODULE" = "config.settings.prod" ]; then
    python manage.py collectstatic --noinput
fi

exec "$@"
