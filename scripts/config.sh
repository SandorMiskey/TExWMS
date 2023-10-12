#!/bin/bash

#
# Copyright TE-FOOD International GmbH., All Rights Reserved
#

# region: load .env if any

[[ -f .env ]] && source .env

# endregion: .env
# region: base paths

# get them from .env 
export PATH_BASE=$PATH_BASE
export PATH_RC=$PATH_RC

# dirs under base
export PATH_BIN=${PATH_BASE}/bin
export PATH_SCRIPTS=${PATH_BASE}/scripts
export PATH_TEMPLATES=${PATH_BASE}/templates
export PATH_LOCALWORKBENCH=${PATH_BASE}/workbench

# wms independent common functions
export PATH_COMMON=${PATH_SCRIPTS}/common.sh

# add scripts and bins to PATH
export PATH=${PATH_BIN}:${PATH_SCRIPTS}:$PATH

# dirs under workbench
export PATH_WORKBENCH=/srv/TExWMS
export PATH_REGISTRY=${PATH_WORKBENCH}/registry
export PATH_DB=${PATH_WORKBENCH}/db
export PATH_STACK=${PATH_WORKBENCH}/docker-compose.yaml

# endregion: base paths
# region: exec control

export EXEC_DRY=false
export EXEC_FORCE=false
export EXEC_SURE=false
export EXEC_PANIC=true
export EXEC_SILENT=false
export EXEC_VERBOSE=true

# endregion: exec contorl
# region: versions and deps

# export TC_DEPS_CA=1.5.6
# export TC_DEPS_FABRIC=2.5.4
# export TC_DEPS_COUCHDB=3.3.1
# export TC_DEPS_BINS=('awk' 'bash' 'curl' 'git' 'go' 'jq' 'configtxgen' 'yq')

# endregion: versions and deps
# region: docker

# network maybe
export DOCKER_STACK=$PATH_STACK
export DOCKER_DELAY=10
export DOCKER_REGISTRY_PORT=6000
export DOCKER_REGISTRY_HOST=localhost

# images
# export TC_SWARM_IMG_COUCHDB=${TC_SWARM_MANAGER1[node]}:${TC_SWARM_IMG_PORT}/trustchain-couchdb
# export TC_SWARM_IMG_VISUALIZER=${TC_SWARM_MANAGER1[node]}:${TC_SWARM_IMG_PORT}/trustchain-visualizer
# export TC_SWARM_IMG_LOGSPOUT=${TC_SWARM_MANAGER1[node]}:${TC_SWARM_IMG_PORT}/trustchain-logspout
# export TC_SWARM_IMG_PROMETHEUS=${TC_SWARM_MANAGER1[node]}:${TC_SWARM_IMG_PORT}/trustchain-prometheus
# export TC_SWARM_IMG_CADVISOR=${TC_SWARM_MANAGER1[node]}:${TC_SWARM_IMG_PORT}/trustchain-cadvisor
# export TC_SWARM_IMG_NODEEXPORTER=${TC_SWARM_MANAGER1[node]}:${TC_SWARM_IMG_PORT}/trustchain-node-exporter
# export TC_SWARM_IMG_GRAFANA=${TC_SWARM_MANAGER1[node]}:${TC_SWARM_IMG_PORT}/trustchain-grafana
# export TC_SWARM_IMG_BUSYBOX=${TC_SWARM_MANAGER1[node]}:${TC_SWARM_IMG_PORT}/trustchain-busybox
# export TC_SWARM_IMG_NETSHOOT=${TC_SWARM_MANAGER1[node]}:${TC_SWARM_IMG_PORT}/trustchain-netshoot
# export TC_SWARM_IMG_PORTAINERAGENT=${TC_SWARM_MANAGER1[node]}:${TC_SWARM_IMG_PORT}/trustchain-portainer-agent
# export TC_SWARM_IMG_PORTAINER=${TC_SWARM_MANAGER1[node]}:${TC_SWARM_IMG_PORT}/trustchain-portainer

# endregion: swarm
# region: services: registry

# export TC_COMMON1_STACK=infra
# export TC_COMMON1_DOMAIN=${TC_COMMON1_STACK}.${TC_NETWORK_DOMAIN}

