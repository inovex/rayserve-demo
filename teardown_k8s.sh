#!/bin/bash
CLUSTER_NAME="rayserve-demo"

echo "Deleting Kind cluster $CLUSTER_NAME..."
kind delete cluster --name $CLUSTER_NAME
