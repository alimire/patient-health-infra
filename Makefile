.PHONY: help init plan apply destroy test security-scan docs clean

# Default environment
ENV ?= dev

# Help target
help: ## Show this help message
	@echo "Available targets:"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-15s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

init: ## Initialize Terraform for specified environment
	@echo "🔧 Initializing Terraform for $(ENV) environment..."
	cd stacks/$(ENV) && terraform init

plan: ## Plan Terraform changes for specified environment
	@echo "📋 Planning Terraform changes for $(ENV) environment..."
	cd stacks/$(ENV) && terraform plan

apply: ## Apply Terraform changes for specified environment
	@echo "🚀 Applying Terraform changes for $(ENV) environment..."
	cd stacks/$(ENV) && terraform apply

destroy: ## Destroy Terraform infrastructure for specified environment
	@echo "💥 Destroying Terraform infrastructure for $(ENV) environment..."
	cd stacks/$(ENV) && terraform destroy

test: ## Run all tests
	@echo "🧪 Running tests..."
	@$(MAKE) test-unit
	@$(MAKE) test-integration

test-unit: ## Run unit tests
	@echo "🔬 Running unit tests..."
	cd test/unit && go test -v ./...

test-integration: ## Run integration tests
	@echo "🔗 Running integration tests..."
	cd test/integration && go test -v ./...

security-scan: ## Run security scans
	@echo "🔒 Running security scans..."
	@command -v tfsec >/dev/null 2>&1 || { echo "Installing tfsec..."; go install github.com/aquasecurity/tfsec/cmd/tfsec@latest; }
	@command -v checkov >/dev/null 2>&1 || { echo "Installing checkov..."; pip install checkov; }
	tfsec .
	checkov -d .

docs: ## Generate documentation
	@echo "📚 Generating documentation..."
	@command -v terraform-docs >/dev/null 2>&1 || { echo "Installing terraform-docs..."; go install github.com/terraform-docs/terraform-docs@latest; }
	find modules -name "*.tf" -exec dirname {} \; | sort -u | xargs -I {} terraform-docs markdown table --output-file README.md {}

fmt: ## Format Terraform code
	@echo "🎨 Formatting Terraform code..."
	terraform fmt -recursive .

validate: ## Validate Terraform code
	@echo "✅ Validating Terraform code..."
	find . -name "*.tf" -exec dirname {} \; | sort -u | xargs -I {} sh -c 'cd {} && terraform init -backend=false && terraform validate'

clean: ## Clean temporary files
	@echo "🧹 Cleaning temporary files..."
	find . -type d -name ".terraform" -exec rm -rf {} +
	find . -name "*.tfplan" -delete
	find . -name "terraform.tfstate*" -delete

localstack-up: ## Start LocalStack
	@echo "🐳 Starting LocalStack..."
	cd tools && docker compose up -d

localstack-down: ## Stop LocalStack
	@echo "🛑 Stopping LocalStack..."
	cd tools && docker compose down

pre-commit: ## Run pre-commit hooks
	@echo "🔍 Running pre-commit hooks..."
	pre-commit run --all-files
