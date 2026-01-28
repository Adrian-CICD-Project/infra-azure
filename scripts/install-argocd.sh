#!/bin/bash
set -e

RESOURCE_GROUP="rg-devops-poc01"
CLUSTERS=("devops-poc01-test" "devops-poc01-prod")

# ile prób czekania na IP LB
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

  echo "→ Pobieram kubeconfig (az aks get-credentials)..."
  az aks get-credentials -g "${RESOURCE_GROUP}" -n "${CLUSTER}" --admin --overwrite-existing >/dev/null

  echo "→ Tworzę namespace argocd (jeśli nie istnieje)..."
  kubectl create namespace argocd --dry-run=client -o yaml 2>/dev/null | kubectl apply -f - >/dev/null

  echo "→ Tworzę wymagane namespace'y środowiskowe..."
  if [ "${CLUSTER}" = "devops-poc01-test" ]; then
    NS_ENV_LIST=("environment-dev" "environment-test")
  else
    NS_ENV_LIST=("environment-prod")
  fi

  for NS in "${NS_ENV_LIST[@]}"; do
    echo "   - ${NS}"
    kubectl create namespace "${NS}" --dry-run=client -o yaml 2>/dev/null | kubectl apply -f - >/dev/null
  done

  echo "→ Tworzę namespace'y dla narzędzi platformowych..."
  PLATFORM_NS=("sonarqube" "dependency-track" "monitoring")
  for NS in "${PLATFORM_NS[@]}"; do
    echo "   - ${NS}"
    kubectl create namespace "${NS}" --dry-run=client -o yaml 2>/dev/null | kubectl apply -f - >/dev/null
  done

  echo "→ Instaluję / aktualizuję ArgoCD przez Helm..."
  helm upgrade --install argocd argo/argo-cd \
    --namespace argocd \
    --set server.service.type=LoadBalancer \
    --wait

  echo "→ Czekam aż deployment 'argocd-server' będzie gotowy..."
  if kubectl -n argocd rollout status deploy argocd-server --timeout=300s; then
    echo "   ✅ argocd-server gotowy"
  else
    echo "   ❌ argocd-server NIE osiągnął stanu Ready w zadanym czasie"
  fi

  echo
  echo "→ Czekam na IP z LoadBalancera..."
  IP=""
  i=1
  while [ $i -le $MAX_RETRIES ]; do
    IP=$(kubectl -n argocd get svc argocd-server -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || true)
    if [ -n "$IP" ]; then
      echo "   ✅ Znalazłem IP po ${i} próbach: ${IP}"
      break
    fi
    echo "   ...jeszcze brak IP, próba ${i}/${MAX_RETRIES}, czekam ${SLEEP_SECONDS}s"
    sleep "${SLEEP_SECONDS}"
    i=$((i+1))
  done

  if [ -z "$IP" ]; then
    echo "   ❌ Nie udało się pobrać IP dla argocd-server w klastrze ${CLUSTER}"
  else
    echo "   🌐 ArgoCD URL (HTTP):  http://${IP}"
  fi

  echo
  echo "→ Wyciągam hasło admina z secreta 'argocd-initial-admin-secret'..."
  if kubectl -n argocd get secret argocd-initial-admin-secret >/dev/null 2>&1; then
    PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d 2>/dev/null || true)
    if [ -n "$PASSWORD" ]; then
      echo "   👤 Login:    admin"
      echo "   🔑 Password: ${PASSWORD}"
    else
      echo "   ❌ Secret jest, ale nie udało się odczytać hasła"
    fi
  else
    echo "   ❌ Secret 'argocd-initial-admin-secret' nie istnieje (może ArgoCD już zresetował hasło?)"
  fi

  echo
  echo "→ Podsumowanie namespace'ów w klastrze ${CLUSTER}:"
  kubectl get ns | egrep 'argocd|environment-|sonarqube|dependency-track|monitoring' || kubectl get ns

done

echo
echo "========================================="
echo "  INSTALACJA + NAMESPACES + WERYFIKACJA ARGOCD ZAKOŃCZONA"
echo "========================================="
