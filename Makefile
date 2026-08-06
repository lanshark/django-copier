# Makefile for automation
include .env

SHELL := /bin/bash

# Colors for output
NC = $(shell tput sgr0)
RED = $(shell tput setaf 1)
GREEN = $(shell tput setaf 2)
YELLOW = $(shell tput setaf 3)
MAGENTA = $(shell tput setaf 5)
CYAN = $(shell tput setaf 6)
PINK = $(shell echo -e '\033[38;5;205m')

BOLD = $(shell tput bold)

H1 = $(BOLD)$(CYAN)
H2 = $(BOLD)$(PINK)

# User and group for the container
USER_NAME := rmove
GROUP_NAME := rmove
DEFAULT_UID := $(shell id -u)
DEFAULT_GID := $(shell id -g)
DJANGO_SUPERUSER_USERNAME := rmove
DJANGO_SUPERUSER_EMAIL := rmove@rmove.com
DJANGO_SUPERUSER_PASSWORD := rmove

# Get UID and GID from the environment or use defaults
LOCAL_UID := $(shell id -u $(USER_NAME) 2>/dev/null || echo $(DEFAULT_UID))
LOCAL_GID := $(shell id -g $(GROUP_NAME) 2>/dev/null || echo $(DEFAULT_GID))

# Environment target (local, stage, production), default to production
ENVIRONMENT ?= production
ENV = $(strip $(ENVIRONMENT))

# ARCH target (amd64, arm64), default to amd64
ARCH_TEMP ?= amd64
ARCH ?= $(strip $(ARCH_TEMP))

# Service target (web, db, mailhog), default to web
SERVICE ?= web
PROJECT_NAME ?= central
SUBDOMAIN ?= $(PROJECT_NAME)
TAG ?= latest.$(ENV)-$(ARCH)
TARGET ?= $(PROJECT_NAME)-$(SERVICE)
PORT_OFFSET ?= 1

# DB defaults
POSTGRES_HOST ?= $(PROJECT_NAME)-db
POSTGRES_DB ?= rmove_$(PROJECT_NAME)
POSTGRES_USER ?= rmove
POSTGRES_PASSWORD ?= rmove
POSTGRES_PORT ?= 5432
HOST_POSTGRES_PORT := $(shell echo $$((5432 + $(PORT_OFFSET))))

# Other defaults
DATA_DIR ?= /uploads/${PROJECT_NAME}-$(ENV)
HOST_WEB_PORT ?= $(shell echo $$((8000 + $(PORT_OFFSET))))
HOST_DEBUGGER_PORT ?= $(shell echo $$((3000 + $(PORT_OFFSET))))
HOST_MAILHOG_PORT ?= $(shell echo $$((1025 + $(PORT_OFFSET))))
HOST_MAILHOG_WEB_PORT ?= $(shell echo $$((8026 + $(PORT_OFFSET))))
PROJECT_HOST_DIR ?= $(shell pwd)

ifeq ($(ENV),local)
	CADDY_LABEL ?= $(SUBDOMAIN).localhost
	COMPOSE_PROFILES := dev
	DOCKER_CADDY_FILE ?= $(CURDIR)/../rMove-Caddy/docker/docker-compose.caddy.local.yml
else ifeq ($(ENV),test)
	CADDY_LABEL ?= $(SUBDOMAIN).test.rmove.rsginc.com
	COMPOSE_PROFILES := deploy
	CERT_FILE_PATH := /etc/ssl/certs/star_test_rmove_rsginc_com.chained.crt
	DOCKER_CADDY_FILE ?= $(CURDIR)/../rMove-Caddy/docker/docker-compose.caddy.yml
	KEY_FILE_PATH := /etc/ssl/private/star_test_rmove_rsginc_com.key
else ifeq ($(ENV),stage)
	CADDY_LABEL ?= $(SUBDOMAIN).stage.rmove.rsginc.com
	COMPOSE_PROFILES := deploy
	CERT_FILE_PATH := /etc/ssl/certs/star_stage_rmove_rsginc_com.chained.crt
	DOCKER_CADDY_FILE ?= $(CURDIR)/../rMove-Caddy/docker/docker-compose.caddy.yml
	KEY_FILE_PATH := /etc/ssl/private/star_stage_rmove_rsginc_com.key
else
	BASE_CERT_FILE_PATH := /etc/ssl/certs/star_rsginc_com.chained.crt
	BASE_KEY_FILE_PATH := /etc/ssl/private/star_rsginc_com.key
	CADDY_LABEL ?= $(SUBDOMAIN).rmove.rsginc.com
	COMPOSE_PROFILES := deploy
	CERT_FILE_PATH := /etc/ssl/certs/star_rmove_rsginc_com.chained.crt
	DOCKER_CADDY_FILE ?= $(CURDIR)/../rMove-Caddy/docker/docker-compose.caddy.yml
	KEY_FILE_PATH := /etc/ssl/private/star_rmove_rsginc_com.key
endif

AZ_CONFIG_DIR := $(shell [ -d "$$HOME/.azure" ] && echo "$$HOME/.azure" || echo "$(DATA_DIR)")

# Docker Compose file directory (possibly temp)
DOCKER_DIR = docker
DOCKER_COMPOSE ?= docker compose

# Dockerfile and Docker Compose file
COMPOSE_FILE = $(DOCKER_DIR)/docker-compose.$(ENV).yml

ifeq ($(ENV),local)
	BUILD_FILE = $(DOCKER_DIR)/Dockerfile.local
else
	BUILD_FILE = $(DOCKER_DIR)/Dockerfile.deploy
endif

# Docker Exec command helper (generic)
ifeq ($(GITHUB_ACTIONS),true)
	EXEC_CMD := docker exec $(TARGET)
else
	ifeq ($(filter dump backup-db pg_dump restore-db,$(MAKECMDGOALS)),)
		EXEC_CMD := docker exec -it $(TARGET)
	else
		EXEC_CMD := docker exec -e PGPASSWORD=$(POSTGRES_PASSWORD) $(TARGET)
	endif
