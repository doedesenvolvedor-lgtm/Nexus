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

### HTTPS (Nginx + Certbot)

1. Configure os DNS para apontar para a VPS:
- nexusstream.com
- www.nexusstream.com
- api.nexusstream.com
- admin.nexusstream.com
- privacy.nexusstream.com
- terms.nexusstream.com

2. Suba a stack com Nginx em HTTP e suporte ao desafio ACME:

```bash
docker compose up -d nginx backend
```

3. Emita os certificados com webroot:

```bash
docker run --rm \
	-v $(pwd)/certbot/conf:/etc/letsencrypt \
	-v $(pwd)/certbot/www:/var/www/certbot \
	certbot/certbot certonly --webroot -w /var/www/certbot \
	-d nexusstream.com -d www.nexusstream.com \
	-d api.nexusstream.com -d admin.nexusstream.com \
	-d privacy.nexusstream.com -d terms.nexusstream.com
```

4. Recarregue o Nginx para ativar os blocos TLS:

```bash
docker compose restart nginx
```

5. Renovação (crontab sugerido):

```bash
docker run --rm \
	-v $(pwd)/certbot/conf:/etc/letsencrypt \
	-v $(pwd)/certbot/www:/var/www/certbot \
	certbot/certbot renew --webroot -w /var/www/certbot
docker compose restart nginx
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
