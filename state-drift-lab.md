# State Drift Practice Lab with LocalStack

## 🎯 Objective
Practice detecting, analyzing, and fixing Terraform state drift using LocalStack in a safe environment.

## 📋 Prerequisites
- LocalStack running on localhost:4566
- Terraform initialized in stacks/local/
- AWS CLI configured for LocalStack

## 🧪 Lab Exercises

### Exercise 1: Detect Current State Drift

Our LocalStack has resources that exist but aren't properly tracked in Terraform state.

```bash
# 1. Check current Terraform state
terraform show

# 2. Check what's actually in LocalStack
export AWS_ENDPOINT_URL=http://localhost:4566
aws s3 ls
aws dynamodb list-tables

# 3. Run terraform plan to see the drift
terraform plan
```

**Expected Result**: Terraform will want to create resources that already exist.

### Exercise 2: Fix State Drift with Import

```bash
# 1. Import the existing S3 bucket
terraform import aws_s3_bucket.example opinionated-terraform-local-bucket

# 2. Import the existing DynamoDB table
terraform import aws_dynamodb_table.example opinionated-terraform-local-table

# 3. Verify state is now aligned
terraform plan
```

### Exercise 3: Create Manual Drift (Simulate Real-World Scenario)

```bash
# 1. Manually add tags to the S3 bucket (simulate developer change)
aws s3api put-bucket-tagging \
  --bucket opinionated-terraform-local-bucket \
  --tagging 'TagSet=[{Key=ManualTag,Value=AddedByDeveloper}]'

# 2. Manually modify DynamoDB table (add a GSI)
aws dynamodb update-table \
  --table-name opinionated-terraform-local-table \
  --attribute-definitions AttributeName=email,AttributeType=S \
  --global-secondary-index-updates '[{
    "Create": {
      "IndexName": "email-index",
      "KeySchema": [{"AttributeName": "email", "KeyType": "HASH"}],
      "Projection": {"ProjectionType": "ALL"}
    }
  }]'

# 3. Check for drift
terraform plan
```

### Exercise 4: Analyze Drift Output

```bash
# Run detailed plan to see exactly what changed
terraform plan -out=drift.tfplan

# Show the plan in human-readable format
terraform show drift.tfplan
```

### Exercise 5: Remediation Strategies

#### Strategy A: Accept Manual Changes (Update Terraform)
```bash
# Update main.tf to include the manual tag
# Add to aws_s3_bucket.example:
tags = {
  Name        = "Local Test Bucket"
  Environment = "local"
  Project     = "opinionated-terraform"
  ManagedBy   = "terraform"
  ManualTag   = "AddedByDeveloper"  # Accept the manual change
}

# Verify alignment
terraform plan
```

#### Strategy B: Revert Manual Changes
```bash
# Remove the manual tag
aws s3api delete-bucket-tagging \
  --bucket opinionated-terraform-local-bucket

# Apply Terraform to restore desired state
terraform apply
```

### Exercise 6: State File Manipulation

```bash
# 1. View current state
terraform state list

# 2. Show specific resource state
terraform state show aws_s3_bucket.example

# 3. Remove resource from state (without destroying)
terraform state rm aws_s3_bucket.example

# 4. Verify it's gone from state but still exists in AWS
terraform state list
aws s3 ls

# 5. Re-import the resource
terraform import aws_s3_bucket.example opinionated-terraform-local-bucket
```

### Exercise 7: Backup and Recovery

```bash
# 1. Backup current state
cp terraform.tfstate terraform.tfstate.backup

# 2. Simulate state corruption
echo '{"version": 4}' > terraform.tfstate

# 3. Try to run terraform
terraform plan  # Should fail

# 4. Restore from backup
cp terraform.tfstate.backup terraform.tfstate

# 5. Verify recovery
terraform plan
```

### Exercise 8: Advanced Drift Scenarios

#### Scenario A: Resource Deleted Manually
```bash
# 1. Delete S3 bucket manually
aws s3 rb s3://opinionated-terraform-local-bucket --force

# 2. Check what terraform wants to do
terraform plan

# 3. Recreate the resource
terraform apply
```

#### Scenario B: Resource Modified Outside Terraform
```bash
# 1. Change bucket versioning manually
aws s3api put-bucket-versioning \
  --bucket opinionated-terraform-local-bucket \
  --versioning-configuration Status=Enabled

# 2. Check drift
terraform plan

# 3. Decide: accept change or revert
```

## 🎯 Practice Commands Summary

```bash
# Detection
terraform plan -detailed-exitcode  # Exit code 2 = drift detected
terraform plan -refresh-only       # Show what would be refreshed

# Analysis
terraform show                      # Current state
terraform state list               # List managed resources
terraform state show <resource>    # Show specific resource

# Remediation
terraform import <resource> <id>    # Import existing resource
terraform state rm <resource>      # Remove from state
terraform state mv <old> <new>     # Rename resource

# Recovery
terraform force-unlock <lock-id>   # Remove stuck locks
terraform refresh                  # Update state (deprecated)
```

## 🎯 Real-World Scenarios to Practice

1. **Emergency Fix**: Someone manually opens port 22 for SSH access during an incident
2. **Tag Compliance**: Security team adds compliance tags through AWS Config
3. **Resource Deletion**: Accidental deletion of critical infrastructure
4. **Configuration Drift**: Manual changes to security groups or load balancers
5. **State Corruption**: State file gets corrupted or locked

## 🎯 Success Criteria

After completing this lab, you should be able to:
- ✅ Detect state drift using terraform plan
- ✅ Import existing resources into Terraform state
- ✅ Decide when to accept vs. revert manual changes
- ✅ Manipulate state files safely
- ✅ Recover from state corruption
- ✅ Explain drift scenarios in interviews

## 🎯 Interview Preparation

Practice explaining these scenarios:
- "Tell me about a time you dealt with state drift"
- "How do you prevent infrastructure drift?"
- "What's your process for handling emergency manual changes?"