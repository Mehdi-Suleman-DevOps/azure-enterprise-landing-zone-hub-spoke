# 🌐 Azure Enterprise Landing Zone: Hub-and-Spoke Network Architecture

[![Terraform](https://img.shields.io/badge/Terraform-%3E%3D1.5.0-844FBA?style=for-the-badge&logo=terraform&logoColor=white)](https://www.terraform.io/)
[![Azure](https://img.shields.io/badge/Azure-CAF%20Landing%20Zone-0078D4?style=for-the-badge&logo=microsoftazure&logoColor=white)](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/)
[![Security](https://img.shields.io/badge/Security-Zero%20Trust%20%7C%20UDR%200.0.0.0%2F0-00C853?style=for-the-badge&logo=shieldsdotio&logoColor=white)](#)
[![License](https://img.shields.io/badge/License-MIT-blue?style=for-the-badge)](#)

> **Architected by Mehdi Suleman**  
> *Senior DevSecOps & Enterprise Automation Engineer*  
> Email: [mailtomehdi133@gmail.com](mailto:mailtomehdi133@gmail.com) | GitHub: [@Mehdi-Suleman-DevOps](https://github.com/Mehdi-Suleman-DevOps)

---

## 🏛️ Executive Summary & Architectural Overview

This repository provides a **production-hardened, enterprise-grade Azure Landing Zone (CAF) Hub-and-Spoke Network Infrastructure** deployed via modular, reusable Terraform.

It enforces a strict **Zero-Trust Network Perimeter**:
1. **Centralized Inspection:** Outbound `0.0.0.0/0` and inter-spoke traffic is forced through **Azure Firewall Premium** via User Defined Routes (UDRs).
2. **Zero Inbound Public Exposure:** PaaS services (Key Vault, SQL, Storage) reside exclusively on **Private Endpoints** linked to centralized **Private DNS Zones**.
3. **Micro-Segmentation:** Granular Network Security Groups (NSGs) and Application Security Groups (ASGs) isolate workload tiers.

```
                                [ On-Premises Datacenter ]
                                            │
                              (ExpressRoute / S2S VPN Gateway)
                                            │
┌───────────────────────────────────────────▼───────────────────────────────────────────┐
│                           HUB VNet (vnet-hub-prod-001)                                │
│                                  10.100.0.0/16                                        │
│                                                                                       │
│  ┌───────────────────────┐    ┌────────────────────────┐    ┌──────────────────────┐  │
│  │ GatewaySubnet         │    │ AzureFirewallSubnet    │    │ AzureBastionSubnet   │  │
│  │ 10.100.0.0/24         │    │ 10.100.1.0/24 (NVA)    │    │ 10.100.2.0/24        │  │
│  │ (VPN / ExpressRoute)  │    │ • TLS & IDPS Inspect   │    │ • Zero-Public RDP/SSH│  │
│  └───────────────────────┘    └───────────┬────────────┘    └──────────────────────┘  │
│                                           │                                           │
│  ┌────────────────────────────────────────┴────────────────────────────────────────┐  │
│  │ Central Private DNS Resolver Subnet (10.100.3.0/24)                              │  │
│  │ (privatelink.vaultcore.azure.net | privatelink.database.windows.net)            │  │
│  └─────────────────────────────────────────────────────────────────────────────────┘  │
└───────────────────────────────────────────┬───────────────────────────────────────────┘
                                            │
                       (VNet Peering + UDR: 0.0.0.0/0 -> 10.100.1.4)
                       ┌────────────────────┴────────────────────┐
                       │                                         │
┌──────────────────────▼────────────────┐       ┌────────────────▼──────────────────────┐
│  SPOKE 1: APP VNet (AKS Workloads)    │       │  SPOKE 2: SHARED VNet (Shared Tooling)│
│  10.101.0.0/16                        │       │  10.102.0.0/16                        │
│                                       │       │                                       │
│  • snet-app-gw        : 10.101.1.0/24 │       │  • snet-devops-runners : 10.102.1.0/24│
│    (App Gateway WAF v2 Ingress)       │       │    (Self-Hosted CI/CD Runners)        │
│  • snet-aks-nodes     : 10.101.2.0/24 │       │  • snet-security-tools : 10.102.2.0/24│
│    (Private AKS Cluster Node Pools)   │       │    (Scanning & SIEM Agents)           │
│  • snet-private-links : 10.101.3.0/24 │       │                                       │
│    (Private Endpoints: KV, SQL, Blob) │       │  Route Table: Default 0.0.0.0/0 -> FW │
│  Route Table: Default 0.0.0.0/0 -> FW │       │                                       │
└───────────────────────────────────────┘       └───────────────────────────────────────┘
```

---

## 📊 Enterprise IPAM CIDR Allocation Matrix

Strict IP Address Management (IPAM) ensures zero overlapping CIDR spaces with on-premises datacenters or hybrid cloud connections:

| Network / Resource | Subnet Name | CIDR Prefix | Usable IPs | Primary Purpose |
| :--- | :--- | :--- | :---: | :--- |
| **Hub VNet** (`10.100.0.0/16`) | `GatewaySubnet` | `10.100.0.0/24` | 251 | ExpressRoute / S2S VPN Gateway termination |
| | `AzureFirewallSubnet` | `10.100.1.0/24` | 251 | Azure Firewall Premium (`10.100.1.4`) |
| | `AzureBastionSubnet` | `10.100.2.0/24` | 251 | Azure Bastion jumpbox-less secure access |
| | `snet-dns-resolver` | `10.100.3.0/24` | 251 | Central Private DNS Inbound/Outbound Resolver |
| **Spoke 1 (App Workloads)** (`10.101.0.0/16`) | `snet-app-gw` | `10.101.1.0/24` | 251 | Azure Application Gateway with WAF (OWASP 3.2) |
| | `snet-aks-nodes` | `10.101.2.0/24` | 251 | Private Azure Kubernetes Service (AKS) nodes |
| | `snet-private-endpoints` | `10.101.3.0/24` | 251 | Private Endpoints for Key Vault, SQL, Storage |
| **Spoke 2 (Shared Services)** (`10.102.0.0/16`) | `snet-devops-runners` | `10.102.1.0/24` | 251 | Self-hosted Azure DevOps & GitHub Actions agents |
| | `snet-security-tools` | `10.102.2.0/24` | 251 | Central vulnerability scanners & SIEM forwarders |

---

## 🚦 Traffic Routing & Security Flows

### 1. Ingress Traffic (Internet ➔ Application)
- Public HTTPS traffic terminates on **Azure Application Gateway v2** with **WAF** enabled.
- WAF inspects requests against OWASP CRS 3.2 for SQLi, XSS, and bot protection.
- Traffic is proxied into the private AKS cluster via internal IP routing.

### 2. Egress Traffic (Workloads ➔ Internet)
- Every spoke subnet has an associated **User Defined Route (UDR)** forcing `0.0.0.0/0` to the Firewall's private IP (`10.100.1.4`).
- **Azure Firewall Premium** performs:
  - Deep packet inspection & TLS termination.
  - Threat Intelligence filtering (instantly drops known malicious IPs/domains).
  - Strict FQDN application rules (only whitelisted destinations like `*.docker.io`, `github.com` allowed).

### 3. Inter-Spoke Traffic (Spoke 1 ➔ Spoke 2)
- Spokes are **not** peered directly with each other (preventing lateral movement).
- Inter-spoke communication must route through the Hub Firewall, allowing granular audit logs and network rule filtering.

### 4. PaaS Private Link Resolution
- All PaaS services (Azure Key Vault, Azure SQL, Blob Storage) have public network access set to `Disabled`.
- Private Endpoints inject private IPs into `snet-private-endpoints`.
- Central **Private DNS Zones** linked across all VNets resolve PaaS hostnames (`kv-prod.vaultcore.azure.net`) to their private IP (`10.101.3.X`).

---

## 🛠️ Repository Directory Structure

```
azure-enterprise-landing-zone-hub-spoke/
├── modules/
│   ├── hub_network/              # Hub VNet, Gateway, Firewall & Bastion Subnets
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── spoke_network/            # Spoke VNet, Subnets & Peering
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── azure_firewall/           # Azure Firewall Premium & Policy Rules
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── route_table/              # User Defined Routes (UDR) for 0.0.0.0/0
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── private_dns/              # Centralized Private DNS Zones & VNet Links
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
├── main.tf                       # Root Orchestration (Wires Hub, Spokes & Firewall)
├── variables.tf                  # Parameterized configuration contracts
├── outputs.tf                    # Exported network IDs, IPs, and peering states
├── versions.tf                   # Terraform version >= 1.5.0 & azurerm provider
├── terraform.tfvars.example      # Production sample input variables
├── .gitignore
└── README.md
```

---

## ⚡ Deployment Instructions

### 1. Prerequisites
- Terraform `>= 1.5.0`
- Azure CLI authenticated (`az login`) with Owner or Contributor + User Access Administrator on target subscription.

### 2. Configure Variables
Copy the example variables file:
```bash
cp terraform.tfvars.example terraform.tfvars
```
Adjust location and IP prefixes if needed.

### 3. Deploy Infrastructure
```bash
# Initialize Terraform and download providers
terraform init

# Validate configuration syntax
terraform validate

# Review deterministic execution plan
terraform plan -out=tfplan

# Apply configuration with zero downtime
terraform apply tfplan
```
