# Ray Serve Iris Demo

This project demonstrates a containerized machine learning deployment using Ray Serve, featuring a Scikit-learn Iris classifier, custom Prometheus metrics, and a pre-configured Grafana dashboard.

## Project Structure

- `models/`: Serialized model artifacts (`.pkl`).
- `data/`: Model metadata and labels (`.json`).
- `monitoring/`: Prometheus and Grafana configuration.
- `serve_model.py`: Core deployment logic with custom metrics and health checks.
- `serve_config.yaml`: Ray Serve deployment configuration.
- `docker-compose.yml`: Full-stack orchestration (Ray, Prometheus, Grafana).

## Prerequisites

- [Docker](https://www.docker.com/) and Docker Compose.
- [uv](https://github.com/astral-sh/uv) (for running the local test client).

## Getting Started

### 1. Launch the Stack
Start the entire environment (Ray Serve, Prometheus, and Grafana) in detached mode:

```bash
docker compose up --build -d
```

Wait about 20-30 seconds for the Ray cluster and Serve application to fully initialize.

### 2. Query the Model
Use the provided test client to send a prediction request:

```bash
uv run python query_model.py
```

### 3. Monitor the Application
- **Ray Dashboard:** [http://localhost:8265](http://localhost:8265) — Monitor cluster status and logs.
- **Grafana:** [http://localhost:3000](http://localhost:3000) — View system and custom metrics.
    - *Default login:* `admin` / `admin`
    - *Dashboard:* Navigate to Dashboards -> Ray -> Default Dashboard.
- **Prometheus:** [http://localhost:9090](http://localhost:9090) — Query raw metrics.

## Custom Metrics
The application exports the following metrics:
- `ray_iris_predictions_total`: Counter of predictions labeled by Iris species.
- `ray_iris_prediction_latency_ms`: Histogram of prediction processing time.

## Shutdown
To stop all services and remove containers:

```bash
docker compose down -v
```