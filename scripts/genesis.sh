#!/bin/bash

#
# Copyright TE-FOOD International GmbH., All Rights Reserved
#

# region: load config

[[ ${PATH_RC:-"unset"} == "unset" ]] && PATH_RC=${PATH_BASE}/scripts/commonFuncs.sh
if [ ! -f  $PATH_RC ]; then
	echo "=> PATH_RC ($PATH_RC) not found, make sure proper path is set or you execute this from the repo's 'scrips' directory!"
	exit 1
fi
source $PATH_RC

# commonPrintfBold "note that certain environment variables must be set to work properly!"
# commonContinue "have you reloded ${PATH_BASE}/.env?"

if [[ ${PATH_SCRIPTS:-"unset"} == "unset" ]]; then
	commonVerify 1 "PATH_SCRIPTS is unset"
fi
commonPP $PATH_SCRIPTS

# endregion: config
# region: strartup warning

commonPrintfBold " "
commonPrintfBold "THIS SCRIPT CAN BE DESTRUCTIVE, IT SHOULD BE RUN WITH SPECIAL CARE ON THE MAIN MANAGER NODE"
commonPrintfBold " "
force=$COMMON_FORCE
COMMON_FORCE=$EXEC_SURE
commonContinue "do you want to continue?"
COMMON_FORCE=$force
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

commonYN "search for dependencies?" commonDeps ${COMMON_PREREQS[@]}
# commonYN "validate ca binary versions?" _CAVersions

# endregion: dependencies and versions
# region: remove config and persistent data

_WipePersistent() {

	_wipe() {
		# making sure all docker services are stopped
		# docker service ls --format '{{.ID}}' | xargs -I {} docker service rm {}

		# purge or create workbench
		if [ -d "$PATH_WORKBENCH" ]; then
			commonPrintf "$PATH_WORKBENCH exists"
			commonPrintf "removing ${PATH_WORKBENCH}/*"
			# err=$( sudo rm -rf "${PATH_WORKBENCH}/*" )
			err=$( sudo find "$PATH_WORKBENCH" -mindepth 1 -delete )
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
		err=$( sudo chgrp $grp "$PATH_WORKBENCH" )
		commonVerify $? $err
		err=$( sudo chmod g+rwx "$PATH_WORKBENCH" )
		commonVerify $? $err

		# remove localworkbench -> workbench symlink
		local localworkbench=$(realpath "$PATH_LOCALWORKBENCH")
		local workbench=$(realpath "$PATH_WORKBENCH")
		if [ "$localworkbench" = "$workbench" ]; then
			commonPrintf "\$PATH_LOCALWORKBENCH and \$PATH_WORKBENCH variables point to the same directory, it is not necessary to deal with any symlink"
		else
			commonPrintf "removing $PATH_LOCALWORKBENCH symlink to $PATH_WORKBENCH"
			err=$( sudo rm -f "$PATH_LOCALWORKBENCH" )
			commonVerify $? $err
			commonPrintf "symlink $PATH_LOCALWORKBENCH -> $PATH_WORKBENCH"
			err=$( ln -s "$PATH_WORKBENCH" "$PATH_LOCALWORKBENCH" )
			commonVerify $? $err
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

[[ "$EXEC_DRY" == false ]] && commonYN "wipe persistent data?" _WipePersistent

# endregion: remove config and persistent data
# region: process templates

_templates() {
	commonPrintf " "
	commonPrintf "processing templates:"
	commonPrintf " "
	for template in $( find $PATH_TEMPLATES/* ! -name '.*' -print ); do
		target=$( commonSetvar $template )
		target=$( echo $target | sed s+$PATH_TEMPLATES+$PATH_WORKBENCH+ )

		local templateRel=$( echo "$template" | sed s+${PATH_BASE}/++g )
		local targetRel=$( echo "$target" | sed s+${PATH_BASE}/++g | sed s+_nope$++g )
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

[[ "$EXEC_DRY" == false ]] && commonYN "process templates?" _templates 

# endregion: process templates
# region: bootstrap

	# _bootstrapCommon2() {
	# 	commonPrintf "bootstrapping >>>${TC_COMMON2_STACK}<<<"
	# 	${TC_PATH_SCRIPTS}/tcBootstrap.sh -m up -s ${TC_COMMON2_STACK}
	# 	commonVerify $? "failed!"
	# }
	# commonYN "bootstrap ${TC_COMMON2_STACK}?" _bootstrapCommon2

# endregion: bootstrap
# region: closing provisions

_prefix="$COMMON_PREFIX"
COMMON_PREFIX="===>>> "
commonPrintfBold " "
commonPrintfBold "ALL DONE! IF THIS IS FINAL, ISSUE THE FOLLOWING COMMAND: sudo chmod a-x ${PATH_SCRIPTS}/genesis.sh"
commonPrintfBold " "
COMMON_PREFIX="_prefix"
unset _prefix

# endregion: closing