endif

ifeq ($(INTERACTIVE),false)
	EXEC_CMD := $(EXEC_CMD)
endif

# Django manage.py command helper
ifeq ($(IN_DOCKER),true)
	undefine EXEC_CMD
	MANAGE_CMD = python manage.py
else
	IN_DOCKER=false
	MANAGE_CMD = $(EXEC_CMD) python manage.py
endif

# Arguments helper
args = `arg="$(filter-out $@,$(MAKECMDGOALS))" && echo $${arg:-${1}}`
CADDY_CONTAINER = $(call args,)
DB_BACKUP = $(call args,)
DB_BACKUP_OUTPUT = $(call args,db-backup)
FIXTURE_PATH = $(call args,)
TEST_PATH = $(call args,)
HELPER_COMMANDS = all check-data_dir check-caddy check-rmove-network check-port check-container-running check-local-env-only check-local-env-reject check-default-stack-only check-default-stack-reject check-non-deploy-env-only check-non-deploy-env-reject check-in-docker-only check-in-docker-reject setup-pgpass
EXCLUDE_PATTERN = $(shell echo $(HELPER_COMMANDS) | sed 's/ /|/g')

# Environment variables to be passed to the shell before Docker Compose.
DOCKER_COMPOSE_ENV_VARS = AZ_CONFIG_DIR=$(AZ_CONFIG_DIR) \
	CADDY_LABEL=$(CADDY_LABEL) \
	COMPOSE_PROFILES=$(COMPOSE_PROFILES) \
	DATA_DIR=$(DATA_DIR) \
	DJANGO_SUPERUSER_USERNAME=$(DJANGO_SUPERUSER_USERNAME) \
	DJANGO_SUPERUSER_EMAIL=$(DJANGO_SUPERUSER_EMAIL) \
	DJANGO_SUPERUSER_PASSWORD=$(DJANGO_SUPERUSER_PASSWORD) \
	PROJECT_HOST_DIR=$(PROJECT_HOST_DIR) \
	POSTGRES_HOST=$(POSTGRES_HOST) \
	POSTGRES_DB=$(POSTGRES_DB) \
	POSTGRES_USER=$(POSTGRES_USER) \
	POSTGRES_PASSWORD=$(POSTGRES_PASSWORD) \
	POSTGRES_PORT=$(POSTGRES_PORT) \
	HOST_DEBUGGER_PORT=$(HOST_DEBUGGER_PORT) \
	HOST_WEB_PORT=$(HOST_WEB_PORT) \
	HOST_POSTGRES_PORT=$(HOST_POSTGRES_PORT) \
	HOST_MAILHOG_PORT=$(HOST_MAILHOG_PORT) \
	HOST_MAILHOG_WEB_PORT=$(HOST_MAILHOG_WEB_PORT) \
	SUBDOMAIN=$(SUBDOMAIN) \
	LOCAL_UID=$(LOCAL_UID) \
	LOCAL_GID=$(LOCAL_GID) \
	TAG=$(TAG) \
# Common variables for Docker Compose (used for both up and checking status)
DOCKER_COMPOSE_ARGS = -f $(COMPOSE_FILE) \
	-p $(PROJECT_NAME) \
	--env-file .env \
	--progress=plain

# Environment variables to be passed to the shell before Docker Compose.
CADDY_DOCKER_COMPOSE_ENV_VARS = BASE_CERT_FILE_PATH=$(BASE_CERT_FILE_PATH) \
	BASE_KEY_FILE_PATH=$(BASE_KEY_FILE_PATH) \
	CERT_FILE_PATH=$(CERT_FILE_PATH) \
	KEY_FILE_PATH=$(KEY_FILE_PATH)
# Common variables for Docker Compose (used for both up and checking status)
CADDY_DOCKER_COMPOSE_ARGS = -f $(DOCKER_CADDY_FILE) \
	-p rmove-caddy \
	--env-file .env \
	--progress=plain


.PHONY: all
all: build-up # Default target
# /uploads/logs/central_debug.log

### Helper commands
check-data_dir: # Check if data directory exists
	@echo "Checking if data directory $(GREEN)$(DATA_DIR)$(NC) exists"
	@if [ ! -d "$(DATA_DIR)" ]; then \
		echo "Data directory $(GREEN)$(DATA_DIR)$(NC) does not exist, creating it"; \
		sudo mkdir -p "$(DATA_DIR)"; \
		echo "Updating permissions for data directory"; \
		echo "Setting ownership to $(GREEN)$(LOCAL_UID)$(NC)"; \
		sudo chown -R $(LOCAL_UID) "$(DATA_DIR)"; \
	else \
		echo "Data directory $(GREEN)$(DATA_DIR)$(NC) exists"; \
	fi

	@echo "Checking if data subdirectories exists"
	@if [ ! -d "$(DATA_DIR)/static" ]; then \
		echo "Data directory $(GREEN)$(DATA_DIR)/static$(NC) does not exist, creating it"; \
		mkdir -p "$(DATA_DIR)/static"; \
	else \
		echo "Data directory $(GREEN)$(DATA_DIR)/static$(NC) exists"; \
	fi

	@if [ ! -d "$(DATA_DIR)/tmp" ]; then \
		echo "Data directory $(GREEN)$(DATA_DIR)/tmp$(NC) does not exist, creating it"; \
		mkdir -p "$(DATA_DIR)/tmp"; \
	else \
		echo "Data directory $(GREEN)$(DATA_DIR)/tmp$(NC) exists"; \
	fi

	@if [ ! -d "$(DATA_DIR)/logs" ]; then \
		echo "Data directory $(GREEN)$(DATA_DIR)/logs$(NC) does not exist, creating it"; \
		mkdir -p "$(DATA_DIR)/logs"; \
	else \
		echo "Data directory $(GREEN)$(DATA_DIR)/logs$(NC) exists"; \
	fi

	@echo "Checking if log file exists"
	@if [ ! -f "$(DATA_DIR)/logs/central_debug.log" ]; then \
		echo "File $(GREEN)$(DATA_DIR)/logs/central_debug.log$(NC) does not exist, creating it"; \
		touch "$(DATA_DIR)/logs/central_debug.log"; \
		echo "Updating permissions for data directory" \
		sudo chmod -R 2775 "$(DATA_DIR)" \
		sudo chown -R $(LOCAL_UID):$(LOCAL_GID) "$(DATA_DIR)" \
	else \
		echo "File $(GREEN)$(DATA_DIR)/logs/central_debug.log$(NC) exists"; \
	fi

	@echo "Checking if outputs dir exists"
	@if [ ! -d "$(PROJECT_HOST_DIR)/outputs" ]; then \
		echo "Data directory $(GREEN)$(PROJECT_HOST_DIR)/outputs$(NC) does not exist, creating it"; \
		mkdir -p "$(PROJECT_HOST_DIR)/outputs"; \
	else \
		echo "Data directory $(GREEN)$(PROJECT_HOST_DIR)/outputs$(NC) exists"; \
	fi

