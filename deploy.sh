#!/bin/bash

# Assumes script is run from root of the repo (e.g., after git clone or unzip)

# Set variables
RESOURCE_GROUP="adi-k8s-rg"
CLUSTER_NAME="adiAKSCluster"
LOCATION="westeurope"
NODE_COUNT=2
VM_SIZE="Standard_B2s"

# Create resource group (if not exists)
if az group show --name $RESOURCE_GROUP &> /dev/null; then
  echo "Resource group '$RESOURCE_GROUP' already exists."
else
  az group create --name $RESOURCE_GROUP --location $LOCATION
fi

# Create AKS cluster
if az aks show --resource-group $RESOURCE_GROUP --name $CLUSTER_NAME &> /dev/null; then
  echo "AKS cluster '$CLUSTER_NAME' already exists."
else
  az aks create \
    --resource-group $RESOURCE_GROUP \
    --name $CLUSTER_NAME \
    --node-count $NODE_COUNT \
    --node-vm-size $VM_SIZE \
    --generate-ssh-keys
fi

# Get kubeconfig
az aks get-credentials -g $RESOURCE_GROUP -n $CLUSTER_NAME

# Install nginx ingress controller
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.10.0/deploy/static/provider/cloud/deploy.yaml

# Deploy Service A
kubectl apply -f service-a/deployment.yaml
kubectl apply -f service-a/service.yaml

# Deploy Service B
kubectl apply -f service-b/deployment.yaml
kubectl apply -f service-b/service.yaml

# Deploy Ingress
kubectl apply -f ingress/ingress.yaml

# Apply Network Policy
kubectl apply -f network-policy.yaml

echo ""
echo "✅ Deployment complete!"
echo "Use 'kubectl get ingress' to get the external IP."
