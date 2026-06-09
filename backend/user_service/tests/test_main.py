from fastapi.testclient import TestClient
from main import app

client = TestClient(app)

def test_api_health_check():
    # Make a request to the endpoint
    response = client.get("/health")
    
    # Check if the response is exactly what we expect
    assert response.status_code == 200
    assert response.json() == {"status": "healthy"}