check-caddy: # Check if Caddy service is running
	@echo "Checking if Caddy service is running"
	@if [ -z "$$(docker ps -q -f name=caddy)" ]; then \
		echo "Caddy service is not running"; \
	else \
		echo "Caddy service is running"; \
	fi

check-rmove-network: # Check if rmove network exists
	@echo "Checking if $(GREEN)rmove network$(NC) exists"
	@if [ -z "$$(docker network ls -q -f name=rmove_network)" ]; then \
		echo "Network $(GREEN)rmove_network does not exist"; \
		docker network create rmove_network; \
		echo "Network $(GREEN)rmove_network$(NC) created"; \
	else \
		echo "Network $(GREEN)rmove_network$(NC) exists"; \
	fi
# @echo "--- Ensuring UFW rules for Docker bridge network are up-to-date ---"
# @sudo sh -c '\
# 	CURRENT_DOCKER_BRIDGE_SUBNET=$$(docker network inspect bridge --format '{{(index .IPAM.Config 0).Subnet}}'); \
# 	echo "Current Docker bridge subnet detected: $$CURRENT_DOCKER_BRIDGE_SUBNET"; \
# 	UFW_DOCKER_RULES=$$(ufw status numbered | grep -E "ALLOW IN.*172\\.[0-9]{1,3}\\.[0-9]{1,3}\\.0/16"); \
# 	if [ -n "$$UFW_DOCKER_RULES" ]; then \
# 		echo "Checking existing Docker bridge UFW rules..."; \
# 		echo "$$UFW_DOCKER_RULES" | while read -r line; do \
# 			RULE_NUM=$$(echo "$$line" | awk "{print \$$1}" | sed "s/[][[:space:]]//g"); \
# 			RULE_SUBNET=$$(echo "$$line" | awk "{print \$$NF}"); \
# 			# Only delete if the rule number and subnet are valid, and it's NOT the current subnet
# 			if [ -n "$$RULE_NUM" ] && [ -n "$$RULE_SUBNET" ] && [ "$$RULE_SUBNET" != "$$CURRENT_DOCKER_BRIDGE_SUBNET" ]; then \
# 				echo " - Deleting old UFW rule: $$line"; \
# 				ufw delete "$$RULE_NUM"; \
# 			fi; \
# 		done; \
# 	fi; \
# 	if ! ufw status | grep -q "$$CURRENT_DOCKER_BRIDGE_SUBNET ALLOW IN Anywhere"; then \
# 		echo " - Adding UFW rule for new Docker bridge subnet: $$CURRENT_DOCKER_BRIDGE_SUBNET"; \
# 		ufw allow from "$$CURRENT_DOCKER_BRIDGE_SUBNET" to any; \
# 	else \
# 		echo " - UFW rule for $$CURRENT_DOCKER_BRIDGE_SUBNET already exists. No action needed."; \
# 	fi; \
# 	echo "Reloading UFW to apply changes..."; \
# 	ufw reload; \
# 	echo "UFW rules updated." \
# '

check-port: # Check if port already in use
	@echo "Checking if $(GREEN)port $(HOST_WEB_PORT)$(NC) available"
	@sh -c 'HOST_WEB_PORT=$(HOST_WEB_PORT); \
		DOCKER_ARGS="$(DOCKER_COMPOSE_ARGS)"; \
		DOCKER_COMPOSE_ENV_VARS="$(DOCKER_COMPOSE_ENV_VARS)"; \
		\
		# 1. Check if the containers are already running for this project.\
		export HOST_WEB_PORT="$$HOST_WEB_PORT"; \
		eval "export $$DOCKER_COMPOSE_ENV_VARS"; \
		if [ -n "$$($(DOCKER_COMPOSE) $$DOCKER_ARGS ps -q 2>/dev/null)" ]; then \
			echo "Docker containers for this project are $(GREEN)already running on $$HOST_WEB_PORT$(NC). Check passed."; \
			exit 0; \
		fi; \
		# 2. If not running, check if the port is blocked by an external process (using nc).\
		# netcat (-z for zero I/O, -w 1 for 1-second timeout) checks if the port is open. \
		if nc -z -w 1 127.0.0.1 $$HOST_WEB_PORT 2>/dev/null; then \
			echo "WARNING: Port $$HOST_WEB_PORT is $(RED)ALREADY IN USE$(NC)."; \
			echo "    Please stop the process using this port or change the HOST_WEB_PORT or PORT_OFFSET value."; \
			exit 1; \
		else \
			echo "SUCCESS: Port $$HOST_WEB_PORT is $(GREEN)AVAILABLE$(NC) for use."; \
		fi'

check-container-running: # Check if the container is running
	@echo "Checking if container is running"
	@if [ -z "$$(docker ps -q -f name=$(TARGET))" ]; then \
		echo "Container $(GREEN)$(TARGET)$(NC) is not running"; \
		CONTAINER_RUNNING=False; \
	else \
		echo "Container $(GREEN)$(TARGET)$(NC) is running"; \
		CONTAINER_RUNNING=true; \
	fi

