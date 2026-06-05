# Infrastructure – AWS DevOps Project

Provisioning EKS (×2), ECR, VPC, Secrets Manager, ArgoCD (via script) i auto-shutdown.
Odpowiednik `infra-azure`, dostosowany pod **niskie koszty**.

---

## Overview

Repozytorium zawiera kompletny kod Terraform IaC dla warstwy AWS projektu DevOps:

- VPC + podsieci (2 AZ) + 1× NAT Gateway
- Amazon ECR (rejestr obrazów – odpowiednik ACR)
- Klastry EKS:
  - **devops-poc01-test**
  - **devops-poc01-prod**
- Węzły robocze na **EC2** (managed node group, `t3.large`, scale-to-zero)
- AWS Secrets Manager + rola IRSA dla External Secrets Operator (odpowiednik Key Vault)
- Auto-shutdown (EventBridge Scheduler + Lambda) – codziennie 18:00 skaluje węzły do 0

> **ArgoCD** nie jest wdrażany przez Terraform – instaluje go skrypt `install-argocd.sh`
> (ten sam wzorzec co w `infra-azure`).

---

## Mapowanie Azure → AWS

| Rola | Azure | AWS |
|---|---|---|
| Sieć | VNet | VPC + subnety + NAT |
| Rejestr obrazów | ACR | ECR |
| Klaster K8s | AKS | EKS (control plane) |
| Węzły | VM `Standard_B4ms` | **EC2** `t3.large` |
| Sekrety | Key Vault | Secrets Manager |
| Auto-shutdown | Automation Account | EventBridge Scheduler + Lambda |

Pełny opis komponentów: `documentation/multicloud-infrastructure.md`.

---

## Repository Structure

```
infra-aws/
├── main.tf, providers.tf, variables.tf, outputs.tf, versions.tf
├── envs/{test.tfvars, prod.tfvars}
├── modules/
│   ├── network/         # VPC, 2× public + 2× private subnet, IGW, 1× NAT GW
│   ├── ecr/             # repozytorium + lifecycle policy
│   ├── eks/             # cluster + node group (EC2) + OIDC (IRSA)
│   ├── secrets/         # Secrets Manager + rola IRSA dla ESO
│   └── auto-shutdown/   # EventBridge Scheduler + Lambda (scale-to-zero 18:00)
├── scripts/{deploy.sh, destroy.sh, install-argocd.sh, check-infra.sh}
└── README.md
```

---

## Deployment Flow

```bash
# 1. Skonfiguruj poświadczenia AWS
aws configure        # lub: export AWS_PROFILE=...

# 2. Pełny deploy (Terraform + ArgoCD + weryfikacja)
./scripts/deploy.sh
```

Manualnie:
```bash
terraform init
terraform apply -var-file=envs/test.tfvars -auto-approve   # tworzy OBA klastry (test + prod)
./scripts/install-argocd.sh
./scripts/check-infra.sh
```

---

## Required Namespaces

| Cluster            | Namespaces                        |
| ------------------ | --------------------------------- |
| devops-poc01-test  | environment-dev, environment-test |
| devops-poc01-prod  | environment-prod                  |

---

## Koszty / FinOps

Mechanizmy ograniczające koszt:

- **Auto-shutdown 18:00** – węzły EC2 skalowane do 0 (Lambda).
- **1 węzeł `t3.large`** na klaster; `min_size = 0`.
- **Tryb SPOT** – ustaw `capacity_type = "SPOT"` w `envs/*.tfvars` dla ~70% oszczędności na EC2.
- **Jeden NAT Gateway** (nie per-AZ) – największy stały koszt sieci AWS.
- **ECR lifecycle policy** – trzyma tylko 10 ostatnich obrazów.

> Control plane EKS (~0,10 USD/h ≈ 73 USD/mc) nie da się zatrzymać. Główny koszt godzinowy
> generują węzły EC2 – dlatego są wygaszane o 18:00. Gdy środowisko nieużywane, trzymaj węzły = 0.

---

## Requirements

- AWS CLI v2
- Terraform >= 1.6
- kubectl, Helm >= 3.x
- Bash

---

## Cleanup

```bash
./scripts/destroy.sh
```
