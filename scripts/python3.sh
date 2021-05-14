#!/bin/bash

# Install Pyenv on RHEL 8
# https://www.mpietruszka.com/install-pyenv-ce-rhel8.html

sudo dnf install -y \
        make \
        gcc \
        zlib-devel \
        bzip2 \
        bzip2-devel \
        readline-devel \
        sqlite \
        sqlite-devel \
        openssl-devel \
        tk-devel \
        libffi-devel \
        git
git clone https://github.com/pyenv/pyenv.git ~/.pyenv

# echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.bash_profile
# echo 'export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.bash_profile
# echo -e 'if command -v pyenv 1>/dev/null 2>&1; then\n eval "$(pyenv init -)"\nfi' >> ~/.bash_profile
# source ~/.bash_profile

export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init --path)"

# Install python
pyenv install 3.8.2
pyenv global 3.8.2

# Install fake-switches 
pip install --upgrade pip
pip install cryptography==3.0
pip install fake-switches

# Run fake-switches
#fake-switches --listen-host localhost --listen-port 3080