check-local-env-only: # Check local environment only
	@echo "Checking local environment only"
	@if [ "$(ENV)" != "local" ]; then \
		echo "Current environment set to $(GREEN)$(ENV)$(NC)"; \
		echo "This command is only allowed for local environment"; \
		exit 1; \
	fi

check-local-env-reject: # Check local environment reject
	@echo "Checking local environment reject"
	@if [ "$(ENV)" = "local" ]; then \
		echo "Current environment set to $(GREEN)$(ENV)$(NC)"; \
		echo "This command is not allowed for local environment"; \
		exit 1; \
	fi

check-non-deploy-env-only: # Check if environment is not stage or production only
	@echo "Checking non-deploy environment only"
	@if [ "$(ENV)" = "stage" ] || [ "$(ENV)" = "production" ]; then \
		echo "Current environment set to $(GREEN)$(ENV)$(NC)"; \
		echo "This command is only allowed for local and test environment"; \
		exit 1; \
	fi

check-non-deploy-env-reject: # Check if environment is not stage or production reject
	@echo "Checking non-deploy environment reject"
	@if [ "$(ENV)" != "stage" ] && [ "$(ENV)" != "production" ]; then \
		echo "Current environment set to $(GREEN)$(ENV)$(NC)"; \
		echo "This command is not allowed for local and test environment"; \
		exit 1; \
	fi

check-in-docker-only: # Check if running in Docker only
	@echo "Checking in Docker only"
	@if [ "$(IN_DOCKER)" = "true" ]; then \
		echo "This command is not allowed when running in Docker"; \
		exit 1; \
	fi

check-in-docker-reject: # Check if running in Docker reject
	@echo "Checking in Docker reject"
	@if [ "$(IN_DOCKER)" = "true" ]; then \
		echo "This command is not allowed when running in Docker"; \
		exit 1; \
	fi

setup-pgpass:
	@echo "Setting up pgpass.."
	@echo "$(POSTGRES_HOST):$(POSTGRES_PORT):*:$(POSTGRES_USER):$(POSTGRES_PASSWORD)" > ~/.pgpass
	@chmod 600 ~/.pgpass

## Docker commands
caddy-up: # Start Caddy service in detached mode for environment
	@make check-rmove-network
	@echo "Starting Caddy service for environment: $(GREEN)$(ENV)$(NC)"
	@make check-in-docker-reject
	@$(CADDY_DOCKER_COMPOSE_ENV_VARS) \
	$(DOCKER_COMPOSE) \
	$(CADDY_DOCKER_COMPOSE_ARGS) \
	up -d --remove-orphans
	@echo "Caddy service started for environment: $(GREEN)$(ENV)$(NC)"
	@echo "To view logs, run '$(GREEN)make logs SERVICE=caddy$(NC)'"
	@echo "You can view the current domains by running $(GREEN)make caddy-ls$(NC)"
	@echo "Run '$(GREEN)make help$(NC)' for more commands"

caddy-down: # Stop Caddy service in detached mode for environment
	@make check-rmove-network
	@echo "Stopping Caddy service for environment: $(GREEN)$(ENV)$(NC)"
	@make check-in-docker-reject
	@$(CADDY_DOCKER_COMPOSE_ENV_VARS) \
	$(DOCKER_COMPOSE) \
	$(CADDY_DOCKER_COMPOSE_ARGS) \
	down --remove-orphans
	@echo "Services stopped for environment: $(GREEN)$(ENV)$(NC)"
	@echo "Consider running '$(GREEN)make clean$(NC)' to remove unused resources"

caddy-ls caddy-status:
	@if [ -n "$$(docker ps -q -f name=caddy)" ]; then \
        echo "Caddy is running." ; \
		echo "Listing Caddy domains for environment: $(GREEN)$(ENV)$(NC)"; \
		echo "$(H1)Current stacks$(NC):$(H2)" ; \
		docker ps --format '{{.Names}}\t{{.Labels}}' \
		| grep -o 'caddy=[^,]*' \
		| sed 's/caddy=//'; \
		printf "$(NC)"; \
    else \
        echo "Caddy is NOT running. Start it with $(GREEN)make caddy-up$(NC)"; \
    fi

caddy-log caddy-logs: # View Caddy logs
	@echo "Showing Caddy logs for environment: $(GREEN)$(ENV)$(NC)"
	@make check-caddy
	@$(CADDY_DOCKER_COMPOSE_ENV_VARS) \
	$(DOCKER_COMPOSE) \
	$(CADDY_DOCKER_COMPOSE_ARGS) \
	logs -f caddy | { if [ -n "$(GREP)" ]; then grep --color=auto "$(GREP)"; else cat; fi; }

caddy-refresh caddy-reload: # Refresh or reload Caddy service
	@echo "Refreshing Caddy service for environment: $(GREEN)$(ENV)$(NC)"
	@make check-in-docker-reject
	@$(CADDY_DOCKER_COMPOSE_ENV_VARS) \
	$(DOCKER_COMPOSE) \
	$(CADDY_DOCKER_COMPOSE_ARGS) \
	exec caddy /bin/sh -c "caddy reload --config /etc/caddy/Caddyfile"
	@make caddy-up

caddy-clean: # Clean up Caddy service
	@echo "Cleaning up Caddy service for environment: $(GREEN)$(ENV)$(NC)"
	@make check-in-docker-reject
	@$(CADDY_DOCKER_COMPOSE_ENV_VARS) \
	$(DOCKER_COMPOSE) \
	$(CADDY_DOCKER_COMPOSE_ARGS) \
	down --remove-orphans
	@echo "Caddy service cleaned up for environment: $(GREEN)$(ENV)$(NC)"

caddy-bash caddy-shell: # View Caddy logs
	@echo "Opening shell for service: $(GREEN)caddy$(NC) in environment $(GREEN)$(ENV)$(NC)"
	@make check-caddy
	@$(CADDY_DOCKER_COMPOSE_ENV_VARS) \
	$(DOCKER_COMPOSE) \
	$(CADDY_DOCKER_COMPOSE_ARGS) \
	exec caddy /bin/sh

