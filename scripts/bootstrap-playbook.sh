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
mkdir -p "$PROJECT_DIR"/{playbooks,inventory,roles,collections,vars,vault,group_vars,host_vars}

# Create ansible.cfg
cat > "$PROJECT_DIR/ansible.cfg" << 'EOF'
[defaults]
inventory=./inventory.yaml
host_key_checking = False
stdout_callback = yaml
bin_ansible_callbacks = False
become = True
roles_path = ./roles
collections_path = ./collections
remote_tmp = $HOME/.ansible/tmp
local_tmp  = $HOME/.ansible/tmp

[ssh_connection]
pipelining = True
control_path = /tmp/ansible-ssh-%%h-%%p-%%r
EOF

# Create inventory.yaml template
cat > "$PROJECT_DIR/inventory.yaml" << 'EOF'
---
all:
  children:
    servers:
      hosts:
        example-host:
          ansible_host: 192.168.1.100
          ansible_user: your_user
          ansible_connection: ssh
EOF

# Create main playbook
cat > "$PROJECT_DIR/playbooks/main.yaml" << 'EOF'
---
- name: Main Playbook
  hosts: all
  become: true
  gather_facts: true
  
  tasks:
    - name: Example task - Gather system facts
      debug:
        msg: |
          Hostname: {{ ansible_hostname }}
          OS: {{ ansible_distribution }} {{ ansible_distribution_version }}
          Architecture: {{ ansible_architecture }}
          Python version: {{ ansible_python_version }}
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
├── group_vars/          # Group-specific variables
└── host_vars/           # Host-specific variables
\`\`\`

## Usage

### Run the main playbook

\`\`\`bash
docker run --rm \\
  -v \$(pwd)/playbooks:/ansible/playbooks \\
  -v \$(pwd)/inventory.yaml:/ansible/inventory/inventory.yaml \\
  -v \$(pwd)/ansible.cfg:/ansible/ansible.cfg \\
  -v \$(pwd)/roles:/ansible/roles \\
  -v \$(pwd)/collections:/ansible/collections \\
  -v ~/.ssh:/home/nonroot/.ssh \\
  containerized-ansible:2.20.1 \\
  ansible-playbook /ansible/playbooks/main.yaml -i /ansible/inventory/inventory.yaml
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