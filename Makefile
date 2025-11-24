# EcoVolt Infrastructure Makefile
# Usage: make <command> <environment>
# Example: make plan dev

.PHONY: help init validate fmt plan apply destroy output clean test simulate

# Colors for output
RED := \033[0;31m
GREEN := \033[0;32m
YELLOW := \033[0;33m
BLUE := \033[0;34m
NC := \033[0m # No Color

help: ## Show this help message
	@echo "$(BLUE)EcoVolt Infrastructure Management$(NC)"
	@echo ""
	@echo "$(YELLOW)Initialization (First Time):$(NC)"
	@echo "  make init-dev                - Initialize for dev environment"
	@echo "  make init-staging            - Initialize for staging environment"
	@echo "  make init-prod               - Initialize for production environment"
	@echo ""
	@echo "$(YELLOW)Common Commands:$(NC)"
	@echo "  make validate                - Validate configuration"
	@echo "  make fmt                     - Format Terraform files"
	@echo "  make plan <env>              - Plan infrastructure (dev|staging|prod)"
	@echo "  make apply <env>             - Apply infrastructure (dev|staging|prod)"
	@echo "  make destroy <env>           - Destroy infrastructure (dev|staging|prod)"
	@echo "  make output <env>            - Show outputs (dev|staging|prod)"
	@echo ""
	@echo "$(YELLOW)Examples:$(NC)"
	@echo "  make init-dev                - Initialize dev (first time)"
	@echo "  make plan dev                - Plan dev environment"
	@echo "  make apply prod              - Apply prod environment"
	@echo "  make output staging          - Show staging outputs"
	@echo ""
	@echo "$(YELLOW)Additional Commands:$(NC)"
	@echo "  make test                    - Run Terratest property tests"
	@echo "  make simulate <env>          - Run IoT simulator for environment"
	@echo "  make security-scan           - Run tfsec security scan"
	@echo "  make cost-estimate <env>     - Estimate costs with infracost"
	@echo "  make clean                   - Clean temporary files"
	@echo ""
	@echo "$(BLUE)Backend: thekloudwiz-tf-state-bucket/project-ecovolt/<env>-tf.state$(NC)"

# Environment validation
check-env:
	@if [ -z "$(filter-out $@,$(MAKECMDGOALS))" ]; then \
		echo "$(RED)Error: Environment not specified$(NC)"; \
		echo "Usage: make $(word 1,$(MAKECMDGOALS)) <environment>"; \
		echo "Valid environments: dev, staging, prod"; \
		exit 1; \
	fi
	@ENV=$(filter-out $@,$(MAKECMDGOALS)); \
	if [ ! -f "environments/$$ENV.tfvars" ]; then \
		echo "$(RED)Error: Environment file 'environments/$$ENV.tfvars' not found$(NC)"; \
		exit 1; \
	fi; \
	echo "$(GREEN)✓ Using environment: $$ENV$(NC)"

init: ## Initialize Terraform (use: make init-dev, init-staging, or init-prod)
	@echo "$(BLUE)Initializing Terraform...$(NC)"
	@echo "$(YELLOW)Note: Use environment-specific init commands:$(NC)"
	@echo "  make init-dev      - Initialize for dev"
	@echo "  make init-staging  - Initialize for staging"
	@echo "  make init-prod     - Initialize for prod"
	terraform init

init-dev: ## Initialize Terraform for dev environment
	@echo "$(BLUE)Initializing Terraform for dev...$(NC)"
	terraform init -backend-config="key=project-ecovolt/dev-tf.state"
	@echo "$(GREEN)✓ Initialized with state key: project-ecovolt/dev-tf.state$(NC)"

init-staging: ## Initialize Terraform for staging environment
	@echo "$(BLUE)Initializing Terraform for staging...$(NC)"
	terraform init -backend-config="key=project-ecovolt/staging-tf.state"
	@echo "$(GREEN)✓ Initialized with state key: project-ecovolt/staging-tf.state$(NC)"

init-prod: ## Initialize Terraform for production environment
	@echo "$(BLUE)Initializing Terraform for prod...$(NC)"
	terraform init -backend-config="key=project-ecovolt/prod-tf.state"
	@echo "$(GREEN)✓ Initialized with state key: project-ecovolt/prod-tf.state$(NC)"

validate: ## Validate Terraform configuration
	@echo "$(BLUE)Validating Terraform configuration...$(NC)"
	terraform validate
	@echo "$(GREEN)✓ Configuration is valid$(NC)"

fmt: ## Format Terraform files
	@echo "$(BLUE)Formatting Terraform files...$(NC)"
	terraform fmt -recursive
	@echo "$(GREEN)✓ Files formatted$(NC)"

plan: check-env ## Plan infrastructure changes (requires environment)
	@ENV=$(filter-out $@,$(MAKECMDGOALS)); \
	echo "$(BLUE)Planning $$ENV environment...$(NC)"; \
	terraform plan -var-file="environments/$$ENV.tfvars" -out=$$ENV.tfplan; \
	echo "$(GREEN)✓ Plan saved to $$ENV.tfplan$(NC)"

apply: check-env ## Apply infrastructure changes (requires environment)
	@ENV=$(filter-out $@,$(MAKECMDGOALS)); \
	echo "$(YELLOW)Applying $$ENV environment...$(NC)"; \
	if [ "$$ENV" = "prod" ]; then \
		echo "$(RED)WARNING: You are about to apply changes to PRODUCTION$(NC)"; \
		read -p "Type 'yes' to continue: " confirm; \
		if [ "$$confirm" != "yes" ]; then \
			echo "$(YELLOW)Aborted$(NC)"; \
			exit 1; \
		fi; \
	fi; \
	terraform apply -var-file="environments/$$ENV.tfvars"; \
	echo "$(GREEN)✓ Infrastructure applied$(NC)"

apply-plan: check-env ## Apply saved plan (requires environment)
	@ENV=$(filter-out $@,$(MAKECMDGOALS)); \
	echo "$(YELLOW)Applying saved plan for $$ENV...$(NC)"; \
	if [ ! -f "$$ENV.tfplan" ]; then \
		echo "$(RED)Error: Plan file '$$ENV.tfplan' not found$(NC)"; \
		echo "Run 'make plan $$ENV' first"; \
		exit 1; \
	fi; \
	terraform apply $$ENV.tfplan; \
	echo "$(GREEN)✓ Plan applied$(NC)"; \
	rm -f $$ENV.tfplan

destroy: check-env ## Destroy infrastructure (requires environment)
	@ENV=$(filter-out $@,$(MAKECMDGOALS)); \
	echo "$(RED)WARNING: You are about to DESTROY $$ENV infrastructure$(NC)"; \
	read -p "Type 'destroy-$$ENV' to continue: " confirm; \
	if [ "$$confirm" != "destroy-$$ENV" ]; then \
		echo "$(YELLOW)Aborted$(NC)"; \
		exit 1; \
	fi; \
	terraform destroy -var-file="environments/$$ENV.tfvars"; \
	echo "$(GREEN)✓ Infrastructure destroyed$(NC)"

output: check-env ## Show Terraform outputs (requires environment)
	@ENV=$(filter-out $@,$(MAKECMDGOALS)); \
	echo "$(BLUE)Outputs for $$ENV environment:$(NC)"; \
	terraform output

refresh: check-env ## Refresh Terraform state (requires environment)
	@ENV=$(filter-out $@,$(MAKECMDGOALS)); \
	echo "$(BLUE)Refreshing $$ENV state...$(NC)"; \
	terraform refresh -var-file="environments/$$ENV.tfvars"; \
	echo "$(GREEN)✓ State refreshed$(NC)"

show: check-env ## Show current state (requires environment)
	@ENV=$(filter-out $@,$(MAKECMDGOALS)); \
	echo "$(BLUE)Current state for $$ENV:$(NC)"; \
	terraform show

clean: ## Clean temporary files
	@echo "$(BLUE)Cleaning temporary files...$(NC)"
	rm -f *.tfplan
	rm -f .terraform.lock.hcl
	@echo "$(GREEN)✓ Cleaned$(NC)"

clean-all: ## Clean all Terraform files (including state)
	@echo "$(RED)WARNING: This will remove .terraform directory$(NC)"
	@read -p "Type 'yes' to continue: " confirm; \
	if [ "$$confirm" = "yes" ]; then \
		rm -rf .terraform/; \
		rm -f *.tfplan; \
		rm -f .terraform.lock.hcl; \
		echo "$(GREEN)✓ All cleaned$(NC)"; \
	else \
		echo "$(YELLOW)Aborted$(NC)"; \
	fi

# Testing
test: ## Run Terratest property tests
	@echo "$(BLUE)Running property-based tests...$(NC)"
	@if [ ! -d "test" ]; then \
		echo "$(RED)Error: test directory not found$(NC)"; \
		exit 1; \
	fi
	cd test && go test -v -timeout 30m ./...
	@echo "$(GREEN)✓ Tests completed$(NC)"

test-unit: ## Run unit tests only
	@echo "$(BLUE)Running unit tests...$(NC)"
	cd test && go test -v -timeout 10m -run "TestUnit" ./...
	@echo "$(GREEN)✓ Unit tests completed$(NC)"

test-properties: ## Run property tests only
	@echo "$(BLUE)Running property tests...$(NC)"
	cd test && go test -v -timeout 30m -run "TestProperty" ./...
	@echo "$(GREEN)✓ Property tests completed$(NC)"

# IoT Simulation
simulate: check-env ## Run IoT device simulator (requires environment)
	@ENV=$(filter-out $@,$(MAKECMDGOALS)); \
	echo "$(BLUE)Starting IoT simulator for $$ENV...$(NC)"; \
	if [ ! -f "scripts/iot_simulator.py" ]; then \
		echo "$(RED)Error: scripts/iot_simulator.py not found$(NC)"; \
		exit 1; \
	fi; \
	REGION=$$(terraform output -raw aws_region 2>/dev/null || echo "eu-central-1"); \
	echo "$(GREEN)Region: $$REGION$(NC)"; \
	python3 scripts/iot_simulator.py --region $$REGION --bikes 5 --stations 2

simulate-load: check-env ## Run high-load IoT simulation (requires environment)
	@ENV=$(filter-out $@,$(MAKECMDGOALS)); \
	echo "$(BLUE)Starting high-load IoT simulator for $$ENV...$(NC)"; \
	REGION=$$(terraform output -raw aws_region 2>/dev/null || echo "eu-central-1"); \
	python3 scripts/iot_simulator.py --region $$REGION --bikes 50 --stations 10 --interval 0.5

# Security and Cost
security-scan: ## Run security scan with tfsec
	@echo "$(BLUE)Running security scan...$(NC)"
	@command -v tfsec >/dev/null 2>&1 || { \
		echo "$(RED)tfsec not installed$(NC)"; \
		echo "Install: brew install tfsec (macOS) or see https://github.com/aquasecurity/tfsec"; \
		exit 1; \
	}
	tfsec . --minimum-severity MEDIUM
	@echo "$(GREEN)✓ Security scan completed$(NC)"

cost-estimate: check-env ## Estimate infrastructure costs (requires environment)
	@ENV=$(filter-out $@,$(MAKECMDGOALS)); \
	echo "$(BLUE)Estimating costs for $$ENV...$(NC)"; \
	command -v infracost >/dev/null 2>&1 || { \
		echo "$(RED)infracost not installed$(NC)"; \
		echo "Install: brew install infracost (macOS) or see https://www.infracost.io/docs/"; \
		exit 1; \
	}; \
	infracost breakdown --path . --terraform-var-file environments/$$ENV.tfvars; \
	echo "$(GREEN)✓ Cost estimate completed$(NC)"

# Documentation
docs: ## Generate module documentation
	@echo "$(BLUE)Generating documentation...$(NC)"
	@command -v terraform-docs >/dev/null 2>&1 || { \
		echo "$(RED)terraform-docs not installed$(NC)"; \
		echo "Install: brew install terraform-docs (macOS) or see https://terraform-docs.io/"; \
		exit 1; \
	}
	terraform-docs markdown table --output-file README.md --output-mode inject .
	@echo "$(GREEN)✓ Documentation generated$(NC)"

# Workspace management
workspace-list: ## List Terraform workspaces
	@echo "$(BLUE)Terraform workspaces:$(NC)"
	terraform workspace list

workspace-show: ## Show current workspace
	@echo "$(BLUE)Current workspace:$(NC)"
	terraform workspace show

# Catch-all target to prevent "No rule to make target" errors for environment names
%:
	@:

# Quick shortcuts
dev: ## Quick dev workflow (plan)
	@$(MAKE) plan dev

staging: ## Quick staging workflow (plan)
	@$(MAKE) plan staging

prod: ## Quick prod workflow (plan)
	@$(MAKE) plan prod
