#!/usr/bin/env bash

set -xeuo pipefail
IFS=$'\n\t'

# if ! (git status && [[ -z "$(git status --porcelain)" ]]); then
#     echo "experiment not running due to uncommitted git changes"
#     exit 1
# fi

if ! which conda; then
    read -r -p "Conda not found. About to install conda in /var/scratch/$(whoami)/miniconda3. Do you want to continue? [yn] " yn
    case $yn in
    [Yy])
        mkdir -p ~/miniconda3
        wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/miniconda3/miniconda.sh
        bash ~/miniconda3/miniconda.sh -b -u -p "/var/scratch/$(whoami)/miniconda3"
        rm -rf ~/miniconda3/miniconda.sh
        set +u
        source "/var/scratch/$(whoami)/miniconda3/bin/activate"
        conda init bash
        set -u
        ;;
    *)
        exit
        ;;
    esac
fi

env_name="$(head -n 1 environment.yml | cut -d':' -f 2 | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"

if ! conda env list | grep -q -E "^$env_name\s+"; then
    read -r -p "Conda environment not found. About to create an environment with name '$env_name'. Do you want to continue? [yn] " yn
    case $yn in
    [Yy])
        conda env create --file environment.yml
        ;;
    *)
        exit
        ;;
    esac
fi

set +u
set +x
eval "$(conda shell.bash hook)"
conda activate "$env_name"
set -x
set -u

if ! conda compare environment.yml; then
    conda env create -q --file environment.yml --force
fi
conda init bash

ansible-playbook -e @experiment.yml -i 'localhost' before.yml
configs=$(python confex.py experiment.yml)
for c in $configs; do
    ansible-playbook -e @"$c" -e "_config_path=$c" -e @experiment.yml -i 'localhost' run_all.yml
done
ansible-playbook -e @experiment.yml -i 'localhost' after.yml
