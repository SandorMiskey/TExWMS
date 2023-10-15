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
# region: strartup warning

commonPrintfBold " "
commonPrintfBold "THIS SCRIPT CAN BE DESTRUCTIVE, IT SHOULD BE RUN WITH SPECIAL CARE ON THE MAIN MANAGER NODE"
commonPrintfBold " "
force=$COMMON_FORCE
COMMON_FORCE=$WMS_EXEC_SURE
commonContinue "do you want to continue?"
export COMMON_FORCE=$force
unset force

# endregion: warning
# region: check for dependencies and versions

# _CAVersions() {
# 	local required_version=$DEPS_CA
# 	local actual_version=$( fabric-ca-client version | grep Version: | sed 's/.*Version: //' | sed 's/^v//i' )

# 	commonPrintf "required ca version: $required_version"
# 	commonPrintf "installed fabric-ca-client version: $actual_version"

# 	if [ "$actual_version" != "$required_version" ]; then
# 		commonVerify 1  "versions do not match required"
# 	fi 
# }
# commonYN "validate ca binary versions?" _CAVersions
commonYN "search for dependencies?" commonDeps ${COMMON_PREREQS[@]}

# endregion: dependencies and versions
# region: docker reset

function _genNetwork() {
		local out

		commonPrintf " "
		commonPrintf "reseting docker"
		commonPrintf " "

		# halt services
		out=$( docker-compose -f ${WMS_DOCKER_STACKS}/* -p $WMS_DOCKER_NET down 2>&1 )
		commonVerify $? "failed to stop services: $out" "halt done"

		# rm network
		if [ "$(docker network ls --format "{{.Name}}" --filter "name=${WMS_DOCKER_NET}" | grep -w ${WMS_DOCKER_NET})" ]; then
			out=$( docker network rm $WMS_DOCKER_NET 2>&1 )
			commonVerify $? "failed to 'docker network rm' ${WMS_DOCKER_NET}: $out" "network rm done"
		fi

		# create network
		out=$( docker network create $WMS_DOCKER_INIT 2>&1 )
		commonVerify $? "failed to create network: $out" "$WMS_DOCKER_NET network is up"
}
[[ "$WMS_EXEC_DRY" == false ]] && commonYN "reset docker, create network ${WMS_DOCKER_NET}?" _genNetwork

# endregion: docker reset
# region: remove config and persistent data

_genWipePersistent() {

	_wipe() {
		# purge or create workbench
		if [ -z "$WMS_PATH_WORKBENCH" ]; then
			commonVerify 1 "\$WMS_PATH_WORKBENCH should not be empty"
		fi
		if [ -d "$WMS_PATH_WORKBENCH" ]; then
			commonPrintf "$WMS_PATH_WORKBENCH exists"
			commonPrintf "removing ${WMS_PATH_WORKBENCH}/*"
			# err=$( sudo rm -rf "${WMS_PATH_WORKBENCH}/*" )
			err=$( sudo find "$WMS_PATH_WORKBENCH" -mindepth 1 -delete )
			commonVerify $? $err
		else
			commonPrintf "$PATH_WORKBENCH doesn't exists"
			commonPrintf "mkdir -p -v $PATH_WORKBENCH" 
			err=$( sudo mkdir -p -v "$PATH_WORKBENCH" )
			commonVerify $? $err
		fi

		# reset
		commonPrintf "chgrp and chmod g+rwx"
		local grp=$( id -g )
		err=$( sudo chgrp $grp "$WMS_PATH_WORKBENCH" )
		commonVerify $? $err
		err=$( sudo chmod g+rwx "$WMS_PATH_WORKBENCH" )
		commonVerify $? $err

		# remove localworkbench -> workbench symlink
		local localworkbench=$(realpath "$WMS_PATH_LOCALWORKBENCH")
		local workbench=$(realpath "$WMS_PATH_WORKBENCH")
		if [ "$localworkbench" = "$workbench" ]; then
			commonPrintf "\$WMS_PATH_LOCALWORKBENCH points to the proper \$WMS_PATH_WORKBENCH, it is not necessary to deal with any symlink"
		else
			if [ ! -z $WMS_PATH_LOCALWORKBENCH ]; then
				commonPrintf "removing $WMS_PATH_LOCALWORKBENCH symlink to $WMS_PATH_WORKBENCH"
				err=$( sudo rm -f "$WMS_PATH_LOCALWORKBENCH" )
				commonVerify $? $err
				commonPrintf "symlink $WMS_PATH_LOCALWORKBENCH -> $WMS_PATH_WORKBENCH"
				err=$( ln -s "$WMS_PATH_WORKBENCH" "$WMS_PATH_LOCALWORKBENCH" )
				commonVerify $? $err
			fi
		fi

		unset err
	}

	local force=$COMMON_FORCE
	COMMON_FORCE=$EXEC_SURE
	commonPrintfBold " "
	commonPrintfBold "THIS WILL WIPE ALL PERSISTENT DATA OF YOURS..."
	commonPrintfBold " "
	commonYN "SURE?" _wipe
	export COMMON_FORCE=$force
}

[[ "$WMS_EXEC_DRY" == false ]] && commonYN "wipe persistent data?" _genWipePersistent

# endregion: remove config and persistent data
# region: process templates

function _genTemplates() {
	commonPrintf " "
	commonPrintf "processing templates:"
	commonPrintf " "
	for template in $( find $WMS_PATH_TEMPLATES/* ! -name '.*' -print ); do
		target=$( commonSetvar $template )
		target=$( echo $target | sed s+$WMS_PATH_TEMPLATES+$WMS_PATH_WORKBENCH+ )

		local templateRel=$( echo "$template" | sed s+${WMS_PATH_BASE}/++g )
		local targetRel=$( echo "$target" | sed s+${WMS_PATH_BASE}/++g | sed s+_nope$++g )
		if [[ -d $template ]]; then
			commonPrintf "mkdir: $templateRel -> $targetRel"
			err=$( mkdir -p "$target" )
			commonVerify $? $err
		elif [[ $template == *_nope ]]; then
			target=$( echo "$target" | sed s+_nope$++g )
			commonPrintfBold "rename and cp: $templateRel -> $targetRel" "${COMMON_BLUE}%s\n${COMMON_NORM}"
			cp $template $target
		elif [[ $(file --mime-encoding -b $template) == "binary" ]]; then
			commonPrintf "binary or empty: $templateRel -> $targetRel" "${COMMON_RED}%s\n${COMMON_NORM}"
			cp $template $target
		elif [[ -f $template ]]; then
			commonPrintf "processed: $templateRel -> $targetRel"
			( echo "cat <<EOF" ; cat $template ; echo EOF ) | sh > $target
			commonVerify $? "unable to process $templateRel"
		else
			commonVerify 1 "$templateRel is not valid"
		fi
	done

	# commonPrintf " "
	# commonPrintf "unpacking private docker repo"
	# commonPrintf " "
	# out=$( tar -C ${COMMON1_REGISTRY_DATA}/ -xzvf ${COMMON1_REGISTRY_DATA}/docker.tgz  )
	# commonVerify $? "failed: $out" "docker repo in place"
	# out=$( rm ${COMMON1_REGISTRY_DATA}/docker.tgz  )
	# commonVerify $? "failed: $out" "docker repo archive removed"

	unset out
	unset template
	unset target
}

[[ "$WMS_EXEC_DRY" == false ]] && commonYN "process templates?" _genTemplates 

# endregion: process templates
# region: registry

function _genRegistry() {

	_inner() {
		commonPrintf " "
		commonPrintf "setting tls cert and key for docker registry"
		commonPrintf " "

		out=$( openssl req \
			-newkey rsa:4096 -nodes -sha256 -keyout ${WMS_STACK1_DATA}/${WMS_STACK1_NAME}.key \
			-addext "subjectAltName = DNS:${WMS_STACK1_NAME}" \
			-x509 -days 36500 -out ${WMS_STACK1_DATA}/${WMS_STACK1_NAME}.crt \
			-batch )
		commonVerify $? "failed: $out"
		unset out
	}
	commonYN "gen tls cert for docker registry?" _inner

	_inner() {
		local dir="/etc/docker/certs.d/${WMS_DOCKER_REGISTRY_HOST}:${WMS_DOCKER_REGISTRY_PORT}"
		out=$( sudo mkdir -p "$dir" 2>&1 )
		commonVerify $? "failed: $out"
		out=$( sudo cp ${WMS_STACK1_DATA}/${WMS_STACK1_NAME}.crt "$dir/ca.crt" 2>&1 )
		commonVerify $? "failed: $out" "${WMS_STACK1_DATA}/${WMS_STACK1_NAME}.crt -> ${dir}/ca.crt in place"
		unset out
	}
	commonYN "copy tls cert for registry?" _inner

	_inner() {
		commonPrintf " "
		commonPrintf "bootstrapping >>>${WMS_STACK1_NAME}<<<"
		commonPrintf " "
		out=$( docker-compose -f $WMS_STACK1_CFG -p $WMS_DOCKER_NET up -d 2>&1 )
		commonVerify $? "failed: $out" "${WMS_STACK1_NAME} is up"
		unset out
	}
	commonYN "bootstrap ${WMS_STACK1_NAME}?" _inner

	commonSleep $WMS_DOCKER_DELAY "waiting ${WMS_DOCKER_DELAY}s for the startup to finish"
	unset _inner
}
[[ "$WMS_EXEC_DRY" == false ]] && commonYN "bootstrap ${WMS_STACK1_NAME}?" _genRegistry

# endregion: registry
# region: closing provisions

_prefix="$COMMON_PREFIX"
COMMON_PREFIX="===>>> "
commonPrintfBold " "
commonPrintfBold "ALL DONE! IF THIS IS FINAL, ISSUE THE FOLLOWING COMMAND: sudo chmod a-x ${WMS_PATH_SCRIPTS}/genesis.sh"
commonPrintfBold " "
COMMON_PREFIX="_prefix"
unset _prefix

# endregion: closing
