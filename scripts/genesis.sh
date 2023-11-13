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

# if [[ ${WMS_PATH_SCRIPTS:-"unset"} == "unset" ]]; then
# 	commonVerify 1 "WMS_PATH_SCRIPTS is unset"
# fi
# commonPP $WMS_PATH_SCRIPTS

# endregion: config
# region: steps

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

_genWipe() {

	_wipe() {
		# authorize sudo
		commonPrintf "root privilege required, sudo authorization check"
		commonSudo

		# purge or create workbench
		if [ -z "$WMS_PATH_WORKBENCH" ]; then
			commonVerify 1 "\$WMS_PATH_WORKBENCH should not be empty"
		fi
		if [ -d "$WMS_PATH_WORKBENCH" ]; then
			commonPrintf "$WMS_PATH_WORKBENCH exists"
			err=$( gum spin --title "removing ${WMS_PATH_WORKBENCH}/*" -- sudo find "$WMS_PATH_WORKBENCH" -mindepth 1 -delete )
			commonVerify $? "$err" "cleaned ${WMS_PATH_WORKBENCH}/*"
		else
			commonPrintf "$WMS_PATH_WORKBENCH doesn't exists"
			commonPrintf "mkdir -p -v $WMS_PATH_WORKBENCH" 
			err=$( sudo mkdir -p -v "$WMS_PATH_WORKBENCH" 2>&1 )
			commonVerify $? "$err"
		fi

		# reset
		commonPrintf "chgrp and chmod g+rwx"
		local grp=$( id -g )
		err=$( sudo chgrp $grp "$WMS_PATH_WORKBENCH" )
		commonVerify $? "$err"
		err=$( sudo chmod g+rwx "$WMS_PATH_WORKBENCH" )
		commonVerify $? "$err"

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
			commonVerify $? "$err"
		elif [[ $template == *_nope ]]; then
			target=$( echo "$target" | sed s+_nope$++g )
			commonPrintfBold "rename and cp: $templateRel -> $targetRel" "${COMMON_BLUE}%s\n${COMMON_NORM}"
			cp $template $target
		elif [[ $(file --mime-encoding -b $template) == "binary" ]]; then
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

	unset out
	unset template
	unset target
}

function _genTempRegistry() {
	out=$( gum spin --title "unpacking private docker registry" -- tar -C ${WMS_STACK1_DATA}/ -xzvf $WMS_STACK1_REPO  )
	commonVerify $? "failed to unpack private docker repo" "docker repo in place"
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

	# local dir="/etc/docker/certs.d/${WMS_DOCKER_REGISTRY_HOST}:${WMS_DOCKER_REGISTRY_PORT}"
	# out=$( sudo mkdir -p "$dir" 2>&1 )
	# commonVerify $? "failed: $out"
	# out=$( sudo cp ${WMS_STACK1_DATA}/${WMS_STACK1_NAME}.crt "$dir/ca.crt" 2>&1 )
	# commonVerify $? "failed: $out" "${WMS_STACK1_DATA}/${WMS_STACK1_NAME}.crt -> ${dir}/ca.crt in place"
	# unset out

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

# endregion: steps
# region: switchboard

# region: check for dependencies

commonYN "search for dependencies?" commonDeps ${COMMON_PREREQS[@]}

# endregion: deps
# region: startup warning

gum style  'THIS SCRIPT CAN BE DESTRUCTIVE' 'IT SHOULD BE RUN WITH SPECIAL CARE ON THE MAIN MANAGER NODE'
gum confirm "${COMMON_PREFIX}do you want to proceed?" && commonPrintf "okay then, going ahead..." || exit 0

# endregion: startup
# region: what to skip

# no associative arrays to maintain POSIX /bin/sh compliance, so care must be
# taken to ensure that the functions to be called and their descriptions are
# given in the same order, which will also be the order of display and
# processing... is still quite far from full compatibility, so for now we'll
# settle for it to work with bash 3...

# mapping between functions and descriptions
declare -a fnNames
declare -a fnDescs
fnNames+=("_genNetwork");		fnDescs+=("reset docker")
fnNames+=("_genWipe");			fnDescs+=("remove persistent data")
fnNames+=("_genTemplates");		fnDescs+=("process templates")
fnNames+=("_genTempRegistry");	fnDescs+=("populate docker registry")
fnNames+=("_genRegistry");		fnDescs+=("setup registry")
fnNames+=("_genDb");			fnDescs+=("bootstrap db")
fnNames+=("_genMq");			fnDescs+=("bootstrap mq")
fnNames+=("_genCdc");			fnDescs+=("bootstrap cdc")

# coose what to skip
export GUM_CHOOSE_SELECTED=$( commonJoinArray %s, , "${fnDescs[@]}" )
gumSelected=$(	\
	gum choose	\
	--no-limit	\
	--ordered	\
	--header="${COMMON_PREFIX}everything is running by default, select what you want to skip:" \
	"${fnDescs[@]}"	\
)
unset GUM_CHOOSE_SELECTED

# list with selected items
declare -a gumSelectedArray=()
while IFS= read -r line; do
	if [ -n "$line" ]; then
		gumSelectedArray+=("$line")
	fi
done <<< "$gumSelected"

# show what will be skipped
declare -a gumUnselected=()
if [ ${#gumSelectedArray[@]} -eq ${#fnDescs[@]} ]; then
	commonPrintf "nothing will be skipped"
else
	for skipped in "${fnDescs[@]}"; do
		if ! echo "${gumSelectedArray[@]}" | grep -q "\<$skipped\>"; then
			gumUnselected+=("$skipped")
			commonPrintf "\"$skipped\" will be skipped"
		fi
	done
fi

# endregion: what to skip
# region: exec

for i in $(seq 0 $((${#fnDescs[@]} - 1))); do
	found=false
	for skip in "${gumUnselected[@]}"; do
		if [ "$skip" = "${fnDescs[i]}" ]; then
			found=true
			break
		fi
	done

	if [ "$found" = true ]; then
		commonPrintf "\"${fnDescs[i]}\" phase will be skipped"
	else
		commonPrintf "entering \"${fnDescs[i]}\" phase"
		${fnNames[i]}
		commonVerify $? "${fnNames[i]} is failed" "${fnNames[i]} is succeeded" 
	fi
done

# endregion: exec

# endregion: switchboard
# region: closing provisions

gum style  'ALL DONE!' 'IF THIS IS FINAL, ISSUE THE FOLLOWING COMMAND:' "sudo chmod a-x ${WMS_PATH_SCRIPTS}/genesis.sh"

# endregion: closing
