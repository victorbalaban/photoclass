# Photo Classification Platform

This repository contains the foundation for a distributed Photo Classification Platform. 

---

## 🏗️ Architecture

The platform uses a decoupled, microservices-based architecture containerized via Docker:

* **`frontend/`**: Reserved for the Flutter application. 
* **`backend/user_service/`**: A lightweight FastAPI instance running on port `8000`. This will handle registration, logins, and JWT token management.
* **`backend/classification_service/`**: A separate FastAPI instance running on port `8001`. This will handle the heavy lifting: image uploads, metadata processing, and running classification logic.
* **Local Storage Volume**: A named Docker volume (`photo_storage`) shared with the classification service. For local development, it maps directly to `/app/storage` inside the container, saving images directly to disk without requiring external cloud accounts.

---

## 🛠️ How to Run Locally

Docker handles everything inside its own virtual containers.

1. Make sure **Docker Desktop** is open and running.
2. Spin up the cluster by running this command in the project root:
   ```bash
   docker compose up --build

3. To shut down the services and clear the network space, simply run:   
   ```bash
   docker compose down
   