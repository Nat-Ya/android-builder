#!/bin/bash
# Check available secrets in cloud providers

set -e

echo "Checking available secrets..."

# Check GCP
if command -v gcloud &> /dev/null; then
  if gcloud auth list --filter=status:ACTIVE --format="value(account)" &> /dev/null; then
    echo "✅ GCP: Authenticated"
    echo "  Available secrets:"
    gcloud secrets list --format="table(name)" 2>/dev/null || echo "  (No secrets found)"
  else
    echo "⚠️  GCP: Not authenticated"
  fi
else
  echo "⚠️  GCP: CLI not installed"
fi

# Check AWS
if command -v aws &> /dev/null; then
  if aws sts get-caller-identity &> /dev/null; then
    echo "✅ AWS: Authenticated"
    echo "  Account ID: $(aws sts get-caller-identity --query Account --output text)"
    echo "  Available secrets:"
    aws secretsmanager list-secrets --query 'SecretList[].Name' --output table 2>/dev/null || echo "  (No secrets found)"
  else
    echo "⚠️  AWS: Not authenticated"
  fi
else
  echo "⚠️  AWS: CLI not installed"
fi

# Check Azure
if command -v az &> /dev/null; then
  if az account show &> /dev/null; then
    echo "✅ Azure: Authenticated"
    echo "  Subscription: $(az account show --query name --output tsv)"
    echo "  Available key vaults:"
    az keyvault list --query '[].name' --output table 2>/dev/null || echo "  (No key vaults found)"
  else
    echo "⚠️  Azure: Not authenticated"
  fi
else
  echo "⚠️  Azure: CLI not installed"
fi

echo ""
echo "✅ Secret check completed"

