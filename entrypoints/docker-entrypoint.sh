#!/usr/bin/env bash

msg() {
    echo -E "/* $1 */"
}

msg "Welcome $(whoami)"
msg "Starting supervisorâ€¦"

exec "$@"

supervisord -c /etc/supervisor/conf.d/huginn.conf
