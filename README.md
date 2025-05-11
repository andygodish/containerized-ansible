# Containerized Ansible

Rather than maintaining dependencies in your local environment, use this purpose-built Ansible container that:

Can be run with a single command
Mounts local playbooks/inventory for execution
Provides a consistent environment for Ansible operations

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

### Implementation Questions

Generated from early converations with the team (ie, AI)

1. Do you want to include any Ansible collections by default, or just the core?
2. How do you plan to handle SSH authentication? (Mounting keys, agent forwarding)
3. Will you need to support Ansible Vault operations?
4. Any specific version requirements for Ansible?
5. Any specific plugins or dependencies your playbooks typically require?