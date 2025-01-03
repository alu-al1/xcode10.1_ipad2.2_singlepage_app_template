#!/bin/bash

# TODO: check iPad2 SSH availability
# TODO: check iPad2 launchctl availability

function _ping_one_sec_total() {
    local tosecs=1
    local to=$(type timeout &>/dev/null && echo "timeout $tosecs")
    local w=$(ping --help 2>&1 | grep '\-w' &>/dev/null && echo "-w $tosecs" || echo "-W $tosecs")
    
    $to ping $w "$@"
}

# Set default values if not set
: "${IPAD2_SSH_KEY:=".ssh/ipad22"}"          # Default SSH key
: "${IPAD2_HOST:="192.168.1.50"}"           # Default IP address of the iPad
: "${IPAD2_TMP_TARGET:="/tmp"}"             # Default temporary target directory on the iPad
: "${PROJECT:="ipad2_project_template"}"    # Default project name

TARGET=/Applications

set -xe 

ipad2_cmd=$(cat << EOF
set -x

if [[ -z "\$TARGET" || -z "\$IPAD2_TMP_TARGET" || -z "\$PROJECT" ]]; then
    echo "One or more required variables are empty!" >&2
    exit 1
fi

## FIXME: app should be wsiped from the recent apps - only after that the new app will be loaded
for apppath in \$(find \$TARGET\/		-maxdepth 1 -name "\$PROJECT.app"); do
    for action in unbootstrap unload uncache remove; do    
	launchctl \$action "\$apppath/\$PROJECT"
    done;
    
    rm -rf "\$apppath.old"
    mv "\$apppath" "\$apppath.old"
done

# Process the new app
for apppath in \$(find \$IPAD2_TMP_TARGET\/	-maxdepth 1 -name "\$PROJECT.app"); do
    
    mv "\$apppath" "\$TARGET"
    launchctl load "\$TARGET/\$( basename \$apppath/)/\$PROJECT"
    
    find "\$TARGET/\$( basename \$apppath/)/\$PROJECT" -type f -exec md5sum {} \; | md5sum
done

echo "done"
EOF
)

# Ping the iPad to check connectivity
_ping_one_sec_total -c 1 "$IPAD2_HOST"

ssh -i "$IPAD2_SSH_KEY" root@"$IPAD2_HOST" <<-REMOTE_CMD
    export TARGET='$TARGET'
    export IPAD2_TMP_TARGET='$IPAD2_TMP_TARGET'
    export PROJECT='$PROJECT'
    $ipad2_cmd
REMOTE_CMD

