#!/usr/bin/env bash

msg() {
    echo -E "/* $1 */"
}



msg "Start supervisord to start Huginn..."
msg $(whoami)
disable_app="${DISABLE_APP:-false}"
disable_worker="${DISABLE_WORKER:-false}"
disable_additional_worker="${DISABLE_ADDITIONAL_WORKER:-false}"

if [ -f tmp/pids/server.pid ]; then
  rm tmp/pids/server.pid
fi
supervisord -c /etc/supervisor/conf.d/supervisord.conf

if [ "${disable_app}" = "false" ] 
then
    msg "Start app"
    supervisorctl -c /etc/supervisor/conf.d/supervisord.conf start app 
fi

if [ "${disable_worker}" = "false" ] 
then
    msg "Start worker"
    supervisorctl -c /etc/supervisor/conf.d/supervisord.conf start worker -c /etc/supervisor/conf.d/supervisord.conf 
fi

if [ "${disable_additional_worker}" = "false" ] 
then
    msg "Start additional worker"
    supervisorctl -c /etc/supervisor/conf.d/supervisord.conf start delay_1 
fi
