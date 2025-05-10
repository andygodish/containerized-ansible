FROM cgr.dev/chainguard/python:latest-dev

# Set environment variables
ENV ANSIBLE_CONFIG=/ansible/ansible.cfg
ENV PATH="/home/nonroot/.local/bin:$PATH"

# Switch to root for package installation
USER root

# Install only necessary system packages
RUN apk add --no-cache openssh-client

# Create ansible directories with proper permissions
RUN mkdir -p /ansible/playbooks /ansible/inventory /ansible/vars /ansible/vault \
    && chown -R nonroot:nonroot /ansible

# Switch back to nonroot for remaining operations
USER nonroot

# Install Ansible with pip
RUN pip install --user ansible

# Copy default ansible.cfg
COPY --chown=nonroot:nonroot ansible.cfg /ansible/ansible.cfg

# Copy entrypoint script
COPY --chown=nonroot:nonroot entrypoint.sh /home/nonroot/entrypoint.sh
RUN chmod +x /home/nonroot/entrypoint.sh

# Set working directory
WORKDIR /ansible

ENTRYPOINT ["/home/nonroot/entrypoint.sh"]