#!/bin/bash

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
commonPP $WMS_PATH_SCRIPTS

# endregion: config

ip=$( docker inspect ${WMS_DOCKER_NET}_${WMS_STACK2_S1_NAME}_1 | jq -r ".[0].NetworkSettings.Networks.${WMS_DOCKER_NET}.Gateway" )

docker run -it --rm $WMS_STACK4_S1_IMG bin/maxwell	\
	--user=$WMS_STACK4_S1_USER		\
	--password=$WMS_STACK4_S1_PW	\
	--producer=stdout	\
	--host=$ip	\
	--port=$WMS_STACK2_S1_PORT

