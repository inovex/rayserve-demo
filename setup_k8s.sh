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

echo "Installing Prometheus Stack and Monitors..."
chmod +x ./prom_install.sh
./prom_install.sh --auto-load-dashboard true

echo "Installing KubeRay Operator..."
helm repo add kuberay https://ray-project.github.io/kuberay-helm/
helm repo update
helm upgrade --install kuberay-operator kuberay/kuberay-operator \
    --version 1.5.1 \
    --create-namespace \
    --namespace ray-system \
    --set metrics.serviceMonitor.enabled=true \
    --set metrics.serviceMonitor.selector.release=prometheus



echo "Building Docker image..."
docker build -t $IMAGE_NAME .

echo "Loading image into Kind..."
kind load docker-image $IMAGE_NAME --name $CLUSTER_NAME

echo "Applying Kubernetes manifests..."
# Note: k8s/monitoring/prometheus.yaml and grafana.yaml are superseded by Helm chart
kubectl apply -f k8s/ray-service.yaml
kubectl apply -f k8s/services.yaml

# Create ConfigMap from the local locustfile.py
kubectl create configmap locust-script --from-file=locustfile.py --dry-run=client -o yaml | kubectl apply -f -

kubectl apply -f k8s/locust.yaml

echo "Waiting for Ray head pod to be created..."
until kubectl get pods -l ray.io/node-type=head 2>/dev/null | grep -q "head"; do
    sleep 2
done

echo "Waiting for pods to be ready..."
kubectl wait --for=condition=Ready pod -l ray.io/node-type=head --timeout=300s

echo "Access Ray Dashboard at: http://localhost:8265"
echo "Access Ray Serve at: http://localhost:8000"
echo "Access Grafana at: http://localhost:3000 (Anonymous Admin access enabled)"
echo "Access Locust at: http://localhost:8089"
