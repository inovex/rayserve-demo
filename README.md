# Ray Serve Iris Demo on Kubernetes (Kind)

This project demonstrates a production-like machine learning deployment using Ray Serve on Kubernetes (via Kind), featuring a Scikit-learn Iris classifier, custom Prometheus metrics, and pre-configured Grafana dashboards.

## Project Structure

- `k8s/`: Kubernetes manifests and configurations.
- `models/`: Serialized model artifacts (`.pkl`).
- `data/`: Model metadata and labels (`.json`).
- `monitoring/`: Prometheus and Grafana configuration.
- `serve_model.py`: Core deployment logic with custom metrics and health checks.
- `serve_config.yaml`: Ray Serve deployment configuration.
- `locustfile.py`: Load testing script.
- `setup_k8s.sh`: One-click script to set up the environment.

## Prerequisites

- [Docker](https://www.docker.com/)
- [Kind](https://kind.sigs.k8s.io/)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [Helm](https://helm.sh/)
- [uv](https://github.com/astral-sh/uv) (for running the local test client)

## Getting Started

### 1. Setup the Cluster
Run the setup script to create the Kind cluster, install the KubeRay operator, build the image, and deploy all services:

```bash
bash setup_k8s.sh
```

Wait a few minutes for all pods to be ready. You can check the status with:
```bash
kubectl get pods
```

### 2. Query the Model
Once the system is up, you can query the model using the provided python script:

```bash
uv run python query_model.py
```
*Note: This works because `setup_k8s.sh` configures Kind to map port 8000 on localhost to the Ray Serve service.*

### 3. Monitor the Application
Access the various dashboards exposed via localhost ports:

- **Ray Dashboard:** [http://localhost:8265](http://localhost:8265) — Cluster status and logs.
- **Grafana:** [http://localhost:3000](http://localhost:3000) — Visualization.
    - Navigate to Dashboards -> Ray -> Serve Deployment Dashboard.
- **Prometheus:** `kubectl port-forward svc/prometheus 9090:9090` then [http://localhost:9090](http://localhost:9090) (Prometheus is not exposed by default on a static node port to save ports, but you can port-forward).

### 4. Load Testing with Locust
1. Open Locust: [http://localhost:8089](http://localhost:8089)
2. Number of users: 10
3. Spawn rate: 2
4. Host: `http://rayserve-demo-head-svc:8000` (This is the internal K8s DNS name, already pre-filled in the deployment).
5. Start swarming.

### 5. Cleanup
To delete the cluster:

```bash
bash teardown_k8s.sh
```
