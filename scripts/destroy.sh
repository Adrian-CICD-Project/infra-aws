#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_ROOT"

echo "========================================="
echo "  DESTROY INFRASTRUCTURE (AWS)"
echo "========================================="

terraform destroy -var-file=envs/test.tfvars -auto-approve

echo "✅ Infrastruktura AWS usunięta (EKS test+prod, ECR, VPC, NAT, Secrets, auto-shutdown)."
