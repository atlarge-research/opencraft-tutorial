#!/usr/bin/env bash

set -euo pipefail

set +u
source ~/.bashrc
set -u

echo "Creating directories for Dyconit experiments..."
EXPERIMENT_PATH=/var/scratch/`whoami`/opencraft-tutorial/opencraft-experiments/dyconit-experiment
EXPERIMENT_RESOURCES_PATH=${EXPERIMENT_PATH}/resources

mkdir -p $EXPERIMENT_RESOURCES_PATH
EXPERIMENT_FIGURES_PATH=${EXPERIMENT_PATH}/figures
mkdir -p $EXPERIMENT_FIGURES_PATH

function downloadResource {
    DOWNLOAD_URL=$1
    OUTPUT=${2-""}

    mkdir -p ${EXPERIMENT_PATH}/resources
    cd ${EXPERIMENT_PATH}/resources
    if [ -n "$OUTPUT" ]; then
        OPTS="--create-dirs -o $OUTPUT"
    else
        OPTS="-O"
    fi
    curl -sSL -X GET $DOWNLOAD_URL $OPTS
    cd - > /dev/null
}

NEXUS_DOWNLOAD_URL=https://opencraft-vm.labs.vu.nl/nexus/service/rest/v1/search/assets/download

EXPERIMENT_URL=https://raw.githubusercontent.com/atlarge-research/opencraft-tutorial/main/exercises/dyconits
CONFIG_URL=${EXPERIMENT_URL}/configs
SCRIPTS_URL=${EXPERIMENT_URL}/scripts

echo "Downloading Opencraft..."
downloadResource "${NEXUS_DOWNLOAD_URL}?repository=opencraft-group&group=science.atlarge.opencraft&name=opencraft&sort=version&maven.extension=jar&version=1.1.4-20201109.150326-6" opencraft.jar
downloadResource ${CONFIG_URL}/opencraft-dyconits-zero.yml ../policy-zero/resources/config/opencraft.yml

echo "Downloading Yardstick..."
downloadResource "${NEXUS_DOWNLOAD_URL}?repository=opencraft-releases&group=nl.tudelft&name=yardstick&sort=version&maven.extension=jar" yardstick.jar
downloadResource ${CONFIG_URL}/yardstick.toml

echo "Downloading Pecosa..."
downloadResource https://raw.githubusercontent.com/jdonkervliet/pecosa/main/pecosa.py

echo "Downloading experiment configuration..."
downloadResource ${CONFIG_URL}/experiment-config.toml

echo "Downloading plot script..."
curl -sSL ${SCRIPTS_URL}/plot-network.py -o ${EXPERIMENT_FIGURES_PATH}/plot-network.py

echo "Dyconit experiment setup complete."
