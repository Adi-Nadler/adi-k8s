# aks-home-assignment

This project is a production-style, repeatable setup of a Kubernetes cluster running on Azure Kubernetes Service (AKS), with two microservices (`Service A` and `Service B`), an ingress controller, and a network policy restricting communication between the services. It includes liveness and readiness probes, external access via Ingress, and a Bitcoin price fetching microservice.

---

## 📁 Project Structure

```
aks-home-assignment/
├── ingress/
│   └── ingress.yaml
├── service-a/
│   ├── app.py
│   ├── Dockerfile
│   ├── deployment.yaml
│   ├── requirements.txt
│   └── service.yaml
├── service-b/
│   ├── deployment.yaml
│   └── service.yaml
├── network-policy.yaml
├── deploy.sh
├── README.md
```

---


## 🪙 Service A Description

- Every 1 minute: fetches the current Bitcoin price in USD from the CoinBase API.
- Every 10 minutes: calculates and prints the average of the last 10 prices.
- Uses a dynamic `/tmp/healthy` file to signal pod health.
- Liveness & readiness probes are configured accordingly.

It does **not** expose the price over HTTP.  
Instead, it returns a simple **"ALIVE"** string on HTTP GET `/` to satisfy health probes.

To view its output logs:

```bash
kubectl logs deployment/service-a
```
---

## 📦 Docker Image

Service A is available publicly on Docker Hub:

[text](https://hub.docker.com/r/adinadler1/service-a)

Image tag used in deployment: `adinadler1/service-a:latest`

---


## 🚀 How to Deploy the Project

### 1. **Pre-requisites**
- Azure CLI (`az`)
- `kubectl`
- Docker installed and logged in to Docker Hub
- Git Bash or WSL (recommended)

### 2. **Clone the Repository**
```bash
git clone https://github.com/Adi-Nadler/aks-home-assignment.git
cd aks-home-assignment
```

### 3. **Login to Azure and Set Variables**
```bash
az login
RESOURCE_GROUP="adi-k8s-rg"
CLUSTER_NAME="adiAKSCluster"
LOCATION="westeurope"
NODE_COUNT=2
VM_SIZE="Standard_B2s"
```

### 4. **Create Resource Group and AKS Cluster**
```bash
az group create --name $RESOURCE_GROUP --location $LOCATION
az aks create \
  --resource-group $RESOURCE_GROUP \
  --name $CLUSTER_NAME \
  --node-count $NODE_COUNT \
  --node-vm-size $VM_SIZE \
  --generate-ssh-keys
az aks get-credentials --resource-group $RESOURCE_GROUP --name $CLUSTER_NAME
```

### 5. **Install Ingress Controller**
```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.10.0/deploy/static/provider/cloud/deploy.yaml

```

### 6. **Apply Kubernetes Manifests**
```bash
kubectl apply -f service-a/deployment.yaml
kubectl apply -f service-a/service.yaml
kubectl apply -f service-b/deployment.yaml
kubectl apply -f service-b/service.yaml
kubectl apply -f ingress/ingress.yaml
kubectl apply -f network-policy.yaml
```

> 🔁 Alternatively, run the automation script:
```bash
bash deploy.sh
```

---

## 🌐 Accessing Services
Get the external IP:
```bash
kubectl get ingress
```
Then open in browser:
- `http://<external-ip>/service-a`
- `http://<external-ip>/service-b`

---

## 🧪 Testing NetworkPolicy
To verify Service-A cannot access Service-B:
```bash
kubectl run -it --rm --image=busybox test-shell -- /bin/sh
wget --spider service-b
```
Expected: Should **fail** if NetworkPolicy is applied correctly.

---

## 🛠 Health Probes
Service-A defines:
- **Readiness Probe** using `/tmp/healthy` file
- **Liveness Probe** for API health detection

---

## ✅ Production Readiness
- Ingress controller
- Liveness & Readiness probes
- NetworkPolicy between services
- Automated repeatable deployment

---

## ✍️ Author
Adi Nadler

---
