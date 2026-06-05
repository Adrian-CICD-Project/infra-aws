#!/bin/bash
set -e

REGION="${AWS_REGION:-eu-west-1}"
CLUSTERS=("devops-poc01-test" "devops-poc01-prod")

MAX_RETRIES=20
SLEEP_SECONDS=15

echo "=== Dodaję repo Helm Argo ==="
helm repo add argo https://argoproj.github.io/argo-helm >/dev/null 2>&1 || true
helm repo update

for CLUSTER in "${CLUSTERS[@]}"; do
  echo
  echo "========================================="
  echo "  ARGOCD + NAMESPACES DLA KLASTRA: ${CLUSTER}"
  echo "========================================="

  echo "→ Pobieram kubeconfig (aws eks update-kubeconfig)..."
  aws eks update-kubeconfig --region "${REGION}" --name "${CLUSTER}"

  echo "→ Tworzę namespace argocd..."
  kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -

  echo "→ Tworzę wymagane namespace'y środowiskowe..."
  if [ "${CLUSTER}" = "devops-poc01-test" ]; then
    NS_ENV_LIST=("environment-dev" "environment-test")
  else
    NS_ENV_LIST=("environment-prod")
  fi
  for NS in "${NS_ENV_LIST[@]}"; do
    echo "   - ${NS}"
    kubectl create namespace "${NS}" --dry-run=client -o yaml | kubectl apply -f -
  done

  echo "→ Tworzę namespace'y dla narzędzi platformowych..."
  for NS in sonarqube dependency-track monitoring external-secrets; do
    echo "   - ${NS}"
    kubectl create namespace "${NS}" --dry-run=client -o yaml | kubectl apply -f -
  done

  echo "→ Instaluję / aktualizuję ArgoCD przez Helm..."
  helm upgrade --install argocd argo/argo-cd \
    --namespace argocd \
    --set server.service.type=LoadBalancer \
    --wait

  echo "→ Czekam aż 'argocd-server' będzie gotowy..."
  kubectl -n argocd rollout status deploy argocd-server --timeout=300s || echo "   ❌ argocd-server NIE gotowy"

  echo "→ Czekam na adres LoadBalancera (AWS zwraca hostname ELB)..."
  ADDR=""
  i=1
  while [ $i -le $MAX_RETRIES ]; do
    ADDR=$(kubectl -n argocd get svc argocd-server -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || true)
    if [ -n "$ADDR" ]; then
      echo "   ✅ Adres po ${i} próbach: ${ADDR}"
      break
    fi
    echo "   ...jeszcze brak adresu, próba ${i}/${MAX_RETRIES}, czekam ${SLEEP_SECONDS}s"
    sleep "${SLEEP_SECONDS}"
    i=$((i+1))
  done
  [ -n "$ADDR" ] && echo "   🌐 ArgoCD URL: http://${ADDR}" || echo "   ❌ Brak adresu LB dla ${CLUSTER}"

  echo "→ Hasło admina:"
  kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' 2>/dev/null | base64 -d && echo " (login: admin)" || echo "   ❌ Brak secreta"
done

echo
echo "  INSTALACJA ARGOCD ZAKOŃCZONA"
