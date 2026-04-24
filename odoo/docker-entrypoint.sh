#!/bin/sh
set -e

mkdir -p /var/lib/odoo/filestore /var/lib/odoo/sessions

if [ "$(id -u)" = "0" ]; then
  chown -R odoo:odoo /var/lib/odoo/filestore /var/lib/odoo/sessions
  chmod 755 /var/lib/odoo/filestore
  chmod 700 /var/lib/odoo/sessions
  exec su -s /bin/sh odoo -c "exec $*"
fi

exec "$@"

