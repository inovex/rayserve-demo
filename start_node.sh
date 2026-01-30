#!/bin/bash
# start_node.sh

# Start Ray head node
ray start --head --metrics-export-port=8080 --dashboard-host=0.0.0.0 --port=6379

# Wait for Ray to be ready
until ray status >/dev/null 2>&1; do
  echo "Waiting for Ray cluster to be ready..."
  sleep 2
done

echo "Ray cluster is ready. Starting Serve..."

# Start Serve and deploy the model
serve run serve_config.yaml &

# Keep container alive
tail -f /dev/null
