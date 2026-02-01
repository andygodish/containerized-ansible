# Running playbooks against your Mac host (from the container)

This repo provides a Docker image (`containerized-ansible:<version>`) that can run Ansible without installing Python/Ansible on your workstation.

If you want to **use the container as the control node** but run tasks **on the Mac host itself**, the container must connect back to macOS over **SSH**.

This doc walks through the “container → macOS host” loopback approach.

## TL;DR

1. Enable **Remote Login** (System Settings → General → Sharing → Remote Login → ON)
2. Add your SSH public key to `~/.ssh/authorized_keys`
3. Run `docker run --rm … ansible-playbook …` with:
   - your playbook/inventory mounted into `/ansible/...`
   - your SSH key mounted into `/home/nonroot/.ssh/...`
   - SSH config disabled (macOS-specific options like `UseKeychain` break Linux SSH)

## Why SSH is required

When you run Ansible in a container and use `ansible_connection: local`, “local” means **inside the container**, not your Mac.

To target the Mac host from the container, use Ansible’s default transport: **SSH**.

On Docker Desktop for Mac, the host is reachable from containers at:

- `host.docker.internal`

## 1) Enable SSH server on macOS

Turn on **Remote Login**:

- System Settings → General → Sharing → Remote Login → ON

This starts `sshd` listening on port 22.

Verify on the Mac:

```bash
ssh <your-user>@localhost 'whoami'
```

## 2) Authorize an SSH key for the target user

Ansible will authenticate via SSH keys.

Add your public key to `~/.ssh/authorized_keys` for the target user (example below assumes the remote user is `moltbot`):

```bash
mkdir -p ~/.ssh
chmod 700 ~/.ssh
cat ~/.ssh/id_ed25519.pub >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
```

Verify key auth works:

```bash
ssh -i ~/.ssh/id_ed25519 -o IdentitiesOnly=yes <your-user>@localhost 'whoami'
```

## 3) Inventory example

Use SSH to the host from inside the container:

```yaml
all:
  hosts:
    mac:
      ansible_host: host.docker.internal
      ansible_user: moltbot
      ansible_connection: ssh
```

## 4) Run ansible-playbook ephemerally via Docker

From your playbook project directory:

```bash
mkdir -p artifacts .ssh-container

docker run --rm \
  --entrypoint ansible-playbook \
  -e ANSIBLE_SSH_ARGS='-F /dev/null -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o IdentityFile=/home/nonroot/.ssh/id_ed25519 -o IdentitiesOnly=yes' \
  -v "$PWD/playbooks:/ansible/playbooks" \
  -v "$PWD/inventory.yaml:/ansible/inventory/inventory.yaml:ro" \
  -v "$PWD/ansible.cfg:/ansible/ansible.cfg:ro" \
  -v "$PWD/roles:/ansible/roles" \
  -v "$PWD/collections:/ansible/collections" \
  -v "$PWD/artifacts:/ansible/artifacts" \
  -v "$PWD/.ssh-container:/home/nonroot/.ssh" \
  -v "$HOME/.ssh/id_ed25519:/home/nonroot/.ssh/id_ed25519:ro" \
  containerized-ansible:2.20.2 \
  /ansible/playbooks/main.yaml -i /ansible/inventory/inventory.yaml
```

### Notes / gotchas

- **Do not mount your macOS `~/.ssh/config` into the container**.
  - macOS SSH supports options like `UseKeychain` which will cause Linux OpenSSH to error.
  - The `-F /dev/null` flag disables reading SSH config.

- You can mount `known_hosts` if you want strict host key checking.
  - If you don’t, the `UserKnownHostsFile=/dev/null` + `StrictHostKeyChecking=no` combo prevents the container from trying to write a host key entry.

- If you want playbook outputs on the host, write them to a mounted path (e.g. `/ansible/artifacts`) or `fetch` remote files back to the controller.

## Troubleshooting

### `ssh: connect to host host.docker.internal port 22: Connection refused`

Remote Login is not enabled, or `sshd` isn’t listening on port 22.

### `Bad configuration option: usekeychain`

You mounted a macOS SSH config into the Linux container. Disable config (`-F /dev/null`) and only mount the key.

### `Permission denied (publickey,...)`

The public key isn’t in the target user’s `~/.ssh/authorized_keys`, or you’re using the wrong `ansible_user`.
