from fastapi import FastAPI

app = FastAPI(title="Classification Service")

@app.get("/")
def health_check():
    return {"status": "Classification Service OK"}