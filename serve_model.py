import pickle
import json
import numpy as np
import os
import time
import logging
from starlette.requests import Request
from typing import Dict
from sklearn.datasets import load_iris
from sklearn.ensemble import GradientBoostingClassifier
from ray import serve
from ray.serve import metrics

logger = logging.getLogger("ray.serve")

# 1. Train and save a simple model
def train_and_save_model():
    print("Training model...")
    model = GradientBoostingClassifier()
    iris_dataset = load_iris()
    data, target, target_names = (
        iris_dataset["data"],
        iris_dataset["target"],
        iris_dataset["target_names"],
    )
    
    # Simple shuffle and split
    indices = np.random.permutation(len(data))
    data, target = data[indices], target[indices]
    train_x, train_y = data[:100], target[:100]
    
    model.fit(train_x, train_y)
    
    model_path = "models/iris_model.pkl"
    label_path = "data/iris_labels.json"
    
    os.makedirs("models", exist_ok=True)
    with open(model_path, "wb") as f:
        pickle.dump(model, f)
    with open(label_path, "w") as f:
        json.dump(target_names.tolist(), f)
    
    print(f"Model saved to {model_path}")
    print(f"Labels saved to {label_path}")
    return model_path, label_path

# 2. Define the Ray Serve Deployment
@serve.deployment
class IrisPredictor:
    def __init__(self, model_path: str, label_path: str):
        with open(model_path, "rb") as f:
            self.model = pickle.load(f)
        with open(label_path) as f:
            self.label_list = json.load(f)
        
        # Monitoring: Custom metrics
        self.prediction_counter = metrics.Counter(
            "iris_predictions_total",
            description="Total number of iris predictions.",
            tag_keys=("label",)
        )
        self.latency_histogram = metrics.Histogram(
            "iris_prediction_latency_ms",
            description="Latency of iris predictions in milliseconds.",
            boundaries=[0.1, 0.5, 1, 2, 5, 10]
        )

    async def __call__(self, starlette_request: Request) -> Dict:
        start_time = time.time()
        payload = await starlette_request.json()
        
        # Structured logging
        logger.info(f"Processing prediction request: {payload}")
        
        # Expecting JSON like: {"sepal_length": 1.2, "sepal_width": 1.0, "petal_length": 1.1, "petal_width": 0.9}
        try:
            input_vector = [
                payload["sepal_length"],
                payload["sepal_width"],
                payload["petal_length"],
                payload["petal_width"],
            ]
        except KeyError as e:
            logger.error(f"Missing key in payload: {e}")
            return {"error": f"Missing key: {e}"}
        
        prediction = self.model.predict([input_vector])[0]
        label = self.label_list[prediction]
        
        # Record metrics
        latency_ms = (time.time() - start_time) * 1000
        self.latency_histogram.observe(latency_ms)
        self.prediction_counter.inc(tags={"label": label})
        
        logger.info(f"Prediction result: {label} (latency: {latency_ms:.2f}ms)")
        return {"prediction": label}

    def check_health(self):
        """Custom health check for the deployment."""
        if self.model is None:
            logger.error("Health check failed: Model is not loaded.")
            raise RuntimeError("Model is not loaded.")
        # logger.info("Health check passed.")

def build_app(args: Dict):
    model_path = args.get("model_path", "models/iris_model.pkl")
    label_path = args.get("label_path", "data/iris_labels.json")
    
    # Ensure paths exist before binding
    if not os.path.exists(model_path):
        train_and_save_model()
        
    return IrisPredictor.bind(model_path, label_path)

iris_app = build_app({})
