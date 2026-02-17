# Ray Serve Demo


<img src="github-qr.png" alt="GitHub QR" width="250" />


This project demonstrates a Kubernetes-based machine learning deployment using Ray Serve on a local `kind` cluster, featuring a Scikit-learn Iris classifier, custom Prometheus metrics, and pre-configured Grafana dashboards.

## Project Structure

- `models/`: Serialized model artifacts (`.pkl`).
- `data/`: Model metadata and labels (`.json`).
- `monitoring/`: Grafana provisioning and dashboard definitions.
- `k8s/`: Kubernetes manifests (`RayService`, services, Locust, monitoring overrides).
- `serve_model.py`: Core deployment logic with custom metrics and health checks.
- `generated_config.yaml`: Generated Ray Serve deployment configuration.
- `locustfile.py`: Load testing script for simulating traffic.
- `setup_k8s.sh`: One-command local cluster setup and deployment.
- `teardown_k8s.sh`: Deletes the local `kind` cluster.

## Prerequisites

- [Docker](https://www.docker.com/)
- [kind](https://kind.sigs.k8s.io/)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [Helm](https://helm.sh/)
- [uv](https://github.com/astral-sh/uv) (for running the local test client).

## Getting Started

### 1. Create Cluster and Deploy
This will create (or reuse) the `rayserve-demo` `kind` cluster, install Prometheus/Grafana and KubeRay, build/load the app image, and apply all manifests.

```bash
bash setup_k8s.sh
```

Wait until pods are ready:

```bash
kubectl get pods -A
```

### 2. Query the Model
Use the provided test client to send a prediction request:

```bash
uv run python query_model.py
```

### 3. Monitor the Application
- **Ray Dashboard:** [http://localhost:8265](http://localhost:8265) — Monitor cluster status, logs, and **integrated Grafana metrics** (under the "Metrics" tab).
- **Grafana:** [http://localhost:3000](http://localhost:3000) — Dedicated visualization platform.
    - *Default login:* `admin` / `admin` (Anonymous viewing enabled).
    - *Dashboards:* Navigate to Dashboards -> Ray.
- **Locust UI:** [http://localhost:8089](http://localhost:8089)

### 4. Access Endpoints
`kind` maps NodePorts to localhost in `k8s/kind-config.yaml`:

- Ray Serve API: [http://localhost:8000](http://localhost:8000)
- Ray Dashboard: [http://localhost:8265](http://localhost:8265)
- Grafana: [http://localhost:3000](http://localhost:3000)
- Locust: [http://localhost:8089](http://localhost:8089)

## Custom Metrics
The application exports the following metrics:
- `ray_iris_prediction_latency_ms`: Histogram of prediction processing time.

### 5. Load Testing with Locust
To simulate traffic and see metrics in Ray Dashboard and Grafana:
1. Open Locust: [http://localhost:8089](http://localhost:8089)
2. Number of users: 10
3. Spawn rate: 2
4. Host: `http://localhost:8000`
5. Start swarming.

### 6. Cleanup
Delete the local `kind` cluster:

```bash
bash teardown_k8s.sh
```