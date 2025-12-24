#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

# Ensure IC_API_KEY env var is set before running this script
if [ -z "${IC_API_KEY:-}" ]; then
  echo "ERROR: IC_API_KEY environment variable is not set. Export your IBM Cloud API key as IC_API_KEY and retry."
  exit 1
fi

# Initialize and create/select workspace
terraform init --upgrade
# Create workspace if it does not exist, otherwise select it
if terraform workspace list | grep -q "roks-second"; then
  terraform workspace select roks-second
else
  terraform workspace new roks-second
fi

# Plan using the roks-second.tfvars file
terraform plan -var-file=roks-second.tfvars

echo "To create the cluster run: terraform apply -var-file=roks-second.tfvars"
# The script intentionally does not auto-approve apply; run the above command interactively to confirm and monitor.

# After apply completes, use 'oc login' with the cluster API endpoint (output from terraform) and then:
#  - wait for ingress to stabilize and check router pods
#  - run: oc api-resources | grep route
#  - If Route exists and ingress healthy, proceed with the tutorial steps in patient-health-frontend/
