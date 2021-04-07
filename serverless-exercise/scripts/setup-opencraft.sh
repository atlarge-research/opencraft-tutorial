#!/usr/bin/env bash

set -euo pipefail

echo "Installing OpenCraft Deployer (ocd)..."
BIN_DIR="/home/`whoami`/.local/bin"
mkdir -p $BIN_DIR
EXE="${BIN_DIR}/ocd"

curl -sSL https://raw.githubusercontent.com/atlarge-research/opencraft-deploy-das5/develop/ocd.py -o ${BIN_DIR}/ocd.py
if [ ! -f "$EXE.py" ]; then
    ln -s ${EXE}.py $EXE
fi

chmod +x $EXE

echo "module load prun" >> ~/.bashrc
echo "PATH=$EXE:\$PATH" >> ~/.bashrc

set +u
source ~/.bashrc
set -u

echo "Creating directories for Opencraft experiments..."
EXPERIMENT_PATH=/var/scratch/`whoami`/opencraft-tutorial/opencraft-experiments/2021/serverless-experiment
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

NEXUS_DOWNLOAD_URL=https://opencraft-vm.labs.vu.nl/nexus/repository/opencraft-snapshots
echo "Downloading Opencraft..."
downloadResource "${NEXUS_DOWNLOAD_URL}/science/atlarge/opencraft/opencraft/1.1.4-serverless-terrain-generation-SNAPSHOT/opencraft-1.1.4-serverless-terrain-generation-20210406.142649-1.jar" opencraft.jar
downloadResource https://raw.githubusercontent.com/atlarge-research/opencraft-tutorial/serverless-terrain-generation/serverless-exercise/configs/opencraft-local-generation.yml ../local-generation/resources/config/opencraft.yml

https://opencraft-vm.labs.vu.nl/nexus/repository/opencraft-snapshots/echo "Downloading Yardstick"
downloadResource "${NEXUS_DOWNLOAD_URL}/nl/tudelft/yardstick/1.0.2-serverless-terrain-generation-SNAPSHOT/yardstick-1.0.2-serverless-terrain-generation-20210406.121248-1.jar" yardstick.jar
downloadResource https://raw.githubusercontent.com/atlarge-research/opencraft-tutorial/serverless-terrain-generation/serverless-exercise/configs/yardstick.toml

echo "Downloading Pecosa..."
downloadResource https://raw.githubusercontent.com/jdonkervliet/pecohttps://raw.githubusercontent.com/atlarge-research/opencraft-tutorial/serverless-terrain-generation/configs/experiment-config.tomlsa/main/pecosa.py

echo "Downloading experiment configuration..."
downloadResource https://raw.githubusercontent.com/atlarge-research/opencraft-tutorial/serverless-terrain-generation/serverless-exercise/configs/experiment-config.toml

echo "Downloading plot script..."
curl -sSL https://raw.githubusercontent.com/atlarge-research/opencraft-tutorial/serverless-terrain-generation/serverless-exercise/scripts/plot-network.py -o ${EXPERIMENT_FIGURES_PATH}/plot-network.py

echo "Opencraft setup complete."
echo "Test that your setup was successful by running 'ocd --help'."
