from fastapi import FastAPI

app = FastAPI(title="User Service")

@app.get("/")
def health_check():
    return {"status": "User Service OK"}