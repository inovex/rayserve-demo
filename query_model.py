import requests

sample_input = {
    "sepal_length": 5.1,
    "sepal_width": 3.5,
    "petal_length": 1.4,
    "petal_width": 0.2,
}

print(f"Sending request with data: {sample_input}")
try:
    response = requests.post("http://localhost:8000/", json=sample_input)
    if response.status_code == 200:
        print("Response from Ray Serve:")
        print(response.json())
    else:
        print(f"Error: {response.status_code}")
        print(response.text)
except requests.exceptions.ConnectionError:
    print("Connection Error: Is Ray Serve running? Run 'uv run serve run serve_model:iris_app' in another terminal.")
