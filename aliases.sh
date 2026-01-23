#!/bin/bash

# Containerized Ansible Convenience Functions
# Set ANSIBLE_VERSION before sourcing, or it defaults to 2.18.7
# 
# Usage:
# export ANSIBLE_VERSION=2.17.0
# source ./aliases.sh

ANSIBLE_VERSION=${ANSIBLE_VERSION:-2.20.1}

ansible-role-init() {
    if [ -z "$1" ]; then
        echo "Usage: ansible-role-init <role-name>"
        return 1
    fi
    docker run -it --rm -v $(pwd):/workspace -w /workspace containerized-ansible:${ANSIBLE_VERSION} ansible-galaxy role init "$1"
}

ansible-playbook-init() {
    if [ -z "$1" ]; then
        echo "Usage: ansible-playbook-init <project-directory>"
        return 1
    fi
    docker run -it --rm -v $(pwd):/workspace -w /workspace containerized-ansible:${ANSIBLE_VERSION} /ansible/scripts/bootstrap-playbook.sh "$1"
}

# Show available functions
ansible-help() {
    echo "Available containerized-ansible functions (using version ${ANSIBLE_VERSION}):"
    echo "  ansible-role-init <role-name>           - Initialize a new Ansible role"
    echo "  ansible-playbook-init <project-name>    - Initialize a new Ansible playbook project"
    echo "  ansible-help                            - Show this help message"
}