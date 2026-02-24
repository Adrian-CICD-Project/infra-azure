# Azure Key Vault + External Secrets — Instrukcja wdrożenia

## Przegląd

Sekrety (klucze GitHub App, tokeny) nie są przechowywane w Git.
Zamiast tego:
- **Azure Key Vault** przechowuje sekrety
- **External Secrets Operator (ESO)** na klastrze AKS automatycznie pobiera je i tworzy Kubernetes Secrets
- **ArgoCD** używa tych K8s Secrets do klonowania prywatnych repozytoriów

```
Azure Key Vault  ──(Managed Identity)──>  ESO na AKS  ──>  K8s Secret  ──>  ArgoCD
```

---

## Wymagania

- Azure CLI zalogowany (`az login`)
- Terraform >= 1.6
- Klastry AKS uruchomione
- Plik klucza prywatnego GitHub App (`.pem`)

---

## Krok 1: Terraform — stworzenie Key Vault

Key Vault jest już zdefiniowany w module `modules/key-vault/` i wywołany w `main.tf`.

```bash
cd infra-azure

# Inicjalizacja (pobiera nowy moduł key-vault)
terraform init

# Podgląd zmian
terraform plan

# Zastosowanie
terraform apply
```

To stworzy:
- Azure Key Vault `kv-devops-poc01-adrian`
- Role assignment `Key Vault Secrets User` dla kubelet identity obu klastrów AKS
- Role assignment `Key Vault Secrets Officer` dla Twojej tożsamości Terraform

---

## Krok 2: Wrzucenie sekretów do Key Vault

Po `terraform apply`, wrzuć sekrety do vault:

```bash
VAULT_NAME="kv-devops-poc01-adrian"

# GitHub App credentials
az keyvault secret set --vault-name $VAULT_NAME \
  --name "github-app-id" \
  --value "2593082"

az keyvault secret set --vault-name $VAULT_NAME \
  --name "github-app-installation-id" \
  --value "102594758"

# Klucz prywatny — z pliku .pem
az keyvault secret set --vault-name $VAULT_NAME \
  --name "github-app-private-key" \
  --file "/sciezka/do/github-app-private-key.pem"

# URL-e repozytoriów
az keyvault secret set --vault-name $VAULT_NAME \
  --name "github-app-repo-url-platform-apps" \
  --value "https://github.com/Adrian-CICD-Project/platform-apps.git"

az keyvault secret set --vault-name $VAULT_NAME \
  --name "github-app-repo-url-env-dev" \
  --value "https://github.com/Adrian-CICD-Project/infrastructure-env-dev.git"

az keyvault secret set --vault-name $VAULT_NAME \
  --name "github-app-repo-url-env-test" \
  --value "https://github.com/Adrian-CICD-Project/infrastructure-env-test.git"

az keyvault secret set --vault-name $VAULT_NAME \
  --name "github-app-repo-url-env-prod" \
  --value "https://github.com/Adrian-CICD-Project/infrastructure-env-prod.git"

# Stałe wartości
az keyvault secret set --vault-name $VAULT_NAME \
  --name "github-app-repo-type" \
  --value "git"

az keyvault secret set --vault-name $VAULT_NAME \
  --name "github-app-project" \
  --value "default"
```

### Weryfikacja

```bash
az keyvault secret list --vault-name $VAULT_NAME -o table
```

Powinno zwrócić 8 sekretów.

---

## Krok 3: Instalacja External Secrets Operator

ESO jest zdefiniowany w `platform-apps/charts/app-of-apps/values.yaml` jako aplikacja ArgoCD.
Po uruchomieniu ArgoCD z app-of-apps, ESO zainstaluje się automatycznie.

### Weryfikacja

```bash
# Na klastrze test
az aks get-credentials --resource-group rg-devops-poc01 --name devops-poc01-test --admin
kubectl get pods -n external-secrets

# Powinno być 3 pody: external-secrets, external-secrets-webhook, external-secrets-cert-controller
```

---

## Krok 4: Aplikowanie ClusterSecretStore i ExternalSecrets

Po potwierdzeniu, że ESO działa:

```bash
cd platform-apps
kubectl apply -f bootstrap/external-secrets-config.yaml
```

To stworzy:
- `ClusterSecretStore` `azure-key-vault` — połączenie z Key Vault przez Managed Identity
- 4x `ExternalSecret` w namespace `argocd` — po jednym per repozytorium

### Weryfikacja

```bash
# Sprawdź ClusterSecretStore
kubectl get clustersecretstore azure-key-vault
# STATUS powinien być: Valid

# Sprawdź ExternalSecrets
kubectl get externalsecrets -n argocd
# Wszystkie powinny mieć STATUS: SecretSynced

# Sprawdź stworzone K8s Secrets
kubectl get secrets -n argocd | grep repo-
# Powinny być: repo-platform-apps, repo-infrastructure-env-dev, env-test, env-prod
```

---

## Krok 5: Weryfikacja ArgoCD

ArgoCD powinien teraz widzieć repozytoria:

```bash
# Sprawdź w ArgoCD CLI
argocd repo list

# Lub w ArgoCD UI → Settings → Repositories
# Wszystkie 4 repozytoria powinny mieć status CONNECTION: Successful
```

---

## Rozwiązywanie problemów

### ClusterSecretStore ma status InvalidProvider

```bash
kubectl describe clustersecretstore azure-key-vault
```

Sprawdź:
- Czy vault URL jest poprawny: `https://kv-devops-poc01-adrian.vault.azure.net/`
- Czy kubelet identity ma role `Key Vault Secrets User` na vault

### ExternalSecret ma status SecretSyncedError

```bash
kubectl describe externalsecret repo-platform-apps -n argocd
```

Sprawdź:
- Czy sekret istnieje w Key Vault: `az keyvault secret show --vault-name kv-devops-poc01-adrian --name github-app-id`
- Czy nazwa sekretu w `ExternalSecret` (remoteRef.key) zgadza się z nazwą w Key Vault

### ESO nie startuje

```bash
kubectl logs -n external-secrets deployment/external-secrets
```

Sprawdź czy CRDs się zainstalowały:
```bash
kubectl get crd | grep external-secrets
```

---

## Rotacja sekretów

Aby zmienić sekret (np. nowy klucz GitHub App):

```bash
# 1. Zaktualizuj w Key Vault
az keyvault secret set --vault-name kv-devops-poc01-adrian \
  --name "github-app-private-key" \
  --file "/sciezka/do/nowy-klucz.pem"

# 2. Poczekaj do 1h (refreshInterval) lub wymuś sync
kubectl annotate externalsecret repo-platform-apps -n argocd \
  force-sync=$(date +%s) --overwrite

# 3. Sprawdź
kubectl get externalsecret repo-platform-apps -n argocd
```

---

## Podsumowanie kolejności operacji

```
1. terraform apply          → Key Vault + RBAC
2. az keyvault secret set   → 8 sekretów w vault
3. ArgoCD app-of-apps       → ESO instaluje się automatycznie
4. kubectl apply -f bootstrap/external-secrets-config.yaml → CRDs
5. Weryfikacja              → kubectl get externalsecrets -n argocd
```
