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
# region: docker reset

function _genNetwork() {
		local out

		# halt services
		for cfg in ${WMS_DOCKER_STACKS}/*; do
			out=$( gum spin --title "$cfg is going down" -- docker-compose -f $cfg -p $WMS_DOCKER_NET down )
			# commonVerify $? "failed to stop services: $out" "$cfg halted"
			commonPrintf "$cfg is down"
		done
		unset cfg

		# rm network
		if [ "$(docker network ls --format "{{.Name}}" --filter "name=${WMS_DOCKER_NET}" | grep -w ${WMS_DOCKER_NET})" ]; then
			out=$( docker network rm $WMS_DOCKER_NET 2>&1 )
			commonVerify $? "failed to 'docker network rm' ${WMS_DOCKER_NET}: $out" "network rm done"
		fi

		# create network
		out=$( docker network create $WMS_DOCKER_INIT 2>&1 )
		commonVerify $? "failed to create network: $out" "$WMS_DOCKER_NET network is up"
}

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
			# err=$( sudo rm -rf "${WMS_PATH_WORKBENCH}/*" )
			err=$( gum spin --title "removing ${WMS_PATH_WORKBENCH}/*" -- sudo find "$WMS_PATH_WORKBENCH" -mindepth 1 -delete )
			commonVerify $? "$err" "cleaned ${WMS_PATH_WORKBENCH}/*"
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

	gum style 'THIS WILL WIPE ALL PERSISTENT DATA OF YOURS...'
	if [ "$WMS_EXEC_SURE" = "true" ]; then
		_wipe
	else
		gum confirm "${COMMON_PREFIX}are you 100% certain?" && _wipe || return
	fi
}


# endregion: remove config and persistent data
# region: process templates

function _genTemplates() {
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
			# gum spin --title "$( echo ${COMMON_RED}binary or empty: $templateRel -> $targetRel ${COMMON_NORM})" -- cp $template $target
			gum spin --title "binary or empty: $templateRel -> $targetRel" -- cp  $template $target 
			commonPrintfBold "binary or empty: $templateRel -> $targetRel" "${COMMON_RED}%s\n${COMMON_NORM}"
		elif [[ -f $template ]]; then
			commonPrintf "processed: $templateRel -> $targetRel"
			( echo "cat <<EOF" ; cat $template ; echo EOF ) | sh > $target
			commonVerify $? "unable to process $templateRel"
		else
			commonVerify 1 "$templateRel is not valid"
		fi
	done

	# out=$( gum spin --title "unpacking private docker registry" -- tar -C ${WMS_STACK1_DATA}/ -xzvf $WMS_STACK1_REPO  )
	# commonVerify $? "failed: $out" "docker repo in place"
	# out=$( rm  $WMS_STACK1_REPO )
	# commonVerify $? "failed: $out" "docker repo archive removed"

	unset out
	unset template
	unset target
}

function _genTemplatesRegistry() {
	out=$( gum spin --title "unpacking private docker registry" -- tar -C ${WMS_STACK1_DATA}/ -xzvf $WMS_STACK1_REPO  )
	commonVerify $? "failed: $out" "docker repo in place"
	out=$( rm  $WMS_STACK1_REPO )
	commonVerify $? "failed: $out" "docker repo archive removed"

	unset out
}

# endregion: process templates
# region: registry

function _genRegistry() {

	commonPrintf "setting tls cert and key for docker registry"
	out=$( openssl req \
		-newkey rsa:4096 -nodes -sha256 -keyout ${WMS_STACK1_DATA}/${WMS_STACK1_NAME}.key \
		-addext "subjectAltName = DNS:${WMS_STACK1_NAME}" \
		-x509 -days 36500 -out ${WMS_STACK1_DATA}/${WMS_STACK1_NAME}.crt \
		-batch )
	commonVerify $? "failed: $out"
	unset out

	local dir="/etc/docker/certs.d/${WMS_DOCKER_REGISTRY_HOST}:${WMS_DOCKER_REGISTRY_PORT}"
	out=$( sudo mkdir -p "$dir" 2>&1 )
	commonVerify $? "failed: $out"
	out=$( sudo cp ${WMS_STACK1_DATA}/${WMS_STACK1_NAME}.crt "$dir/ca.crt" 2>&1 )
	commonVerify $? "failed: $out" "${WMS_STACK1_DATA}/${WMS_STACK1_NAME}.crt -> ${dir}/ca.crt in place"
	unset out

	out=$( gum spin --title "bootstrapping ${WMS_STACK1_NAME}" -- docker-compose -f $WMS_STACK1_CFG -p $WMS_DOCKER_NET up -d )
	commonVerify $? "failed: $out" "${WMS_STACK1_NAME} is up"
	unset out

	#commonSleep $WMS_DOCKER_DELAY "waiting ${WMS_DOCKER_DELAY}s for the startup to finish"
	gum spin --title "waiting ${WMS_DOCKER_DELAY}s for the startup to finish" -- sleep $WMS_DOCKER_DELAY 
}

# endregion: registry
# region: db

function _genDb() {
	out=$( gum spin --title "bootstrapping ${WMS_STACK2_NAME}" -- docker-compose -f $WMS_STACK2_CFG -p $WMS_DOCKER_NET up -d 2>&1 )
	commonVerify $? "failed: $out" "${WMS_STACK2_NAME} is up"
	gum spin --title "waiting ${WMS_DOCKER_DELAY}s for the startup to finish" -- sleep $WMS_DOCKER_DELAY
	unset out
}

# endregion: db
# region: mq

function _genMq() {
	out=$( gum spin --title "bootstrapping ${WMS_STACK3_NAME}" -- docker-compose -f $WMS_STACK3_CFG -p $WMS_DOCKER_NET up -d )
	commonVerify $? "failed: $out" "${WMS_STACK3_NAME} is up"
	gum spin --title "waiting ${WMS_DOCKER_DELAY}s for the startup to finish" -- sleep $WMS_DOCKER_DELAY
	unset out
}

# endregion: mq
# region: cdc

function _genCdc() {
	# launch maxwell
	out=$( gum spin --title "bootstrapping ${WMS_STACK4_NAME}" --  docker-compose -f $WMS_STACK4_CFG -p $WMS_DOCKER_NET up -d )
	commonVerify $? "failed: $out" "${WMS_STACK4_NAME} is up"
	gum spin --title "waiting ${WMS_DOCKER_DELAY}s for the startup to finish" -- sleep $WMS_DOCKER_DELAY
	unset out

	# launch client
	# cd ${WMS_PATH_BASE}/dummy_consumer
	# go mod tidy
	# go run dummy_consumer.go
}

# endregion: cdc
# region: switchboard

# region: check for dependencies

commonYN "search for dependencies?" commonDeps ${COMMON_PREREQS[@]}

# endregion: deps
# region: startup warning

gum style  'THIS SCRIPT CAN BE DESTRUCTIVE' 'IT SHOULD BE RUN WITH SPECIAL CARE ON THE MAIN MANAGER NODE'
gum confirm "${COMMON_PREFIX}do you want to proceed?" && commonPrintf "okay then, going ahead..." || exit 0

# endregion: startup
# region: what to skip

# define a mapping between functions and descriptions
declare -A fnToSelected
fnToSelected["_genNetwork"]="1. reset docker"
fnToSelected["_genWipePersistent"]="2. remove persistent data"
fnToSelected["_genTemplates"]="3. process templates"
fnToSelected["_genTemplatesRegistry"]="4. populate docker registry"
fnToSelected["_genRegistry"]="5. setup registry"
fnToSelected["_genDb"]="6. bootstrap db"
fnToSelected["_genMq"]="7. bootstrap mq"
fnToSelected["_genCdc"]="8. bootstrap cdc"

# extract values from fnToSelected
fnToSelectedValues=()
for key in "${!fnToSelected[@]}"; do
	value="${fnToSelected[$key]}"
	fnToSelectedValues+=("$value")
done

# array with sorted items
declare -a fnToSelectedSorted=()
while IFS= read -r line; do
	if [ -n "$line" ]; then
		fnToSelectedSorted+=("$line")
	fi
done <<< $(printf "%s\n" "${fnToSelectedValues[@]}" | sort)

# gum options
gumOptions=()
for value in "${fnToSelectedSorted[@]}"; do
	for key in "${!fnToSelected[@]}"; do
		if [ "${fnToSelected[$key]}" == "$value" ]; then
			gumOptions+=("$value")
			break
		fi
	done
done

# get list of functions to skip
if [ "$WMS_EXEC_FORCE" != "true" ]; then
	gumSelected=$( gum choose --no-limit --header="${COMMON_PREFIX}everything is running by default, select what you want to skip:" "${gumOptions[@]}")
else
	gumSelected=()
fi

# arraw with function to skip
declare -a gumSelectedArray=()
while IFS= read -r line; do
	if [ -n "$line" ]; then
		gumSelectedArray+=("$line")
	fi
done <<< "$gumSelected"

if [ ${#gumSelectedArray[@]} -eq 0 ]; then
	commonPrintf "nothing will be skipped"
else
	commonPrintf "these steps will be skipped: $(commonJoinArray gumSelectedArray "\n%s" "")"
fi

# endregion: skip
# region: exec

# execute functions in the order of fnToSelectedSorted... bash is braindead
for element in "${fnToSelectedSorted[@]}"; do
	for fn in "${!fnToSelected[@]}"; do
		if [ "${fnToSelected[$fn]}" == "$element" ]; then
			if [[ -n "$element" && " ${gumSelectedArray[*]} " == *" $element "* ]]; then
				commonPrintf "skipping \"$element\""
			else
				commonPrintfBold "entering \"$element\" phase"
				[[ "$WMS_EXEC_DRY" == false ]] && $fn
			fi
			break
		fi
	done
done

# endregion: exec

# endregion: switchboard
# region: closing provisions

gum style  'ALL DONE!' 'IF THIS IS FINAL, ISSUE THE FOLLOWING COMMAND:' "sudo chmod a-x ${WMS_PATH_SCRIPTS}/genesis.sh"

# endregion: closing
