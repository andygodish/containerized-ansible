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

---

### Implementation Questions

Generated from early converations with the team (ie, AI)

1. Do you want to include any Ansible collections by default, or just the core?
2. How do you plan to handle SSH authentication? (Mounting keys, agent forwarding)
3. Will you need to support Ansible Vault operations?
4. Any specific version requirements for Ansible?
5. Any specific plugins or dependencies your playbooks typically require?