# caddy-check: # Check a caddy subdomain
# 	@echo "Checking Caddy subdomain for environment: $(GREEN)$(ENV)$(NC)"
# 	@make check-caddy
# 	@if [ -z "$(CADDY_CONTAINER)" ]; then \
# 		echo "CADDY_CONTAINER not set, defaulting to central-web:8000"; \
# 		CADDY_CONTAINER=central-web; \
# 	fi
# 	@CADDY_CONTAINER_ID=$$(docker ps -q -f name=caddy) || { echo "Caddy container not running"; exit 1; }
# 	@echo "Caddy container ID: $(CADDY_CONTAINER_ID)"
# 	@docker exec "$(CADDY_CONTAINER_ID)" curl -v "$(CADDY_CONTAINER):8000" || { echo "Caddy subdomain check failed"; exit 1; }

docker-status: # List containers for environment
	@echo "Listing containers for environment: $(GREEN)$(ENV)$(NC)"
	@make check-in-docker-reject
	@$(DOCKER_COMPOSE_ENV_VARS) \
	$(DOCKER_COMPOSE) \
	$(DOCKER_COMPOSE_ARGS) \
	ps --format '{{.ID}} - {{.Names}} - {{.Image}} - {{ .Ports }} - {{.Status}}'

.PHONY: image images
image images: # List images for environment
	@echo "Listing images for environment: $(GREEN)$(ENV)$(NC)"
	@make check-in-docker-reject
	@docker images --format '{{.ID}}: {{.Repository}}:{{.Tag}} - {{.Size}}'

pull: # Pull the services
	@echo "Pulling for environment: $(GREEN)$(ENV)$(NC)"
	@make check-in-docker-reject
	@docker pull ghcr.io/rsginc/rmove-central:$(TAG)

push: # Push the services (only for deploy)
	@echo "Pushing for environment: $(GREEN)$(ENV)$(NC)"
	@make check-in-docker-reject
	@if [ -z "$(FORCE_YES)" ]; then \
		read -p "Are you sure you want to push the image? [y/N] " -n 1 -r; \
		echo ""; \
		if [[ ! $$REPLY =~ ^[Yy]$$ ]]; then \
			echo "Exiting.."; \
			exit 1; \
		fi; \
	fi
	@docker push ghcr.io/rsginc/rmove-central:$(TAG)

.PHONY: build
build: # Build the services for environment
	@echo "Building $(GREEN)$(TARGET)$(NC) for environment: $(GREEN)$(ENV)$(NC)"
	@make check-in-docker-reject
	@docker build \
	-f $(BUILD_FILE) \
	-t ghcr.io/rsginc/rmove-central:$(TAG) \
	--build-arg LOCAL_UID=$(LOCAL_UID) \
	--build-arg LOCAL_GID=$(LOCAL_GID) \
	--progress=plain .
	@echo "Image built: ghcr.io/rsginc/rmove-central:$(TAG)"
	@echo "Next step usually is to run '$(GREEN)make up$(NC)' "
	@echo "Run '$(GREEN)make help$(NC)' for more commands"

.PHONY: rebuild
rebuild: # Rebuild the services (no cache)
	@echo "Re-building $(GREEN)$(TARGET)$(NC) for environment: $(GREEN)$(ENV)$(NC)"
	@make check-in-docker-reject
	@docker build \
	--no-cache \
	-f $(BUILD_FILE) \
	-t ghcr.io/rsginc/rmove-central:$(TAG) \
	--build-arg LOCAL_UID=$(LOCAL_UID) \
	--build-arg LOCAL_GID=$(LOCAL_GID) \
	--progress=plain .
	@echo "Image built: ghcr.io/rsginc/rmove-central:$(TAG)"
	@echo "Next step usually is to run '$(GREEN)make up$(NC)'"
	@echo "Run '$(GREEN)make help$(NC)' for more commands"

up: # Start the services in detached mode for environment
	@make check-rmove-network
	@make check-port
	@echo "Starting $(GREEN)$(TARGET)$(NC) for environment: $(GREEN)$(ENV)$(NC)"
	@make check-in-docker-reject
	@make check-data_dir
	@$(DOCKER_COMPOSE_ENV_VARS) \
	$(DOCKER_COMPOSE) \
	$(DOCKER_COMPOSE_ARGS) \
	up -d --remove-orphans
	@echo "Services started for environment: $(GREEN)$(ENV)$(NC)"
	@echo "To view logs, run '$(GREEN)make logs$(NC)'"
	@echo "Next step usually is to run '$(GREEN)DB_BACKUP=path/to/backup/file.db make restore-db$(NC)'"
	@echo "simply '$(GREEN)DB_BACKUP=file.db make restore-db$(NC)' if in the same directory "
	@if [ -n "$$(docker ps -q -f name=caddy)" ]; then \
        echo "Caddy is running. You can view the current domains by running $(GREEN)make caddy-ls$(NC)"; \
    else \
        echo "Caddy is $(BOLD)$(RED)NOT$(NC) running. Start it with $(GREEN)make caddy-up$(NC)"; \
    fi
	@echo "Run '$(GREEN)make help$(NC)' for more commands"

down: # Stop the services in environment
	@echo "Stopping $(GREEN)$(TARGET)$(NC) for environment: $(GREEN)$(ENV)$(NC)"
	@make check-in-docker-reject
	@$(DOCKER_COMPOSE_ENV_VARS) \
	$(DOCKER_COMPOSE) \
	$(DOCKER_COMPOSE_ARGS) \
	down
	@echo "Services stopped for environment: $(GREEN)$(ENV)$(NC)"
	@echo "Consider running '$(GREEN)make clean$(NC)' to remove unused resources"

