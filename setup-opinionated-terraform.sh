#!/bin/bash
# Setup Opinionated Terraform Project Structure

set -e

echo "🏗️ Setting up Opinionated Terraform Project Structure"

# Create directory structure
echo "📁 Creating directory structure..."
mkdir -p {modules,stacks,tools,ci,test}
mkdir -p modules/vpc/{examples,test}
mkdir -p stacks/{dev,staging,prod,local}
mkdir -p tools/{bootstrap-backend,policies}
mkdir -p ci/workflows
mkdir -p test/{unit,integration}

# Create Makefile
echo "📝 Creating Makefile..."
cat > Makefile << 'EOF'
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
EOF

# Create .pre-commit-config.yaml
echo "🔧 Creating pre-commit configuration..."
cat > .pre-commit-config.yaml << 'EOF'
repos:
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.4.0
    hooks:
      - id: trailing-whitespace
      - id: end-of-file-fixer
      - id: check-yaml
      - id: check-added-large-files

  - repo: https://github.com/antonbabenko/pre-commit-terraform
    rev: v1.83.5
    hooks:
      - id: terraform_fmt
      - id: terraform_validate
      - id: terraform_docs
        args:
          - --hook-config=--path-to-file=README.md
          - --hook-config=--add-to-existing-file=true
          - --hook-config=--create-file-if-not-exist=true
      - id: terraform_tflint
        args:
          - --args=--only=terraform_deprecated_interpolation
          - --args=--only=terraform_deprecated_index
          - --args=--only=terraform_unused_declarations
          - --args=--only=terraform_comment_syntax
          - --args=--only=terraform_documented_outputs
          - --args=--only=terraform_documented_variables
          - --args=--only=terraform_typed_variables
          - --args=--only=terraform_module_pinned_source
          - --args=--only=terraform_naming_convention
          - --args=--only=terraform_required_version
          - --args=--only=terraform_required_providers
          - --args=--only=terraform_standard_module_structure
          - --args=--only=terraform_workspace_remote

  - repo: https://github.com/Yelp/detect-secrets
    rev: v1.4.0
    hooks:
      - id: detect-secrets
        args: ['--baseline', '.secrets.baseline']
EOF

# Create .gitignore
echo "📝 Creating .gitignore..."
cat > .gitignore << 'EOF'
# Terraform
*.tfstate
*.tfstate.*
*.tfplan
*.tfvars
!*.tfvars.example
.terraform/
.terraform.lock.hcl

# IDE
.vscode/
.idea/
*.swp
*.swo

# OS
.DS_Store
Thumbs.db

# Logs
*.log

# Test artifacts
test-results/
coverage.out

# Secrets
.secrets.baseline
EOF

echo "✅ Opinionated Terraform project structure created!"
echo ""
echo "📋 Next steps:"
echo "  1. Install pre-commit: pip install pre-commit"
echo "  2. Setup pre-commit: pre-commit install"
echo "  3. Initialize development: make init ENV=dev"
echo "  4. Create your first module: ./create-vpc-module.sh"
echo ""
echo "🎯 Available commands:"
echo "  make help              # Show all available commands"
echo "  make init ENV=dev      # Initialize development environment"
echo "  make plan ENV=dev      # Plan infrastructure changes"
echo "  make security-scan     # Run security scans"
echo "  make test             # Run all tests"