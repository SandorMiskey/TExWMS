#!/bin/bash

#
# Copyright TE-FOOD International GmbH., All Rights Reserved
#

# region: load .env if any

[[ -f .env ]] && source .env

# endregion: .env
# region: base paths

# get them from .env 
export WMS_PATH_BASE=$WMS_PATH_BASE
export WMS_PATH_RC=$WMS_PATH_RC

# dirs under base
export WMS_PATH_BIN=${WMS_PATH_BASE}/bin
export WMS_PATH_SCRIPTS=${WMS_PATH_BASE}/scripts
export WMS_PATH_TEMPLATES=${WMS_PATH_BASE}/templates
export WMS_PATH_LOCALWORKBENCH=${WMS_PATH_BASE}/workbench

# wms independent common functions
export WMS_PATH_COMMON=${WMS_PATH_SCRIPTS}/common.sh

# add scripts and bins to PATH
export PATH=${WMS_PATH_BIN}:${WMS_PATH_SCRIPTS}:$PATH

# dirs under workbench
export WMS_PATH_WORKBENCH=/srv/TExWMS
export WMS_PATH_REGISTRY=${WMS_PATH_WORKBENCH}/registry
export WMS_PATH_DB=${WMS_PATH_WORKBENCH}/db
export WMS_PATH_STACKS=${WMS_PATH_WORKBENCH}/stacks

# endregion: base paths
# region: exec control

export WMS_EXEC_DRY=false
export WMS_EXEC_FORCE=false
export WMS_EXEC_SURE=false
export WMS_EXEC_PANIC=true
export WMS_EXEC_SILENT=false
export WMS_EXEC_VERBOSE=true

# endregion: exec contorl
# region: versions and deps

export WMS_DEPS_BINS=('bash' 'docker' 'docker-compose')

export WMS_DEPS_DB=mariadb:10.11.5
export WMS_DEPS_ADMINER=adminer:4.8.1
export WMS_DEPS_CDC=zendesk/maxwell:v1.40.5

# endregion: versions and deps
# region: docker

export WMS_DOCKER_DELAY=5
export WMS_DOCKER_NET=wms
export WMS_DOCKER_INIT="--attachable --driver bridge --subnet 10.96.0.0/24 $WMS_DOCKER_NET"
export WMS_DOCKER_DOMAIN=test.te-food.com
export WMS_DOCKER_REGISTRY_PORT=6000
export WMS_DOCKER_REGISTRY_HOST=localhost
export WMS_DOCKER_STACKS=$WMS_PATH_STACKS

# endregion: docker
# region: stacks

# region: registry 

export WMS_STACK1_NAME=registry
export WMS_STACK1_IMG=registry:2
export WMS_STACK1_CFG=${WMS_DOCKER_STACKS}/00_${WMS_STACK1_NAME}.yaml
export WMS_STACK1_FQDN=${WMS_STACK1_NAME}.${WMS_DOCKER_DOMAIN}
export WMS_STACK1_PORT=$WMS_DOCKER_REGISTRY_PORT
export WMS_STACK1_DATA=${WMS_PATH_WORKBENCH}/${WMS_STACK1_NAME}
export WMS_STACK1_IMAGES=("$WMS_DEPS_DB" "$WMS_DEPS_ADMINER" "$WMS_DEPS_CDC")

# endregion: registry
# region: db

export WMS_DOCKER_IMG_DB=${WMS_DOCKER_REGISTRY_HOST}:${WMS_DOCKER_REGISTRY_PORT}/${WMS_DEPS_DB}
export WMS_DOCKER_IMG_ADMINER=${WMS_DOCKER_REGISTRY_HOST}:${WMS_DOCKER_REGISTRY_PORT}/${WMS_DEPS_ADMINER}

# endregion: db
# region: cdc

export WMS_DOCKER_IMG_MAXWELL=${WMS_DOCKER_REGISTRY_HOST}:${WMS_DOCKER_REGISTRY_PORT}/${WMS_DEPS_MAXWELL}

# endregion: cdc
# region: ???

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

# endregion: ???

# endregion: stacks
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

[[ -f "$WMS_PATH_COMMON" ]] && source "$WMS_PATH_COMMON"
[[ -f "$COMMON_FUNCS" ]] && source "$COMMON_FUNCS"

export COMMON_FORCE=$WMS_EXEC_FORCE
export COMMON_PANIC=$WMS_EXEC_PANIC
export COMMON_PREREQS=("${WMS_DEPS_BINS[@]}")
export COMMON_SILENT=$WMS_EXEC_SILENT
export COMMON_VERBOSE=$WMS_EXEC_VERBOSE

# endregion: common funcs
# region: load .env if any

[[ -f .env ]] && source .env

# endregion: .env
