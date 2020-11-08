#!/usr/bin/env bash

set -euo pipefail

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
    cd -
}

echo "Installing OpenCraft Deployer (ocd)..."
BIN_DIR="/home/`whoami`/.local/bin"
mkdir -p $BIN_DIR
curl -sSL https://raw.githubusercontent.com/atlarge-research/opencraft-deploy-das5/master/ocd.py -o ${BIN_DIR}/ocd.py
EXE="/ocd"
ln -s ${EXE}.py $EXE
chmod +x $EXE
echo "PATH=$EXE:\$PATH" >> ~/.bashrc
source ~/bashrc

echo "Creating directories for Opencraft experiments..."
EXPERIMENT_PATH=/var/scratch/`whoami`/opencraft-tutorial/opencraft-experiments/2020/first-experiment
EXPERIMENT_RESOURCES_PATH=${EXPERIMENT_PATH}/resources
mkdir -p $EXPERIMENT_RESOURCES_PATH
EXPERIMENT_FIGURES_PATH=${EXPERIMENT_PATH}/figures
mkdir -p $EXPERIMENT_FIGURES_PATH

NEXUS_DOWNLOAD_URL=https://opencraft-vm.labs.vu.nl/nexus/service/rest/v1/search/assets/download

echo "Downloading Opencraft..."
downloadResource ${NEXUS_DOWNLOAD_URL}?repository=opencraft-group&group=science.atlarge.opencraft&name=opencraft&sort=version&maven.extension=jar
downloadResource https://raw.githubusercontent.com/atlarge-research/opencraft-tutorial/main/configs/opencraft-dyconits-chunk.yml ../policy-chunk/resources/config/opencraft.yml
downloadResource https://raw.githubusercontent.com/atlarge-research/opencraft-tutorial/main/configs/opencraft-dyconits-zero.yml ../policy-zero/resources/config/opencraft.yml

echo "Downloading Yardstick..."
downloadResource ${NEXUS_DOWNLOAD_URL}?repository=opencraft-group&group=nl.tudelft&name=yardstick&sort=version&maven.extension=jar
downloadResource https://raw.githubusercontent.com/atlarge-research/opencraft-tutorial/main/configs/yardstick.toml

echo "Downloading Pecosa..."
downloadResource https://raw.githubusercontent.com/jdonkervliet/pecosa/main/pecosa.py

echo "Downloading experiment configuration..."
downloadResource https://raw.githubusercontent.com/atlarge-research/opencraft-tutorial/main/configs/experiment-config.toml

echo "Downloading plot script..."
curl -sSL https://raw.githubusercontent.com/atlarge-research/opencraft-tutorial/main/scripts/plot-network.py -o ${EXPERIMENT_FIGURES_PATH}/plot-network.py

echo "Opencraft setup complete."
echo "Test that your setup was successful by running 'ocd --help'."
