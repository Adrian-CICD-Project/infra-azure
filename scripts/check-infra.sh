#!/bin/bash

set -e

# --- KONFIGURACJA ---
RESOURCE_GROUP="rg-devops-poc01"
AKS_TEST="devops-poc01-test"
AKS_PROD="devops-poc01-prod"
ACR_NAME="acrfordevopspoc01adrian"

# ile prób czekania na IP LoadBalancera ArgoCD
MAX_RETRIES=20
SLEEP_SECONDS=15

echo "========================================="
echo "  CHECK INFRA – DEVOPS POC01"
echo "========================================="

echo
echo "1) Sprawdzam Resource Group: ${RESOURCE_GROUP}"
if az group show -n "${RESOURCE_GROUP}" >/dev/null 2>&1; then
  echo "   ✅ Resource Group istnieje"
else
  echo "   ❌ Resource Group NIE istnieje"
  exit 1
fi

echo
echo "2) Sprawdzam ACR: ${ACR_NAME}"
if az acr show -n "${ACR_NAME}" -g "${RESOURCE_GROUP}" >/dev/null 2>&1; then
  echo "   ✅ ACR istnieje"
else
  echo "   ❌ ACR nie istnieje albo jest w innym RG"
  exit 1
fi

echo
echo "3) Sprawdzam AKS TEST: ${AKS_TEST}"
if az aks show -g "${RESOURCE_GROUP}" -n "${AKS_TEST}" >/dev/null 2>&1; then
  STATE_TEST=$(az aks show -g "${RESOURCE_GROUP}" -n "${AKS_TEST}" --query "powerState.code" -o tsv 2>/dev/null || echo "unknown")
  echo "   ✅ AKS TEST istnieje, powerState: ${STATE_TEST}"
else
  echo "   ❌ AKS TEST nie istnieje"
  exit 1
fi

echo
echo "4) Sprawdzam AKS PROD: ${AKS_PROD}"
if az aks show -g "${RESOURCE_GROUP}" -n "${AKS_PROD}" >/dev/null 2>&1; then
  STATE_PROD=$(az aks show -g "${RESOURCE_GROUP}" -n "${AKS_PROD}" --query "powerState.code" -o tsv 2>/dev/null || echo "unknown")
  echo "   ✅ AKS PROD istnieje, powerState: ${STATE_PROD}"
else
  echo "   ❌ AKS PROD nie istnieje"
  exit 1
fi

# Funkcja: czekanie na IP ArgoCD + wyciągnięcie hasła
get_argocd_info() {
  local CLUSTER_NAME="$1"

  echo
  echo "========================================="
  echo "  ARGOCD – CLUSTER: ${CLUSTER_NAME}"
  echo "========================================="

  echo "→ Pobieram kubeconfig dla ${CLUSTER_NAME}"
  az aks get-credentials -g "${RESOURCE_GROUP}" -n "${CLUSTER_NAME}" --admin --overwrite-existing >/dev/null

  echo "→ Sprawdzam namespace 'argocd'"
  if ! kubectl get ns argocd >/dev/null 2>&1; then
    echo "   ❌ Namespace 'argocd' nie istnieje w klastrze ${CLUSTER_NAME}"
    return 1
  fi
  echo "   ✅ Namespace 'argocd' istnieje"

  echo "→ Czekam na IP z LoadBalancera (svc argocd-server)..."
  local IP=""
  local i=1
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
    echo "   ❌ Nie udało się pobrać IP dla argocd-server w klastrze ${CLUSTER_NAME}"
  else
    echo "   🌐 ArgoCD URL (HTTP):  http://${IP}"
  fi

  echo
  echo "→ Pobieram hasło admina z secreta 'argocd-initial-admin-secret'"
  if kubectl -n argocd get secret argocd-initial-admin-secret >/dev/null 2>&1; then
    PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d 2>/dev/null || true)
    if [ -n "$PASSWORD" ]; then
      echo "   ✅ Hasło odczytane"
      echo "   👤 Login:    admin"
      echo "   🔑 Password: ${PASSWORD}"
    else
      echo "   ❌ Secret istnieje, ale nie udało się zdekodować hasła"
    fi
  else
    echo "   ❌ Secret 'argocd-initial-admin-secret' nie istnieje w klastrze ${CLUSTER_NAME}"
  fi
}

echo
echo "5) Sprawdzam ArgoCD na TEST (devops-poc01-test)"
get_argocd_info "${AKS_TEST}" || echo "   ⚠ problem z ArgoCD na TEST"

echo
echo "6) Sprawdzam ArgoCD na PROD (devops-poc01-prod)"
get_argocd_info "${AKS_PROD}" || echo "   ⚠ problem z ArgoCD na PROD"

echo
echo "========================================="
echo "  CHECK COMPLETE"
echo "========================================="
