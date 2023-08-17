#!/usr/bin/env bash

set -ue -o pipefail

USER="ubuntu"
USER_HOME="/home/${USER}"

sudo -u ${USER} mkdir -p ${USER_HOME}/.local/bin
export PATH="${USER_HOME}/.local/bin:${PATH}"

apt update && apt upgrade -y
apt install -y \
    git \
    curl \
    wget \
    zip \
    unzip \
    emacs-nox \
    less \
    software-properties-common \
    python3-pip \
    python3-testresources # for launchpadlib; see https://www.discoverbits.in/864/error-launchpadlib-requires-testresources-which-installed

PYTHON_VERSION="3.10"
PYTHON="python${PYTHON_VERSION}"
PIP="pip${PYTHON_VERSION}"
add-apt-repository -y ppa:deadsnakes/ppa
apt install -y ${PYTHON} ${PYTHON}-dev ${PYTHON}-venv
sudo -u ${USER} ${PYTHON} -m pip install pipenv poethepoet
curl -sSL https://install.python-poetry.org | sudo -u ${USER} ${PYTHON} -
