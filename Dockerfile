FROM --platform=$BUILDPLATFORM cgr.dev/chainguard/python:latest-dev AS builder
# Accept Ansible version as build argument, default to latest
ARG ANSIBLE_VERSION=latest
ARG TARGETPLATFORM
ARG BUILDPLATFORM
# Install only necessary system packages
USER root
RUN apk add --no-cache openssh-client
# Create global collections directory with appropriate permissions
RUN mkdir -p /usr/share/ansible/collections && chown -R nonroot:nonroot /usr/share/ansible
# Switch back to nonroot for remaining operations
USER nonroot

# Set PATH to include .local/bin
ENV PATH="/home/nonroot/.local/bin:$PATH"

# Install specified Ansible version with pip
RUN if [ "${ANSIBLE_VERSION}" = "latest" ]; then \
        pip install --user ansible ansible-lint; \
        ansible-galaxy collection install community.general -p /usr/share/ansible/collections; \
    else \
        # Remove 'v' prefix if present
        VERSION=$(echo ${ANSIBLE_VERSION} | sed 's/^v//'); \
        # Check if installing a pre-2.10 version (when ansible-core didn't exist)
        MAJOR=$(echo ${VERSION} | cut -d. -f1); \
        MINOR=$(echo ${VERSION} | cut -d. -f2); \
        if [ "$MAJOR" -lt 2 ] || ([ "$MAJOR" -eq 2 ] && [ "$MINOR" -lt 10 ]); then \
            # For older versions, install ansible directly
            pip install --user ansible==${VERSION} ansible-lint; \
        else \
            # For 2.10+, install ansible-core with specific version and ansible-lint
            pip install --user ansible-core==${VERSION} ansible-lint; \
            ansible-galaxy collection install community.general -p /usr/share/ansible/collections; \
        fi \
    fi

# Final stage
FROM cgr.dev/chainguard/python:latest-dev
# Accept Ansible version argument to pass to final image
ARG ANSIBLE_VERSION
# Set environment variables
ENV ANSIBLE_CONFIG=/ansible/ansible.cfg
ENV PATH="/home/nonroot/.local/bin:$PATH"
ENV ANSIBLE_COLLECTIONS_PATH="/usr/share/ansible/collections:/ansible/collections"

# Install only necessary system packages
USER root
RUN apk add --no-cache openssh-client
# Create ansible directories
RUN mkdir -p /ansible/playbooks /ansible/inventory /ansible/vars /ansible/vault \
    /ansible/roles /ansible/collections
# Create global collections directory
RUN mkdir -p /usr/share/ansible/collections
# Set proper permissions
RUN chown -R nonroot:nonroot /ansible /usr/share/ansible

USER nonroot

# Copy Ansible installation from builder
COPY --from=builder --chown=nonroot:nonroot /home/nonroot/.local /home/nonroot/.local
# Copy global collections from builder
COPY --from=builder --chown=nonroot:nonroot /usr/share/ansible/collections /usr/share/ansible/collections

# Copy default ansible.cfg
COPY --chown=nonroot:nonroot ansible.cfg /ansible/ansible.cfg

# Copy entrypoint script
COPY --chown=nonroot:nonroot entrypoint.sh /home/nonroot/entrypoint.sh
RUN chmod +x /home/nonroot/entrypoint.sh

# Set working directory
WORKDIR /ansible

# Set label for version tracking
LABEL org.opencontainers.image.description="Containerized Ansible ${ANSIBLE_VERSION}"
LABEL org.opencontainers.image.version="${ANSIBLE_VERSION}"

ENTRYPOINT ["/home/nonroot/entrypoint.sh"]