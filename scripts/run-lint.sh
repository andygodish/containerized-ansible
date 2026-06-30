#!/usr/bin/env bash
set -euo pipefail

# Run ansible-lint inside the containerized-ansible image.
#
# Usage:
#   ./scripts/run-lint.sh [PATHS...]
#
# If no paths are provided, it lints the current working directory.

IMAGE=${IMAGE:-"containerized-ansible:latest"}

# If caller passed explicit lint targets, use them; otherwise lint repo root.
LINT_PATHS=("$@")
if [[ ${#LINT_PATHS[@]} -eq 0 ]]; then
  LINT_PATHS=(".")
fi

# Run from repo root on the host.
REPO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

exec docker run --rm -t \
  -v "${REPO_ROOT}:/ansible" \
  -w /ansible \
  "${IMAGE}" \
  ansible-lint "${LINT_PATHS[@]}"
