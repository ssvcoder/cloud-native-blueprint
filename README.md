# Cloud-Native Blueprint

A production-style reference for running a .NET microservice on Azure: **Terraform** provisions the platform (AKS + Container Registry + monitoring), **Kubernetes** manifests run the workload, and a **GitHub Actions** pipeline ties it all together — build, push, plan/apply, deploy.

Built to demonstrate real-world DevOps skills: infrastructure as code, container orchestration, and CI/CD automation.

## Architecture

```
                        +-----------------------+
                        |      GitHub repo      |
                        |  (app + tf + k8s)     |
                        +-----------+-----------+
                                    | push to main / PR
                                    v
                        +-----------------------+
                        |   GitHub Actions      |
                        |  ci-cd.yml pipeline   |
                        +--+--------+-----+----+
                           |        |     |
              build & test |        |     | terraform
              docker push  |        |     | plan / apply
                           v        v     v
   +------------------------------------------------------+
   |                   Azure (rg-blueprint-dev)            |
   |                                                       |
   |  +----------------+    +-------------------------+   |
   |  | Container      |    | AKS cluster             |   |
   |  | Registry (ACR) |<---| (SystemAssigned ident.) |   |
   |  | hello-api:img  |AcrPull|                         |   |
   |  +----------------+    |  Namespace: blueprint   |   |
   |                         |   Deployment x3 (HPA)   |   |
   |  +----------------+    |   Service (ClusterIP)   |   |
   |  | Log Analytics  |<---|   Ingress (nginx)       |   |
   |  | (AKS monitoring|OMS  +-------------------------+   |
   |  +----------------+                                   |
   +------------------------------------------------------+
```

Traffic flow: `hello.blueprint.local` → NGINX Ingress → ClusterIP Service → 3 hello-api pods (autoscales 3–10 on CPU).

## Repo layout

```
.
├── infra/terraform/        # Azure platform as code
│   ├── versions.tf         # provider pins + remote-state backend placeholder
│   ├── variables.tf        # project/env/location/node sizing knobs
│   ├── main.tf             # RG, Log Analytics, ACR, AKS, AcrPull role
│   └── outputs.tf          # ACR login server, cluster name, kubeconfig (sensitive)
├── k8s/                    # workload manifests (applied after infra exists)
│   ├── namespace.yaml      # `blueprint` namespace
│   ├── configmap.yaml      # non-secret app settings (greeting, version)
│   ├── secret-template.yaml# placeholder Secret — replace values before use
│   ├── deployment.yaml     # 3 replicas, probes, resources (image via envsubst)
│   ├── service.yaml        # internal ClusterIP service
│   ├── ingress.yaml        # nginx ingress for hello.blueprint.local
│   ├── hpa.yaml            # autoscale 3–10 pods at 70% CPU
│   └── app/                # sample ASP.NET Core 8 minimal API
│       ├── Program.cs      # GET / and GET /healthz
│       ├── HelloApi.csproj
│       └── Dockerfile      # multi-stage build, runs as non-root `app` user
└── .github/workflows/
    └── ci-cd.yml           # build/test → push to ACR → tf apply → kubectl deploy
```

## Prerequisites

- Azure subscription with permission to create resource groups (Contributor+)
- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.5
- [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli) (`az login` first)
- [kubectl](https://kubernetes.io/docs/tasks/tools/) and [Docker](https://docs.docker.com/get-docker/)
- .NET 8 SDK (only to run the sample app locally)

## Deployment guide

### 1. Provision the platform

```bash
cd infra/terraform
terraform init
terraform plan -out=tfplan     # review the diff — RG, ACR, AKS, Log Analytics
terraform apply tfplan
```

Grab the outputs you'll need next:

```bash
ACR=$(terraform output -raw acr_login_server)
az aks get-credentials \
  --resource-group "$(terraform output -raw resource_group_name)" \
  --name "$(terraform output -raw aks_cluster_name)"
```

### 2. Build & push the sample image

```bash
cd ../../k8s/app
docker build -t "$ACR/hello-api:v1" .
az acr login --name "$(echo $ACR | cut -d. -f1)"
docker push "$ACR/hello-api:v1"
```

### 3. Deploy the workload

```bash
cd ..
# Fill in the real secret values in secret-template.yaml first (see its header).

export ACR_LOGIN_SERVER="$ACR" IMAGE_TAG="v1"
for f in namespace.yaml configmap.yaml secret-template.yaml deployment.yaml \
         service.yaml ingress.yaml hpa.yaml; do
  envsubst < "$f" | kubectl apply -f -
done

kubectl -n blueprint rollout status deployment/hello-api
kubectl -n blueprint get pods
```

### 4. Access it

Install the NGINX ingress controller and point `hello.blueprint.local` at its external IP (see `k8s/ingress.yaml` header), then:

```bash
curl http://hello.blueprint.local/
# {"message":"Hello from the Cloud-Native Blueprint!","version":"1.0.0",...}
```

For a quick local check without ingress:

```bash
kubectl -n blueprint port-forward svc/hello-api 8080:80
curl http://localhost:8080/
```

### 5. CI/CD

Push to `main` (or open a PR to see `terraform plan` only). Configure the secrets listed at the top of `.github/workflows/ci-cd.yml` and a `production` environment with required reviewers — deploys then pause for approval before touching Azure.

## ⚠️ Cost & cleanup

AKS node pools and ACR **bill by the hour even when idle** — a small dev cluster like this typically costs on the order of tens of dollars per month. When you're done experimenting:

```bash
cd infra/terraform
terraform destroy   # removes the resource group and everything in it
```

Also delete the local kubeconfig context (`kubectl config delete-context <name>`) and revoke the service principal if you created one for CI.

## What this demonstrates

| Piece | Skills shown |
|---|---|
| `infra/terraform/` | IaC with variables/outputs, Azure networking & identity (AcrPull role), Log Analytics monitoring integration, remote-state hygiene |
| `k8s/` manifests | Production K8s patterns: namespaces, probes, resource requests/limits, rolling updates, ConfigMaps/Secrets, Ingress, HPA |
| `k8s/app/` | Multi-stage Docker builds, non-root containers, minimal ASP.NET Core API with health endpoints |
| `ci-cd.yml` | Full pipeline: build/test → container publish → `terraform plan` on PR / `apply` on main → envsubst image pinning → `kubectl rollout status`, with environment protection |
