# End-to-End Cloud-Native Hospital Recruitment Platform

## 1. Project Overview

This Capstone project implements a production-grade, cloud-native DevOps platform for a Hospital Management System. The goal was to migrate a legacy application to **Microsoft Azure Kubernetes Service (AKS)**, enabling full automation, high availability, and SRE-grade observability.

The solution enforces **Infrastructure as Code (IaC)**, **Immutable Infrastructure** via Docker, and **GitOps** principles for zero-touch deployments.

## 2. Architecture & Tech Stack

The solution follows a layered cloud-native architecture:

| Layer | Technology | Usage |
| --- | --- | --- |
| **Cloud** | Microsoft Azure | Primary Cloud Provider (AKS, ACR, VNet) |
| **IaC** | Terraform | Provisioning AKS, VNet, Subnets, and ACR |
| **Containerization** | Docker | Packaging the Node.js Microservice |
| **CI** | GitHub Actions | Automated Build, Test, Tag, and Push to ACR |
| **Orchestration** | Kubernetes (AKS) | Container Management and Scaling |
| **Packaging** | Helm | Templating K8s manifests for environment flexibility |
| **CD (GitOps)** | Argo CD | Continuous Delivery and Configuration Management |
| **Observability** | Prometheus & Grafana | Metrics collection and Visualization |

---

## 3. Implementation Phases

### Phase 1: Infrastructure Provisioning (Terraform)

* Provisioned a dedicated **Resource Group**, **VNet** (10.0.0.0/16), and **Subnet**.
* Deployed a secure **AKS Cluster** with Managed Identity.
* Created an **Azure Container Registry (ACR)** with `AcrPull` Role Assignment for seamless authentication.



### Phase 2: Continuous Integration (GitHub Actions)

* Designed a workflow that triggers on commits to `main`.
* Implemented **Dynamic Tagging** using GitHub Run IDs (e.g., `v1.0.45`) to ensure traceability.


* Optimized build times using `node:18-alpine` base images.

### Phase 3 & 4: Kubernetes & Helm Packaging

* Created manifests for **Deployment**, **Service**, **ConfigMap**, **Secret**, and **PVC**.


* Converted static YAMLs into a flexible **Helm Chart**, enabling configuration injection (replicas, image tags) via `values.yaml`.



### Phase 5: GitOps Deployment (Argo CD)

* Implemented **Argo CD** to watch the GitHub repository.
* Achieved "Zero-Touch Deployment": Changes committed to Git are automatically synced to the cluster without manual `kubectl` intervention.



### Phase 6: Observability

* Deployed the **Kube-Prometheus Stack**.
* Configured **Grafana Dashboards** to monitor Node CPU, Memory, and Pod health, satisfying SRE requirements.



---

## 4. Challenges Faced & Resolutions

*This section highlights technical hurdles encountered during the lab and the engineering solutions applied.*

### 🛑 Challenge 1: Azure Policy Violation

* **Issue:** The deployment failed with `RequestDisallowedByPolicy` when attempting to create `Standard_DS2_v2` nodes. The lab environment enforced strict VM SKU policies.
* **Resolution:** Analyzed policy error logs and identified `Standard_D2s_v3` (8GB RAM) as the compliant SKU. Updated `main.tf` to reflect this change.

### 🛑 Challenge 2: Availability Zone Constraints

* **Issue:** The deployment failed with `AvailabilityZoneNotSupported` because the assigned region (`australiacentral`) does not support Availability Zones.
* **Resolution:** Modified the Terraform `default_node_pool` configuration to remove the `zones` parameter while maintaining the `Standard` load balancer SKU for production features.

### 🛑 Challenge 3: Network CIDR Overlap

* 
**Issue:** The Kubernetes Service CIDR (`10.0.0.0/16`) conflicted with the VNet Address Space (`10.0.0.0/16`), preventing cluster creation.


* **Resolution:** Redesigned the network profile in Terraform to separate the address spaces:
* **Nodes:** `10.0.0.0/16`
* **Services:** `10.100.0.0/16`



### 🛑 Challenge 4: Large File Git Rejection

* **Issue:** The `git push` was rejected by GitHub because the Terraform provider binary (`.exe`, 200MB+) was accidentally committed, exceeding the 100MB file limit.
* **Resolution:**
1. Implemented a `.gitignore` to exclude `.terraform/` folders.
2. Performed a `git reset` to unstage the large file.
3. Re-initialized the repository history to ensure a clean push.



### 🛑 Challenge 5: Docker Build Failure (Alpine Linux)

* **Issue:** The CI pipeline failed with `exit code: 127` because the `node:18-alpine` image does not support `apt install` (it uses `apk`).
* **Resolution:** Corrected the `Dockerfile` to use `npm install --production` for dependency management, aligning with Node.js best practices.

---

## 5. Project Structure

```text
Hospital-Application/
├── .github/workflows/   # CI Pipelines (GitHub Actions)
├── infrastructure/      # Terraform IaC (main.tf)
├── kubernetes/          # Helm Charts & Manifests
│   └── recruitment-app/ # Application Chart
├── backend/             # Node.js Source Code
├── public/              # Frontend Assets
├── Dockerfile           # Container Definition
└── README.md            # Project Documentation

```

## 6. How to Run

1. **Infrastructure:** `cd infrastructure` -> `terraform init` -> `terraform apply`.
2. **Pipeline:** Push changes to `main` to trigger the Docker build and push to ACR.
3. **Deploy:** Argo CD automatically detects the new Helm chart version and syncs it to AKS. Access Argo CD via Port Forwarding (`localhost:8080`)
4. **Monitor:** Access Grafana via Port Forwarding (`localhost:80`) to view cluster metrics.