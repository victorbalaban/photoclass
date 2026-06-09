# CI/CD Automation Strategy

This document explains how our automated Continuous Integration (CI) and Continuous Deployment (CD) pipelines work. 

To keep things efficient, we separate the automation paths:
* **Backend Services:** Handled via container-focused pipelines (like GitHub Actions or GitLab CI) targeting **Kubernetes**.
* **Frontend App:** Handled via **Codemagic**, because it is optimized specifically for Flutter's unique build, signing, and App Store/Play Store deployment requirements.

---

## 1. Backend CI/CD Pipeline (FastAPI & Kubernetes)

The backend pipeline handles both of our microservices (`user_service` and `classification_service`). Every time code is pushed to the `main` branch, the pipeline triggers 4 main stages.

### Stage A: Linting & Static Analysis
First, the runner checks the code quality to make sure there are no syntax bugs or formatting problems.
* **Tools used:** `ruff` or `flake8` and `black`.
* **Command run inside pipeline:**
    ```bash
    pip install ruff black
    ruff check .
    black --check .
    ```

### Stage B: Automated Testing
Next, the pipeline runs the unit tests to ensure our API endpoints behave correctly and database fixtures work.
* **Tools used:** `pytest` with `pytest-mock`.
* **Command run inside pipeline:**
    ```bash
    pip install -r requirements.txt
    pytest
    ```

### Stage C: Docker Build & Registry Push
If the linting and tests pass perfectly, the runner builds production-ready Docker images for both services and tags them with the unique Git commit SHA identifier.
* **Container Registry:** Images are securely pushed to a container registry (like Docker Hub, GitHub Packages, or AWS ECR).
* **Process:**
    ```bash
    docker build -t my-registry/user-service:latest ./backend/user_service
    docker build -t my-registry/classification-service:latest ./backend/classification_service
    docker push my-registry/user-service:latest
    ```

### Stage D: Deployment Step (Kubernetes)
Finally, the CD step communicates with our **Kubernetes (K8s)** cluster. It applies the updated deployment configuration files (`deployment.yaml`) so the cluster fetches the brand new images from the registry with zero downtime.
* **Command run inside pipeline:**
    ```bash
    kubectl apply -f k8s/
    kubectl rollout status deployment/user-service-deployment
    kubectl rollout status deployment/classification-service-deployment
    ```

---

## 2. Frontend CI/CD Pipeline (Flutter & Codemagic)

Because our frontend uses Flutter, we do not want to use a standard Linux container pipeline. Flutter apps eventually need to be built for iOS and Android, which requires Mac runners (Xcode), code signing certificates, and safe provisioning profiles. 

Therefore, we use **Codemagic** as our dedicated mobile/web DevOps platform.

### Why Codemagic?
* It provides native macOS virtual machines out-of-the-box for building iOS `.ipa` files.
* It automates Google Play and Apple App Store connect authentication loops.
* It natively supports `fvm` configuration setups.

### The Codemagic Automation Workflow

A typical `codemagic.yaml` pipeline config looks like this:

```yaml
workflows:
  flutter-web-and-mobile-release:
    instance_type: mac_mini_m1 # Gives us fast compilation speeds for web and mobile
    environment:
      flutter: stable
    scripts:
      - name: Install FVM & Fetch Dependencies
        script: |
          dart pub global activate fvm
          fvm flutter pub get
      - name: Lint Code
        script: |
          fvm flutter analyze
      - name: Run Frontend Tests
        script: |
          fvm flutter test
      - name: Build Production Assets
        script: |
          # Builds the web app artifacts
          fvm flutter build web --release
          # (Ready for mobile toggles later):
          # fvm flutter build apk --release
          # fvm flutter build ipa --release
    publishing:
      # If Web: Deploys directly to Firebase Hosting or AWS S3 static web links
      firebase:
        firebase_token: $FIREBASE_TOKEN
        site: my-photo-class-app
      # If Mobile: Automatically uploads the app store artifacts to beta tracks
      app_store_connect:
        auth: integration
        submit_to_testflight: true