#!/bin/bash

# 1. Create the namespace
kubectl create namespace argocd || true

# 2. Install ArgoCD with Server-Side Apply
# --server-side bypasses the 262KB annotation limit by offloading logic to the API
echo "Installing ArgoCD manifests (Server-Side)..."
kubectl apply --server-side -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# 3. Wait for the CRD to actually exist before waiting for it to be established
echo "Waiting for CRDs to register..."
until kubectl get crd applicationsets.argoproj.io > /dev/null 2>&1; do
  echo "Still waiting for CRD registration..."
  sleep 2
done

echo "Waiting for ApplicationSet CRDs to be 'established'..."
kubectl wait --for=condition=established --timeout=60s crd/applicationsets.argoproj.io

# 4. Expose ArgoCD Server UI
echo "Exposing ArgoCD Server via LoadBalancer..."
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'

# 5. Wait for the initial admin secret to be generated
echo "Waiting for admin secret generation..."
until kubectl -n argocd get secret argocd-initial-admin-secret > /dev/null 2>&1; do
  echo "Secret not ready yet..."
  sleep 2
done

echo "---------------------------------------------------"
echo "ArgoCD Installation FIXED."
echo "---------------------------------------------------"
echo "Login: admin"
echo "Password: $(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d)"
echo "---------------------------------------------------"