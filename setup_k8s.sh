#!/bin/bash
set -e

CLUSTER_NAME="rayserve-demo"
KIND_CONFIG="k8s/kind-config.yaml"
IMAGE_NAME="rayserve-demo:latest"

# 1. Check dependencies
command -v kind >/dev/null 2>&1 || { echo "kind is required but not installed. Aborting." >&2; exit 1; }
command -v kubectl >/dev/null 2>&1 || { echo "kubectl is required but not installed. Aborting." >&2; exit 1; }
command -v docker >/dev/null 2>&1 || { echo "docker is required but not installed. Aborting." >&2; exit 1; }
command -v helm >/dev/null 2>&1 || { echo "helm is required but not installed. Aborting." >&2; exit 1; }

echo "Creating Kind cluster..."
if kind get clusters | grep -q "^$CLUSTER_NAME$"; then
    echo "Cluster $CLUSTER_NAME already exists. Skipping creation."
else
    kind create cluster --name $CLUSTER_NAME --config $KIND_CONFIG
fi

# Switch context
kubectl cluster-info --context kind-$CLUSTER_NAME

echo "Installing KubeRay Operator..."
helm repo add kuberay https://ray-project.github.io/kuberay-helm/
helm repo update
helm upgrade --install kuberay-operator kuberay/kuberay-operator --version 1.1.0 --create-namespace --namespace ray-system

echo "Building Docker image..."
docker build -t $IMAGE_NAME .

echo "Loading image into Kind..."
kind load docker-image $IMAGE_NAME --name $CLUSTER_NAME

echo "Creating ConfigMaps..."

# Helper function to create configmap from file/dir with deletion first
create_cm() {
    local name=$1
    local from=$2
    kubectl delete configmap "$name" --ignore-not-found
    kubectl create configmap "$name" --from-file="$from"
}

create_cm "grafana-datasources" "monitoring/grafana/provisioning/datasources/prometheus.yml"
create_cm "grafana-dashboards-prov" "monitoring/grafana/provisioning/dashboards/ray.yml"
create_cm "grafana-dashboards-json" "monitoring/grafana/provisioning/dashboards/ray"

echo "Applying Kubernetes manifests..."
kubectl apply -f k8s/monitoring/prometheus.yaml
kubectl apply -f k8s/monitoring/grafana.yaml
kubectl apply -f k8s/ray-service.yaml
kubectl apply -f k8s/services.yaml
kubectl apply -f k8s/locust.yaml

echo "Waiting for pods to be ready..."
kubectl wait --for=condition=Ready pod -l ray.io/node-type=head --timeout=300s || echo "Waiting for head pod timed out, check status with kubectl get pods"

echo "Access Ray Dashboard at: http://localhost:8265"
echo "Access Ray Serve at: http://localhost:8000"
echo "Access Grafana at: http://localhost:3000"
echo "Access Locust at: http://localhost:8089"
