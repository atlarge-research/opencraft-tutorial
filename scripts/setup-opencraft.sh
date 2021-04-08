#!/usr/bin/env bash

set -euo pipefail

echo "Installing OpenCraft Deployer (ocd)..."
BIN_DIR="/home/`whoami`/.local/bin"
mkdir -p $BIN_DIR
EXE="${BIN_DIR}/ocd"

if [ ! -f "$EXE" ]; then
    curl -sSL https://raw.githubusercontent.com/atlarge-research/opencraft-deploy-das5/develop/ocd.py -o ${BIN_DIR}/ocd.py
    ln -s ${EXE}.py $EXE

    chmod +x $EXE

    echo "module load prun" >> ~/.bashrc
    echo "PATH=$EXE:\$PATH" >> ~/.bashrc
fi

echo "Test that your Opencraft Deployer setup was successful by running 'ocd --help'."
