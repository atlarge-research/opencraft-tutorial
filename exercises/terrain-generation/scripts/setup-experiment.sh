#!/usr/bin/env bash

set -euo pipefail

set +u
source ~/.bashrc
set -u

echo "Creating directories for terrain generation experiments..."
EXPERIMENT_PATH=/var/scratch/`whoami`/opencraft-tutorial/opencraft-experiments/terrain-generation-experiment
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

EXPERIMENT_URL=https://raw.githubusercontent.com/atlarge-research/opencraft-tutorial/main/exercises/terrain-generation
CONFIG_URL=${EXPERIMENT_URL}/configs
SCRIPTS_URL=${EXPERIMENT_URL}/scripts

echo "Downloading Opencraft..."
downloadResource "${NEXUS_DOWNLOAD_URL}/science/atlarge/opencraft/opencraft/1.1.4-serverless-terrain-generation-SNAPSHOT/opencraft-1.1.4-serverless-terrain-generation-20210407.183614-2.jar" opencraft.jar
downloadResource ${CONFIG_URL}/opencraft-local-generation.yml ../local-generation/resources/config/opencraft.yml

echo "Downloading Yardstick..."
downloadResource "${NEXUS_DOWNLOAD_URL}/nl/tudelft/yardstick/1.0.2-serverless-terrain-generation-SNAPSHOT/yardstick-1.0.2-serverless-terrain-generation-20210406.121248-1.jar" yardstick.jar
downloadResource ${CONFIG_URL}/yardstick.toml

echo "Downloading Pecosa..."
downloadResource https://raw.githubusercontent.com/jdonkervliet/pecosa/main/pecosa.py

echo "Downloading experiment configuration..."
downloadResource ${CONFIG_URL}/experiment-config.toml

echo "Downloading plot script..."
curl -sSL ${SCRIPTS_URL}/plot-network.py -o ${EXPERIMENT_FIGURES_PATH}/plot-network.py

echo "Setting up AWS Lambda configuration"
echo "export LAMBDA_REGION=eu-central-1" >> ~/.bashrc
echo "export LAMBDA_FUNCTION=NaivePopulator" >> ~/.bashrc
echo "export LAMBDA_ACCESS_KEY=SET KEY HERE" >> ~/.bashrc
echo "export LAMBDA_SECRET_KEY=SET KEY HERE" >> ~/.bashrc

echo "Terrain generation experiment setup complete."
echo "Please set the AWS Lambda Access Key and Secret Key in .bashrc, and run 'source ~/.bashrc' before continuing."

