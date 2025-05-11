# Variables
ANSIBLE_VERSION ?= $(shell jq -r '.["ansible-core"]' ansible-version.json 2>/dev/null || echo "") 
IMAGE_NAME := containerized-ansible
REPO_ROOT := $(shell pwd)
PLATFORMS ?= linux/amd64,linux/arm64

# Validate that ANSIBLE_VERSION is provided
.PHONY: validate-version
validate-version:
	@if [ -z "$(ANSIBLE_VERSION)" ]; then \
		echo "Error: ANSIBLE_VERSION is required. Use 'make build ANSIBLE_VERSION=x.y.z'"; \
		exit 1; \
	fi

# Build the Docker image (single architecture)
.PHONY: build
build: validate-version
	@echo "Building $(IMAGE_NAME):$(ANSIBLE_VERSION) with Ansible $(ANSIBLE_VERSION)..."
	docker build \
		--build-arg ANSIBLE_VERSION=$(ANSIBLE_VERSION) \
		-t $(IMAGE_NAME):$(ANSIBLE_VERSION) \
		$(REPO_ROOT)
	@echo "Build complete: $(IMAGE_NAME):$(ANSIBLE_VERSION)"

# Build multi-architecture Docker image
.PHONY: build-multiarch
build-multiarch: validate-version
	@echo "Building multi-arch $(IMAGE_NAME):$(ANSIBLE_VERSION) for platforms: $(PLATFORMS)"
	docker buildx build \
		--platform $(PLATFORMS) \
		--build-arg ANSIBLE_VERSION=$(ANSIBLE_VERSION) \
		-t $(IMAGE_NAME):$(ANSIBLE_VERSION) \
		--load \
		$(REPO_ROOT)
	@echo "Multi-arch build complete: $(IMAGE_NAME):$(ANSIBLE_VERSION)"

# Test the Docker image
.PHONY: test
test: validate-version
	@echo "Testing $(IMAGE_NAME):$(ANSIBLE_VERSION)..."
	docker run --rm $(IMAGE_NAME):$(ANSIBLE_VERSION) ansible --version
	@echo "Test complete."

# Build and test in one command
.PHONY: all
all: build test

# Help command
.PHONY: help
help:
	@echo "Containerized Ansible Makefile"
	@echo ""
	@echo "Usage:"
	@echo "  make build ANSIBLE_VERSION=x.y.z          Build the Docker image with specified Ansible version"
	@echo "  make build-multiarch ANSIBLE_VERSION=x.y.z Build multi-arch Docker image (requires buildx setup)"
	@echo "  make test ANSIBLE_VERSION=x.y.z           Test the Docker image with specified Ansible version"
	@echo "  make all ANSIBLE_VERSION=x.y.z            Build and test in one command"
	@echo "  make help                                 Show this help message"
	@echo ""
	@echo "Examples:"
	@echo "  make build ANSIBLE_VERSION=2.12.3"
	@echo "  make build-multiarch ANSIBLE_VERSION=2.12.3 PLATFORMS=linux/amd64,linux/arm64"
	@echo "  make all ANSIBLE_VERSION=2.14.0"

# Default target
.DEFAULT_GOAL := help