#!/bin/bash
set -e

REGION="${AWS_REGION:-eu-west-1}"
CLUSTERS=("devops-poc01-test" "devops-poc01-prod")
ECR_NAME="${ECR_NAME:-adrian-java-app}"

echo "=== ECR ==="
aws ecr describe-repositories --region "$REGION" --repository-names "$ECR_NAME" \
  --query 'repositories[0].repositoryUri' --output text 2>/dev/null || echo "   ❌ Brak ECR"

for CLUSTER in "${CLUSTERS[@]}"; do
  echo
  echo "=== EKS: ${CLUSTER} ==="
  aws eks describe-cluster --region "$REGION" --name "$CLUSTER" \
    --query 'cluster.status' --output text 2>/dev/null || { echo "   ❌ Brak klastra"; continue; }

  echo "→ Node group (desired/min/max):"
  aws eks describe-nodegroup --region "$REGION" --cluster-name "$CLUSTER" --nodegroup-name systempool \
    --query 'nodegroup.scalingConfig' --output json 2>/dev/null || echo "   (brak node group)"

  echo "→ ArgoCD:"
  aws eks update-kubeconfig --region "$REGION" --name "$CLUSTER" >/dev/null 2>&1 || true
  kubectl -n argocd get pods 2>/dev/null || echo "   (brak dostępu / węzły wyłączone)"
done
