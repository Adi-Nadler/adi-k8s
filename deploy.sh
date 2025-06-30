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
# Poll every 5 seconds, timeout after ~2 minutes
for i in {1..24}; do
  READY=$(kubectl get pods -n ingress-nginx -l app.kubernetes.io/component=controller -o jsonpath="{.items[0].status.containerStatuses[0].ready}" 2>/dev/null)
  
  if [ "$READY" == "true" ]; then
    echo "✅ ingress-nginx-controller is ready."
    break
  else
    echo "⏳ Still waiting... ($i)"
    sleep 5
  fi
done

# Optional: Check if it failed after timeout
if [ "$READY" != "true" ]; then
  echo "❌ ingress-nginx-controller failed to become ready. Exiting."
  exit 1
fi

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
echo "⏳ Waiting for external IP allocation to Ingress..."

EXTERNAL_IP=""
while [ -z "$EXTERNAL_IP" ]; do
  EXTERNAL_IP=$(kubectl get ingress adi-ingress -o jsonpath="{.status.loadBalancer.ingress[0].ip}")
  [ -z "$EXTERNAL_IP" ] && echo "Still waiting..." && sleep 10
done

echo "🌐 Access services:"
echo "   Service A: http://$EXTERNAL_IP/service-a"
echo "   Service B: http://$EXTERNAL_IP/service-b"

