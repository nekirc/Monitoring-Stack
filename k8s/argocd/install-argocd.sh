#!/bin/bash

# 1. Create the namespace
kubectl create namespace argocd || true

# 2. Install ArgoCD with Server-Side Apply
# --server-side bypasses the 262KB annotation limit by offloading logic to the API
echo "Installing ArgoCD manifests (Server-Side)..."
kubectl apply --server-side -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# 3. Wait for the CRDs to actually exist before waiting for them to be established
echo "Waiting for CRDs to register..."
until kubectl get crd applicationsets.argoproj.io > /dev/null 2>&1 && \
      kubectl get crd applications.argoproj.io > /dev/null 2>&1; do
  echo "Still waiting for CRD registration..."
  sleep 2
done

echo "Waiting for Application CRDs to be 'established'..."
kubectl wait --for=condition=established --timeout=60s crd/applicationsets.argoproj.io
kubectl wait --for=condition=established --timeout=60s crd/applications.argoproj.io

# 4. Expose ArgoCD Server UI
echo "Exposing ArgoCD Server via LoadBalancer..."
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'

# 5. Wait for the initial admin secret to be generated
echo "Waiting for admin secret generation..."
until kubectl -n argocd get secret argocd-initial-admin-secret > /dev/null 2>&1; do
  echo "Secret not ready yet..."
  sleep 2
done

# 6. Apply ArgoCD Applications in the specified order
echo "Applying ArgoCD Applications in order..."
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
apps_dir="$SCRIPT_DIR/apps"
apps=("portainer.yaml" "victoriametrics.yaml" "prometheus.yaml" "grafana.yaml" "elastic-stack.yaml")

for app in "${apps[@]}"; do
  if [ -f "$apps_dir/$app" ]; then
    echo "Deploying $app..."
    kubectl apply -f "$apps_dir/$app"
  else
    echo "Warning: $apps_dir/$app not found!"
  fi
done

echo "---------------------------------------------------"
echo "ArgoCD Installation."
echo "---------------------------------------------------"
echo "Login: admin"
echo "Password: $(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d)"
echo "---------------------------------------------------"