restart: # Restart a specific service in environment
	@echo "Restarting service: $(GREEN)$(TARGET)$(NC) in environment $(GREEN)$(ENV)$(NC)"
	@make check-in-docker-reject
	@$(DOCKER_COMPOSE_ENV_VARS) \
	$(DOCKER_COMPOSE) \
	$(DOCKER_COMPOSE_ARGS) \
	restart
	@echo "Service restarted: $(GREEN)$(TARGET)$(NC) in environment $(GREEN)$(ENV)$(NC)"

build-up: # Build and start the services in detached mode for environment
	@echo "Building and starting services for environment: $(GREEN)$(ENV)$(NC)"
	@make check-in-docker-reject
	@make build
	@make up

.PHONY: log logs
log logs: # View logs for specific service in environment
	@echo "Showing logs for service $(GREEN)$(SERVICE)$(NC) in environment $(GREEN)$(ENV)$(NC)"
	@echo "To view other services, run '$(GREEN)make logs SERVICE=service_name$(NC)'"
	@make check-in-docker-reject
	@$(DOCKER_COMPOSE_ENV_VARS) \
	$(DOCKER_COMPOSE) \
	$(DOCKER_COMPOSE_ARGS) \
	logs -f $(SERVICE) | { if [ -n "$(GREP)" ]; then grep --color=auto "$(GREP)"; else cat; fi; }

clean-container clean-containers: # Clean up unused Docker containers
	@echo "Cleaning up unused Docker containers.."
	@make check-in-docker-reject
	@docker container prune -f --filter "label=project=$(PROJECT_NAME)"

clean-image clean-images: # Clean up unused Docker images
	@echo "Cleaning up unused Docker images.."
	@make check-in-docker-reject
	@docker image prune -a -f --filter "label=project=$(PROJECT_NAME)"

clean-volume clean-volumes: # Clean up unused Docker volumes
	@echo "Cleaning up unused Docker volumes.."
	@make check-in-docker-reject
	@docker volume prune -f --filter "label=project=$(PROJECT_NAME)"

clean-network: # Clean up unused Docker networks
	@echo "Cleaning up unused Docker networks.."
	@make check-in-docker-reject
	@docker network prune -f --filter "label=project=$(PROJECT_NAME)"

.PHONY: clean
clean: # Clean up unused Docker resources (containers, images, volumes)
	@echo "Cleaning up unused Docker resources.."
	@make check-in-docker-reject
	@make clean-containers
	@make clean-image
	@make clean-volume
	@docker buildx prune -f
	@docker network prune -f --filter "label=project=$(PROJECT_NAME)"
	@docker system prune --volumes -af --filter "label=project=$(PROJECT_NAME)"

.PHONY: purge
purge: # Purge all Docker resources (containers, images, volumes, networks)
	@echo "$(RED)WARNING$(NC): This command will $(RED)remove ALL stopped$(NC) $(YELLOW)containers$(NC), $(RED)ALL unused$(NC) $(YELLOW)images$(NC), and $(RED)ALL unused$(NC) $(YELLOW)volumes$(NC)"
	@echo "This is a $(RED)destructive$(NC) operation and may effect $(RED)ALL$(NC) your Docker projects."
	@if [ -z "$(FORCE_YES)" ]; then \
		read -p "Are you sure you want to proceed? [y/N] " -n 1 -r; \
		echo ""; \
		if [[ ! $$REPLY =~ ^[Yy]$$ ]]; then \
			echo "Exiting.."; \
			exit 1; \
		fi; \
	fi
	@echo "Purging all Docker resources.."
	@make check-in-docker-reject
	@docker container prune -f
	@docker image prune -a -f
	@docker volume prune -f
	@docker network prune -f
	@docker buildx prune -f
	@docker system prune --volumes -af

.PHONY: bash shell
### TODO: shell with rmoves user, or current user
bash shell: # Shell into running container
	@echo "Opening shell for service: $(GREEN)$(TARGET)$(NC) in environment $(GREEN)$(ENV)$(NC)"
	@if [ $(IN_DOCKER) = "true" ]; then \
		echo "Already inside container"; \
	else \
		$(EXEC_CMD) /bin/bash; \
	fi

.PHONY: psql
psql: # Shell into running db container
	@echo "Opening psql for service: $(GREEN)$(TARGET)$(NC) in environment $(GREEN)$(ENV)$(NC)"
	@TARGET=${PROJECT_NAME}-${POSTGRES_HOST:-db} $(EXEC_CMD) psql -U $(POSTGRES_USER) -d $(POSTGRES_DB)

## Django specific commands
django-shell: # Shell into running container
	@echo "Opening shell within django.."
	@$(MANAGE_CMD) shell

.PHONY: migrate
migrate: # Migrate database for Django
	@echo "Applying database migrations.."
	@$(MANAGE_CMD) migrate

.PHONY: checkmigrations
checkmigrations: # Check migrations for Django
	@echo "Checking migrations.."
	@$(MANAGE_CMD) makemigrations --check --no-input --dry-run

.PHONY: makemigrations
makemigrations: # Make migrations for Django
	@echo "Creating new migrations.."
	@$(MANAGE_CMD) makemigrations

.PHONY: su superuser createsuperuser
su superuser createsuperuser: # Create superuser for Django
	@echo "Creating Django superuser.."
	@$(MANAGE_CMD) createsuperuser

.PHONY: collectstatic
collectstatic: # Collect static files
	@echo "Collecting static files.."
	@$(MANAGE_CMD) collectstatic --noinput

create-groups: # Create group for Django
	@echo "Creating group.."
	@$(MANAGE_CMD) create_groups

generate-study-stack-dbs: # Create study stack databases
	@echo "Creating study stack databases.."
	@if [ -z "$(STUDY_ID)" ]; then \
		echo "STUDY_ID not set"; \
		exit 1; \
	fi
	@$(MANAGE_CMD) generate_study_stack_dbs --study_id $(STUDY_ID)

sync-db-name: # Sync stack databases
	@echo "Syncing study stack databases.."
	@if [ -z "$(STUDY_ID)" ]; then \
		echo "STUDY_ID not set"; \
		exit 1; \
	fi
	@if [ -z "$(DB_NAME)" ]; then \
		echo "DB_NAME not set"; \
		exit 1; \
	fi
	@$(MANAGE_CMD) sync_db_name --study_id $(STUDY_ID) --db_name $(DB_NAME)

