#!/bin/bash
# ansible-playbook-init
# Bootstrap script for creating new Ansible playbook projects
# Usage: ansible-playbook-init <project-name>

set -e

PROJECT_NAME="$1"

if [ -z "$PROJECT_NAME" ]; then
    echo "Usage: ansible-playbook-init <project-name>"
    echo "Example: ansible-playbook-init bitcoin-node"
    exit 1
fi

PROJECT_DIR="ansible-playbook-${PROJECT_NAME}"

if [ -d "$PROJECT_DIR" ]; then
    echo "Error: Directory '$PROJECT_DIR' already exists"
    exit 1
fi

echo "Creating Ansible playbook project: $PROJECT_DIR"

# Create directory structure
mkdir -p "$PROJECT_DIR"/{playbooks,inventory,roles,collections,vars,vault,group_vars,host_vars,artifacts}

# Create ansible.cfg
cat > "$PROJECT_DIR/ansible.cfg" << 'EOF'
[defaults]
inventory=./inventory.yaml
host_key_checking = False
# community.general.yaml callback was removed; use builtin default with YAML formatting
stdout_callback = default
result_format = yaml
bin_ansible_callbacks = False
become = False
roles_path = ./roles
collections_path = ./collections
remote_tmp = $HOME/.ansible/tmp
local_tmp  = $HOME/.ansible/tmp

deprecation_warnings = False

[ssh_connection]
pipelining = True
control_path = /tmp/ansible-ssh-%%h-%%p-%%r
EOF

# Create inventory.yaml template
# NOTE: when running playbooks from inside Docker on macOS, the host is reachable at host.docker.internal
cat > "$PROJECT_DIR/inventory.yaml" << 'EOF'
---
all:
  hosts:
    example-host:
      ansible_host: 192.168.1.100
      ansible_user: your_user
      ansible_connection: ssh

    # macOS host (from inside Docker Desktop)
    # mac:
    #   ansible_host: host.docker.internal
    #   ansible_user: your_user
    #   ansible_connection: ssh
EOF

# Create main playbook
# Writes reports on the remote host and fetches them back to ./artifacts on the controller.
cat > "$PROJECT_DIR/playbooks/main.yaml" << 'EOF'
---
- name: Smoke test + basic report
  hosts: all
  gather_facts: true
  become: false

  vars:
    artifacts_dir: "{{ playbook_dir }}/../artifacts"
    remote_report_dir: "/tmp/ansible-artifacts"

  pre_tasks:
    - name: Ensure remote report directory exists
      ansible.builtin.file:
        path: "{{ remote_report_dir }}"
        state: directory
        mode: "0755"

  tasks:
    - name: Sanity check - ping
      ansible.builtin.ping:

    - name: Show a short summary
      ansible.builtin.debug:
        msg:
          hostname: "{{ ansible_hostname }}"
          os: "{{ ansible_distribution }} {{ ansible_distribution_version }}"
          arch: "{{ ansible_architecture }}"
          python: "{{ ansible_python_version | default('unknown') }}"

    - name: Write facts report on remote
      ansible.builtin.copy:
        dest: "{{ remote_report_dir }}/report.yaml"
        mode: "0644"
        content: |
          generated_at: {{ ansible_date_time.iso8601 }}
          host:
            hostname: {{ ansible_hostname }}
            fqdn: {{ ansible_fqdn }}
            user_id: {{ ansible_user_id }}
          os:
            distribution: {{ ansible_distribution }}
            version: {{ ansible_distribution_version }}
            kernel: {{ ansible_kernel }}

    - name: Disk usage (human readable)
      ansible.builtin.command: df -h
      register: df_out
      changed_when: false

    - name: Write disk usage on remote
      ansible.builtin.copy:
        dest: "{{ remote_report_dir }}/df.txt"
        mode: "0644"
        content: "{{ df_out.stdout }}\n"

    - name: Fetch reports back to controller artifacts/
      ansible.builtin.fetch:
        src: "{{ remote_report_dir }}/{{ item }}"
        dest: "{{ artifacts_dir }}/"
        flat: true
      loop:
        - report.yaml
        - df.txt
EOF

# Create README.md
cat > "$PROJECT_DIR/README.md" << EOF
# ${PROJECT_NAME}

Ansible playbook project for ${PROJECT_NAME}.

## Structure

