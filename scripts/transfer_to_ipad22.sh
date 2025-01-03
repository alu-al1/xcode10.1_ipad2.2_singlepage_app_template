#!/bin/bash

function _ping_one_sec_total() {
    local tosecs=1
    local to=$(type timeout 2>/dev/null && echo "timeout $tosecs")
    local w=$(ping --help 2>&1 | grep '\-w' && echo "-w $tosecs" || echo "-W $tosecs")
    
    $to ping $w $@
}

function _exists() {
    local f=$1
    if [[ -z "$f" ]]; then
        return 1  # Return false if no argument is provided
    fi
    # Check if the file exists
    [ -e "$f" ]
}

# Set default values if not set
: "${IPAD2_SSH_KEY:=".ssh/ipad22"}"  					# Default SSH key
: "${IPAD2_HOST:="192.168.1.50"}"  					# Default IP address of the iPad
: "${IPAD2_TMP_TARGET:="/tmp"}"  					# Default temporary target directory on the iPad
: "${XCODE_PROJECT_PATH:="$HOME/Library/Developer/Xcode/DerivedData"}"  # Default Xcode project path
: "${PROJECT:="ipad2_project_template"}"  				# Default project name
: "${XCODE_BUILD_TYPE:="Release"}"  					# Default build type (can be Debug or Release)

# Debugging output to verify variables
# echo "IPAD2_SSH_KEY=$IPAD2_SSH_KEY"
# echo "IPAD2_HOST=$IPAD2_HOST"
# echo "IPAD2_TMP_TARGET=$IPAD2_TMP_TARGET"
# echo "XCODE_PROJECT_PATH=$XCODE_PROJECT_PATH"
# echo "PROJECT=$PROJECT"
# echo "XCODE_BUILD_TYPE=$XCODE_BUILD_TYPE"

BUILD_PATH="$XCODE_PROJECT_PATH/$PROJECT-*/Build/Products/$XCODE_BUILD_TYPE-*"

## TODO add md5sum check ( we may not need to deploy it )
## TODO add compress-scp-uncompress variant
## TODO check if rsync is available on the iPad and switch to it if possible

for apppath in $(find $BUILD_PATH -name "*.app"); do
	echo "Copying $apppath to iPad at $IPAD2_HOST:$IPAD2_TMP_TARGET"
	scp -i "$IPAD2_SSH_KEY" -r "$apppath" root@"$IPAD2_HOST:$IPAD2_TMP_TARGET"

	# Check if SCP was successful
	if [[ $? -ne 0 ]]; then
    		echo "Error: SCP failed to copy the app!"
    		exit 1
	fi
done;
echo "done"

