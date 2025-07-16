# Containerized Ansible

Rather than maintaining dependencies in your local environment, use this purpose-built Ansible container that:

- Can be run with a single command
- Mounts local playbooks/inventory for execution
- Provides a consistent environment for Ansible operations

## Quick Start

### Prerequisites

1. Docker

Utilize the makefile to build the latest version (as indicated by the `ansible-version.json` file in the root of this repository):

```
make build 
```

To download a specific version of Ansible: 

```
make build ANSIBLE_VERSION=2.18.4
```

This will result in a local image called `containerized-ansible` with an image tag corresponding to the version of Ansible you specified. If a version was not specified, then the tag will correspond to the version found in the `ansible-version.json` file.

### Verify the Image

```
docker run --rm containerized-ansible:2.18.4 ansible --version
```

this should return valid ansible output corresponding to the specified version.

### Using Published Images

This repository also publishes images to my [ghcr.io](https://github.com/andygodish/containerized-ansible/pkgs/container/containerized-ansible) registry. Pull an image from the remote registry like so:

```
docker pull ghcr.io/andygodish/containerized-ansible:latest
```


## Necessary System Packages

```
# Dockerfile 

RUN apk add --no-cache openssh-client
```

### openssh-client

**Purpose**: This package provides essential SSH client functionality for Ansible to connect to remote hosts.

**How it's used**:

Ansible uses SSH as its default connection method to remote machines
The SSH client executables (ssh, scp, ssh-keygen, etc.) enable Ansible to:

Without this package: Ansible would fail to establish SSH connections to remote hosts, which would prevent most playbooks from executing since they require remote access.

## Volume Mounting

```
# Dockerfile

RUN mkdir -p /ansible/playbooks /ansible/inventory /ansible/vars /ansible/vault \
    /ansible/roles /ansible/collections \
    && chown -R nonroot:nonroot /ansible
```

The `nonroot` user is only given adequate permissions to the `/ansible` directory. You will need to mount your local playbooks, inventory, and any other necessary files into the container at runtime. For example:

```
docker run --rm \
  -v $(pwd)/playbooks:/ansible/playbooks \
  -v $(pwd)/inventory.yaml:/ansible/inventory/inventory.yaml \
  -v $(pwd)/roles:/ansible/roles \
  -v $(pwd)/collections:/ansible/collections \
  -v ~/.ssh:/home/nonroot/.ssh \
  containerized-ansible \
  ansible-playbook /ansible/playbooks/your-playbook.yml -i /ansible/inventory/inventory.yaml
```

---

## Convenience Functions

To make working with containerized Ansible easier, source the provided aliases:

```bash
# Use default version (2.18.7)
source ./aliases.sh

# Or specify a version
export ANSIBLE_VERSION=2.17.0
source ./aliases.sh