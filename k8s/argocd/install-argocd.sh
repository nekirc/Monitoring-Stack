#!/bin/bash

# 1. Create the namespace
kubectl create namespace argocd || true

# 2. Install ArgoCD
echo "Installing ArgoCD..."
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# 3. Expose ArgoCD Server UI via LoadBalancer (Standard for local clusters like Docker Desktop/Minikube)
echo "Exposing ArgoCD Server..."
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'

echo "---------------------------------------------------"
echo "ArgoCD Installation Triggered."
echo "Wait a few minutes for the pods to be ready."
echo ""
echo "To get your login password (username is 'admin'):"
echo "kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d; echo"
echo ""
echo "Access the UI at: http://localhost (if using Docker Desktop) or run 'minikube service argocd-server -n argocd'"
echo "---------------------------------------------------"