\`\`\`
${PROJECT_DIR}/
├── ansible.cfg           # Ansible configuration
├── inventory.yaml        # Inventory file
├── playbooks/           # Playbook files
│   └── main.yaml        # Main playbook
├── roles/               # Custom roles
├── collections/         # Custom collections
├── vars/                # Variable files
├── vault/               # Encrypted files
├── artifacts/           # Output artifacts fetched from targets
├── group_vars/          # Group-specific variables
└── host_vars/           # Host-specific variables
\`\`\`

## Usage

### Run the main playbook

\`\`\`bash
# Example: run from the container, connecting to targets over SSH.
# NOTE: If you want to target the *macOS host* from the container, use host.docker.internal in inventory.yaml.
mkdir -p artifacts

docker run --rm \\
  --entrypoint ansible-playbook \\
  -e ANSIBLE_SSH_ARGS='-F /dev/null -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o IdentityFile=/home/nonroot/.ssh/id_ed25519 -o IdentitiesOnly=yes' \\
  -v \$(pwd)/playbooks:/ansible/playbooks \\
  -v \$(pwd)/inventory.yaml:/ansible/inventory/inventory.yaml:ro \\
  -v \$(pwd)/ansible.cfg:/ansible/ansible.cfg:ro \\
  -v \$(pwd)/roles:/ansible/roles \\
  -v \$(pwd)/collections:/ansible/collections \\
  -v \$(pwd)/artifacts:/ansible/artifacts \\
  -v ~/.ssh/id_ed25519:/home/nonroot/.ssh/id_ed25519:ro \\
  containerized-ansible:<tag> \\
  /ansible/playbooks/main.yaml -i /ansible/inventory/inventory.yaml
\`\`\`

### Or use the alias (if configured)

\`\`\`bash
ansible-playbook playbooks/main.yaml
\`\`\`

## Quick Start

1. Edit \`inventory.yaml\` with your target hosts
2. Modify \`playbooks/main.yaml\` with your tasks
3. Run the playbook using the command above

## Adding Roles

\`\`\`bash
cd roles/
ansible-role-init my-role
\`\`\`

## Variables

- **group_vars/**: Variables for inventory groups
- **host_vars/**: Variables for specific hosts
- **vars/**: General variable files

## Vault (Encrypted Secrets)

\`\`\`bash
ansible-vault create vault/secrets.yaml
ansible-vault edit vault/secrets.yaml
\`\`\`

Run playbook with vault:
\`\`\`bash
ansible-playbook playbooks/main.yaml --ask-vault-pass
\`\`\`
EOF

# Create .gitignore
cat > "$PROJECT_DIR/.gitignore" << 'EOF'
# Ansible
*.retry
.vault_pass
*.swp
*~

# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python

# Collections
collections/ansible_collections/

# Logs
*.log

# OS
.DS_Store
Thumbs.db
EOF

# Create example group_vars
mkdir -p "$PROJECT_DIR/group_vars/all"
cat > "$PROJECT_DIR/group_vars/all/vars.yaml" << 'EOF'
---
# Variables for all hosts
# Example:
# ntp_servers:
#   - 0.pool.ntp.org
#   - 1.pool.ntp.org
EOF

# Create example host_vars
mkdir -p "$PROJECT_DIR/host_vars/example-host"
cat > "$PROJECT_DIR/host_vars/example-host/vars.yaml" << 'EOF'
---
# Variables specific to example-host
# Example:
# custom_port: 8080
EOF

# Create requirements.yaml for collections
cat > "$PROJECT_DIR/collections/requirements.yaml" << 'EOF'
---
collections:
  # Example collections
  # - name: community.general
  #   version: ">=1.0.0"
  # - name: ansible.posix
EOF

# Create requirements.yaml for roles
cat > "$PROJECT_DIR/roles/requirements.yaml" << 'EOF'
---
roles:
  # Example roles from Ansible Galaxy
  # - name: geerlingguy.docker
  #   version: "7.0.2"
EOF

echo "✅ Successfully created playbook project: $PROJECT_DIR"
echo ""
echo "Next steps:"
echo "  1. cd $PROJECT_DIR"
echo "  2. Edit inventory.yaml with your hosts"
echo "  3. Edit playbooks/main.yaml with your tasks"
echo "  4. Run: ansible-playbook playbooks/main.yaml"
echo ""
echo "Project structure:"
tree -L 2 "$PROJECT_DIR" 2>/dev/null || find "$PROJECT_DIR" -maxdepth 2 -type d | sed 's|[^/]*/| |g'