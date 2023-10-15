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

for img in ${WMS_STACK1_IMAGES[@]}; do
	privimg=${WMS_DOCKER_REGISTRY_HOST}:${WMS_DOCKER_REGISTRY_PORT}/${WMS_DOCKER_NET}-${img}
	commonPrintf "$img"
	docker pull $img
	docker tag $img $privimg
	docker push $privimg 
	docker image remove $img
	docker image remove $privimg
done
unset img privimg