# export TC_COMMON1_REGISTRY_NAME=registriy
# export TC_COMMON1_REGISTRY_FQDN=${TC_COMMON1_REGISTRY_NAME}.${TC_COMMON1_DOMAIN}
# export TC_COMMON1_REGISTRY_PORT=$TC_SWARM_IMG_PORT
# export TC_COMMON1_REGISTRY_DATA=${TC_PATH_WORKBENCH_COMMON}/${TC_COMMON1_REGISTRY_NAME}
# export TC_COMMON1_REGISTRY_WORKER=${TC_SWARM_MANAGER1[node]}

# endregion: registry
# region: mgmt and metrics

	# region: COMMON2

	# export TC_COMMON2_STACK=metrics
	# export TC_COMMOM2_DATA=${TC_PATH_WORKBENCH_COMMON}
	# export TC_COMMON2_UID=$( id -u )
	# export TC_COMMON2_GID=$( id -g )
	
	# export TC_COMMON2_S1_NAME=visualizer

	# export TC_COMMON2_S1_PORT=5021
	# export TC_COMMON2_S2_NAME=logspout
	# export TC_COMMON2_S2_PORT=5022

	# export TC_COMMON2_S3_NAME=prometheus
	# export TC_COMMON2_S3_DATA=${TC_COMMOM2_DATA}/${TC_COMMON2_S3_NAME}
	# export TC_COMMON2_S3_PORT=5023
	# export TC_COMMON2_S3_WORKER=${TC_SWARM_MANAGER1[node]}
	# export TC_COMMON2_S3_PW=$TC_COMMON2_S3_PW

	# export TC_COMMON2_S4_NAME=cadvisor
	# export TC_COMMON2_S4_PORT=5024
	# export TC_COMMON2_S4_WORKER=${TC_SWARM_MANAGER1[node]}

	# export TC_COMMON2_S5_NAME=node-exporter
	# export TC_COMMON2_S5_PORT=5025
	# export TC_COMMON2_S5_WORKER=${TC_SWARM_MANAGER1[node]}

	# export TC_COMMON2_S6_NAME=grafana
	# export TC_COMMON2_S6_PORT=5026
	# export TC_COMMON2_S6_WORKER=${TC_SWARM_MANAGER1[node]}
	# export TC_COMMON2_S6_DATA=${TC_COMMOM2_DATA}/${TC_COMMON2_S6_NAME}
	# export TC_COMMON2_S6_PW=$TC_COMMON2_S6_PW
	# export TC_COMMON2_S6_INT=15

	# endregion: COMMON2
	# region: COMMON3

	# export TC_COMMON3_STACK=mgmt
	# export TC_COMMOM3_DATA=${TC_PATH_WORKBENCH_COMMON}
	# export TC_COMMON3_WORKER=${TC_SWARM_MANAGER1[node]}

	# export TC_COMMON3_S1_NAME=busybox
	# export TC_COMMON3_S1_WORKER=${TC_SWARM_MANAGER1[node]}

	# export TC_COMMON3_S2_NAME=netshoot
	# export TC_COMMON3_S2_WORKER=${TC_SWARM_MANAGER1[node]}

	# export TC_COMMON3_S3_NAME=portainer-agent

	# export TC_COMMON3_S4_NAME=portainer
	# export TC_COMMON3_S4_PORT=5034
	# export TC_COMMON3_S4_PW=$TC_COMMON3_S4_PW
	# export TC_COMMON3_S4_DATA=${TC_COMMOM3_DATA}/${TC_COMMON3_S4_NAME}

	# endregion: COMMON3

# endregion: mgmt and metrics
# region: common funcs

[[ -f "$PATH_COMMON" ]] && source "$PATH_COMMON"
[[ -f "$COMMON_FUNCS" ]] && source "$COMMON_FUNCS"

export COMMON_FORCE=$EXEC_FORCE
export COMMON_PANIC=$EXEC_PANIC
export COMMON_PREREQS=("${DEPS_BINS[@]}")
export COMMON_SILENT=$EXEC_SILENT
export COMMON_VERBOSE=$EXEC_VERBOSE

# endregion: common funcs
# region: load .env if any

[[ -f .env ]] && source .env

# endregion: .env
