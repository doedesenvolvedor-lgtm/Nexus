# Nexus Streaming

Nexus Streaming is a full-stack streaming platform prototype built with FastAPI for the backend and Flutter for the mobile app.

## Installation

### Backend

```bash
cd backend
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env
uvicorn app.main:app --reload
```

### Flutter

```bash
cd nexus_mobile
flutter pub get
flutter run
```

### Docker

```bash
docker compose up --build
```

### Kubernetes

```bash
kubectl apply -f kubernetes/
```

## API

The API exposes OpenAPI documentation at:
- /docs
- /redoc

## Deploy

The project includes Docker Compose, NGINX, Kubernetes manifests, Prometheus, and Grafana configuration for deployment preparation.

## License

MIT
