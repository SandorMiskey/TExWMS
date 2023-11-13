#!/bin/sh

#
# Copyright TE-FOOD International GmbH., All Rights Reserved
#

# region: load config

[[ ${WMS_PATH_RC:-"unset"} == "unset" ]] && WMS_PATH_RC=${WMS_PATH_BASE}/scripts/common.sh
if [ ! -f  $WMS_PATH_RC ]; then
	echo "=> WMS_PATH_RC ($WMS_PATH_RC) not found, make sure proper path is set or you execute this from the repo's 'scrips' directory!"
	exit 1
fi
source $WMS_PATH_RC

if [[ ${WMS_PATH_SCRIPTS:-"unset"} == "unset" ]]; then
	commonVerify 1 "WMS_PATH_SCRIPTS is unset"
fi
commonPP $WMS_STACK4_S2_SRC

# endregion: config

cd $WMS_STACK4_S2_SRC
go mod tidy
go run ./...
