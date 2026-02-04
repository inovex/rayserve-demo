from locust import HttpUser, task, between
import random

class IrisUser(HttpUser):
    host = "http://ray-head:8000"
    wait_time = between(0.1, 0.5)  # Simulate aggressive traffic

    @task
    def predict_iris(self):
        # Sample data for Iris dataset
        sample_payload = {
            "sepal_length": random.uniform(4.0, 8.0),
            "sepal_width": random.uniform(2.0, 4.5),
            "petal_length": random.uniform(1.0, 7.0),
            "petal_width": random.uniform(0.1, 2.5)
        }
        
        self.client.post("/", json=sample_payload)