.PHONY: check django-check
### TODO double check pre ver 4
check django-check: # Run manage.py check to validate Django system
	@echo "Running Django system check.."
	@$(MANAGE_CMD) check

.PHONY: set-default-release-branch
set-default-release-branch: # Set the default release branch for swarm studies
	@echo "Setting default release branch.."
	@if [ -z "$(BRANCH_VALUE)" ]; then \
		echo "BRANCH_VALUE not set"; \
		exit 1; \
	fi
	@$(MANAGE_CMD) set_default_release_branch $(BRANCH_VALUE)

.PHONY: sync-default-release-branch
sync-default-release-branch: # Sync release_branch for unlocked studies
	@echo "Syncing default release branch to unlocked studies.."
	@$(MANAGE_CMD) sync_default_release_branch
	@echo "Default release branch synced to unlocked studies"

.PHONY: loaddata load-fixture
## Database commands
loaddata load-fixture: # Load initial data for Django
	@echo "Loading data.."
	@if [ -z "$(FIXTURE_PATH)" ]; then \
		echo "FIXTURE_PATH not set, loading defaults"; \
		echo "--fixtures/groups.json"; \
		$(MANAGE_CMD) loaddata fixtures/groups.json; \
	else \
		echo "Loading fixture from: $(FIXTURE_PATH)"; \
		$(MANAGE_CMD) loaddata $(FIXTURE_PATH); \
	fi

### @$(MANAGE_CMD) loaddata fixtures/groups.json

clear-db setup-db: # Setup database for local development
	@if [ -z "$(FORCE_YES)" ]; then \
		read -p "Are you sure you want to reset the database? This will erase existing data! [y/N] " -n 1 -r; \
		echo ""; \
		if [[ ! $$REPLY =~ ^[Yy]$$ ]]; then \
			echo "Exiting.."; \
			exit 1; \
		fi; \
	fi
	@echo "Setting up db for local development"
	@make check-local-env-only

	@$(EXEC_CMD) psql -h $(POSTGRES_HOST) -U $(POSTGRES_USER) postgres -c "DROP DATABASE IF EXISTS $(POSTGRES_DB);"
	@$(EXEC_CMD) psql -h $(POSTGRES_HOST) -U $(POSTGRES_USER) postgres -c "CREATE DATABASE $(POSTGRES_DB) ENCODING='UTF8';"
	@$(EXEC_CMD) psql -h $(POSTGRES_HOST) -U $(POSTGRES_USER) postgres -c "GRANT ALL PRIVILEGES ON DATABASE $(POSTGRES_DB) TO $(POSTGRES_USER);"
	@echo "Database setup complete."

# refresh-test-db: # Refresh test database (not implemented)
# 	@echo "Refreshing test database.."
# 	@echo "not implemented"
### 	@$(MANAGE_CMD) flush --no-input
### 	@$(MANAGE_CMD) loaddata test_dump.json

.PHONY: dump backup-db pg-dump
dump backup-db pg-dump: # Backup database
	@echo "Backing up the database.."
	@make check-local-env-only

	@if [ "$(DB_BACKUP_OUTPUT)" == "db-backup" ]; then \
		echo "DB_BACKUP_OUTPUT might not be set. Using default value $(GREEN)db-backup$(NC)."; \
	fi
	@echo "DB_BACKUP_OUTPUT set to: $(DB_BACKUP_OUTPUT)"
	@make setup-pgpass

	@echo "Dumping db to $(DB_BACKUP_OUTPUT).db.."
	@$(EXEC_CMD) pg_dump -F c -v -U $(POSTGRES_USER) -h $(POSTGRES_HOST) -p $(POSTGRES_PORT) $(POSTGRES_DB) -f $(DB_BACKUP_OUTPUT).db
	@echo "Database backed up to $(GREEN)$(DB_BACKUP_OUTPUT).db$(NC)."; \

restore-db: # Restore database from backup (requires DB_BACKUP: backup db file)
	@if [ -z "$(FORCE_YES)" ]; then \
		read -p "Are you sure you want to restore the database? [y/N] " -n 1 -r; \
		echo ""; \
		if [[ ! $$REPLY =~ ^[Yy]$$ ]]; then \
			echo "Exiting.."; \
			exit 1; \
		fi; \
	fi
	@echo "Restoring the database from a backup.."

	@if [ -z "$(DB_BACKUP)" ]; then \
		echo "DB_BACKUP not found, please add arg to .env or"; \
		echo "run '$(GREEN)make restore-db path/to/backup/file.sql$(NC)'"; \
		exit 1; \
	else \
		echo "DB_BACKUP set to: $(DB_BACKUP)"; \
	fi

	@if [ -f "$(DB_BACKUP)" ]; then \
		echo "DB_BACKUP found, using file: $(GREEN)$(DB_BACKUP)$(NC)"; \
	else \
		echo "DB_BACKUP $(DB_BACKUP) not found, please double check path"; \
		exit 1; \
	fi; \

	@make check-local-env-only
	@make setup-pgpass
	@-$(EXEC_CMD) pg_restore -c -v --host $(POSTGRES_HOST) -U $(POSTGRES_USER) --dbname=$(POSTGRES_DB) --no-owner --no-privileges $(DB_BACKUP)
	@echo "Database restored from $(GREEN)$(DB_BACKUP)$(NC)"

	@make migrate

.PHONY: refresh
## Management commands
refresh:
	@echo "$(GREEN)Refreshing..tmp$(NC)"
	@if [ $(IN_DOCKER) = "true" ]; then \
		$(EXEC_CMD) service gunicorn restart; \
	else \
		printf "$(shell tput setaf 6)---Docker containers---$(NC):\n"; \
		sudo systemctl restart gunicorn-central; \
	fi

restart-gunicorn: # Restart Gunicorn within the container
	@make check-in-docker-only
	@echo "Restarting $(GREEN)Gunicorn$(NC).."
	@$(EXEC_CMD) service gunicorn restart

