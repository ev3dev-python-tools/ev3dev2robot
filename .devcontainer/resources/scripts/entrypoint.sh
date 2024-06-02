#!/usr/bin/env bash

# this script runs as root,
# but the entrypoint user script runs as SESUSER user
#entrypoint_user_script="entrypoint_user"
entrypoint_user_script="/etc/xrdp/entrypoint_user.sh"
su -c "$entrypoint_user_script" $SESUSER &

# entrypoint_user_script="/home/$SESUSER/bin/entrypoint_user.sh"
# if [ -e "$entrypoint_user_script" ]; then
#     su -c "/bin/bash $entrypoint_user_script" $SESUSER
# fi

# Start xrdp sesman service
/usr/sbin/xrdp-sesman

# Run xrdp in foreground if no commands specified
if [ -z "$1" ]; then
    /usr/sbin/xrdp --nodaemon
else
    /usr/sbin/xrdp
    exec "$@"
fi
