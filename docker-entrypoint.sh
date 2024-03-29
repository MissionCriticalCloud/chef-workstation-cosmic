#!/bin/bash
set -e

# Setup shell and print Chef Workstation component versions
eval "$(/opt/chef-workstation/bin/chef shell-init bash)"
chef -v && echo

# Load git private key if one is provided
if [ -n "${GIT_PRIVATE_KEY}" ]; then
    mkdir -p ~/.ssh && echo -e "Host *\\n\\tStrictHostKeyChecking no\\n" > ~/.ssh/config

    echo "Setting up SSH Agent..."
    eval "$(ssh-agent -s)" > /dev/null
    echo "Adding private key..."
    ssh-add <(echo "${GIT_PRIVATE_KEY}")
    echo
fi

# Fetch chef config repository if one is provided
if [ -n "${CHEF_REPO}" ] && [ -n "${GIT_PRIVATE_KEY}" ]; then
    echo "Fetching Chef config from ${CHEF_REPO}..."
    rm -rf ~/.chef && git clone -q "${CHEF_REPO}" ~/.chef
    echo
fi

# Add a Chef user PEM if one is provided
if [ -n "${CHEF_PEM}" ] && [ -n "${CHEF_REPO}" ] && [ -n "${CHEF_USER}" ]; then
    echo "Writing Chef PEM for ${CHEF_USER}..."
    echo "${CHEF_PEM}" > "${HOME}/.chef/${CHEF_USER}.pem"
    echo
fi

exec "$@"