restart-services: # Restart all services within the container
	@make check-in-docker-only
	@echo "Restarting $(GREEN)all services$(NC).."
	@$(EXEC_CMD) service gunicorn restart

.PHONY: status
## Testing and linting
status: # Display both docker and django status
	@printf "$(H2)---Makefile status---$(NC):\n"
	@make make-check

	@printf "$(H2)---Django status---$(NC):\n"
	@make django-check

	@echo "Listing containers for environment: $(GREEN)$(ENV)$(NC)"

	@if [ $(IN_DOCKER) = "true" ]; then \
		echo "Currently inside container, skipping docker status"; \
	else \
		printf "$(H2)---Docker containers---$(NC):\n"; \
		make docker-status; \
	fi

.PHONY: test tests
### TODO consider pytest-xdist for parallel testing ex pytest -n 4 -x
test tests: # Run tests with pytest within the container (optional TEST_PATH: path to test)
	@echo "Running tests.."
	@make check-non-deploy-env-only
	@if [ -z "$(TEST_PATH)" ]; then \
		printf "Running $(H1)all tests$(NC)\n"; \
	else \
		printf "Running tests for path: $(H1)$(TEST_PATH)$(NC)\n"; \
	fi

	@$(EXEC_CMD) ./run-test $(TEST_PATH);

.PHONY: test-coverage
test-coverage: # Run tests with coverage within the container
	@echo "Running tests and coverage.."
	@make check-on-deploy-env-only

	@$(EXEC_CMD) ./run-test --cov=.

.PHONY: lint
lint: # Run linting with pre-commit within the container
	@echo "Running lint.."
	@make check-non-deploy-env-only

	@$(EXEC_CMD) pre-commit run --all-files

.PHONY: help
## Help and variable check
help: # Default help command
	@echo "$(H1)Usage$(NC):"
	@echo "  make [command] <>"
	@echo "  examples:"
	@echo "           make build"
	@echo "           make logs db"
	@echo "           make test tests/api/test_set_locale.py"
	@echo "$(H1)Environment Variables:$(NC) (run '$(GREEN)make make-check$(NC)' to see more)"
	@echo "  ENV: $(ENV)"
	@echo "  TARGET: $(TARGET)"
	@echo "  TAG: $(TAG)"
	@echo "$(H1)Common Commands:$(NC) $(GREEN)build, up, logs, test, lint, help$(NC)"
	@echo "$(H1)Available Commands:$(NC)"
	@grep -E '^(## |[a-zA-Z0-9 _-]+:.*#)' Makefile | grep -v '^###' | grep -Ev "^($(EXCLUDE_PATTERN)):" | while read -r line; do \
		if echo "$$line" | grep -q '^##'; then \
			printf "$(H2)$$(echo $$line | sed 's/^## //')$(NC)\n"; \
		else \
			cmd=$$(echo $$line | cut -f 1 -d':'); \
			desc=$$(echo $$line | cut -f 2- -d'#'); \
			printf "    $(GREEN)$$cmd$(NC):$$desc\n"; \
		fi; \
	done

make-check: # Check current environment variable
	@echo "$(H1)Makefile Variables$(NC):"
	@echo "ARCH: $(ARCH)"
	@echo "PROJECT_NAME: $(PROJECT_NAME)"
	@echo "COMPOSE_PROFILES: $(COMPOSE_PROFILES)"
	@echo "USER_NAME: $(USER_NAME)"
	@echo "GROUP_NAME: $(GROUP_NAME)"
	@echo "LOCAL_UID: $(LOCAL_UID)"
	@echo "LOCAL_GID: $(LOCAL_GID)"
	@echo "ENV: $(ENV)"
	@echo "SERVICE: $(SERVICE)"
	@echo "TARGET: $(TARGET)"
	@echo "TAG: $(TAG)"
	@echo "DATA_DIR: $(DATA_DIR)"
	@echo "COMPOSE_FILE: $(COMPOSE_FILE)"
	@echo "BUILD_FILE: $(BUILD_FILE)"
	@echo "EXEC_CMD: $(EXEC_CMD)"
	@echo "MANAGE_CMD: $(MANAGE_CMD)"
	@echo "GITHUB_ACTIONS: $(GITHUB_ACTIONS)"
	@echo "IN_DOCKER: $(IN_DOCKER)"
	@echo "POSTGRES_HOST: $(POSTGRES_HOST)"
	@echo "POSTGRES_DB: $(POSTGRES_DB)"
	@echo "POSTGRES_PORT: $(POSTGRES_PORT)"
	@echo "POSTGRES_USER: $(POSTGRES_USER)"
	@echo "PORT_OFFSET: $(PORT_OFFSET)"
	@echo "HOST_WEB_PORT: $(HOST_WEB_PORT)"
	@echo "HOST_POSTGRES_PORT: $(HOST_POSTGRES_PORT)"
	@echo "HOST_DEBUGGER_PORT: $(HOST_DEBUGGER_PORT)"
	@echo "HOST_MAILHOG_PORT: $(HOST_MAILHOG_PORT)"
	@echo "HOST_MAILHOG_WEB_PORT: $(HOST_MAILHOG_WEB_PORT)"
	@echo "AZ_CONFIG_DIR: $(AZ_CONFIG_DIR)"
	@echo "PROJECT_HOST_DIR: $(PROJECT_HOST_DIR)"
	@echo "CADDY_LABEL: $(CADDY_LABEL)"
	@echo "BASE_CERT_FILE_PATH: $(BASE_CERT_FILE_PATH)"
	@echo "BASE_KEY_FILE_PATH: $(BASE_KEY_FILE_PATH)"
	@echo "CERT_FILE_PATH: $(CERT_FILE_PATH)"
	@echo "KEY_FILE_PATH: $(KEY_FILE_PATH)"
	@echo "SUBDOMAIN: $(SUBDOMAIN)"

.SILENT: # Suppress command output

### Special targets for arguments
%:
	@:
