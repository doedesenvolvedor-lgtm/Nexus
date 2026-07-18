# 🚀 Deploy Guide - Nexustwos Admin Panel

## Opções de Deployment

### 1. Vercel (Recomendado - 5 minutos)

Vercel é perfeito para aplicações React e oferece deploy automático.

```bash
# Instalar Vercel CLI
npm install -g vercel

# Deploy
vercel

# Acompanhar: https://vercel.com/dashboard
```

**Benefícios:**
- Deploy automático ao fazer push
- Preview automático de branches
- HTTPS automático
- CDN global
- Analytics incluso

### 2. Netlify (Simples - 5 minutos)

```bash
# Build
npm run build

# Deploy manual (arrastar pasta dist)
# Ou:

npm install -g netlify-cli
netlify deploy --prod --dir=dist
```

### 3. AWS S3 + CloudFront (Escalável)

```bash
# Build
npm run build

# Configurar AWS CLI
aws configure

# Upload para S3
aws s3 sync dist/ s3://seu-bucket-name

# Invalidar cache CloudFront
aws cloudfront create-invalidation --distribution-id E123QWER --paths "/*"
```

### 4. Google Firebase Hosting (Integrado)

```bash
# Instalar Firebase CLI
npm install -g firebase-tools

# Login
firebase login

# Build
npm run build

# Deploy
firebase deploy --only hosting
```

### 5. VPS (Docker - Controle Total)

```dockerfile
# Dockerfile
FROM node:18-alpine as builder
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build

FROM nginx:alpine
COPY --from=builder /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

```bash
# Build
docker build -t nexustwos-admin .

# Run
docker run -p 80:80 nexustwos-admin
```

### 6. GitHub Pages (Gratuito - Simples)

```bash
# Adicionar ao package.json
"homepage": "https://seu-username.github.io/admin-panel"

# Build
npm run build

# Deploy
npm install gh-pages --save-dev
npm run deploy
```

---

## Configuração de Produção

### 1. Variáveis de Ambiente

Criar `.env.local` com:

```env
REACT_APP_API_URL=https://api.nexustwos.com
REACT_APP_ENV=production
REACT_APP_DEBUG=false
```

### 2. Nginx (VPS)

```nginx
server {
    listen 80;
    server_name admin.nexustwos.com;
    
    # Redirecionar HTTP para HTTPS
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name admin.nexustwos.com;
    
    # SSL
    ssl_certificate /etc/ssl/certs/nexustwos.crt;
    ssl_certificate_key /etc/ssl/private/nexustwos.key;
    
    # Compression
    gzip on;
    gzip_types text/plain text/css application/json application/javascript;
    
    # Cache
    location ~* \.js$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
    
    location ~* \.css$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
    
    # Root
    root /var/www/nexustwos-admin;
    index index.html;
    
    # SPA routing
    location / {
        try_files $uri $uri/ /index.html;
    }
}
```

### 3. CORS Backend

Configurar backend para aceitar requisições:

```python
# Django/FastAPI
CORS_ALLOWED_ORIGINS = [
    "https://admin.nexustwos.com",
    "http://localhost:3000",
]

# Express
cors({
    origin: [
        "https://admin.nexustwos.com",
        "http://localhost:3000"
    ]
})
```

### 4. Monitoramento

```bash
# PM2 (Node.js server)
npm install -g pm2
pm2 start "npm run preview" --name "nexustwos-admin"
pm2 save
pm2 startup
```

---

## Checklist de Deploy

- [ ] `.env.local` configurado
- [ ] `npm run build` executado com sucesso
- [ ] Tamanho do bundle verificado
- [ ] CORS configurado no backend
- [ ] SSL/HTTPS ativado
- [ ] Cache headers configurados
- [ ] Compression ativado (gzip)
- [ ] CDN/DNS apontando corretamente
- [ ] Testes em produção executados
- [ ] Monitoramento/analytics ativado

---

## Performance Checklist

- [ ] Bundle size < 1MB (gzipped)
- [ ] Lighthouse score > 90
- [ ] Core Web Vitals verde
- [ ] Tempo de carregamento < 3s
- [ ] Assets otimizados
- [ ] Cache policy implementada

---

## Troubleshooting

### CORS Error
- Verificar URL da API em `.env.local`
- Verificar configuração de CORS no backend
- Verificar headers de requisição

### Blank Page
- Verificar console do navegador (F12)
- Verificar arquivo dist/index.html
- Verificar nginx/server config

### Slow Load
- Ativar gzip compression
- Implementar cache headers
- Usar CDN
- Verificar performance do backend

---

## Monitoramento

### Ferramentas Recomendadas
- **Vercel Analytics** - Incluso no Vercel
- **Google Analytics** - Adicionar REACT_APP_GA_ID
- **Sentry** - Error tracking
- **Datadog** - Monitoramento completo
- **New Relic** - Performance monitoring

---

## CI/CD Pipeline

### GitHub Actions

Criar `.github/workflows/deploy.yml`:

```yaml
name: Deploy

on:
  push:
    branches: [main]

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
        with:
          node-version: 18
      
      - name: Install
        run: npm install
      
      - name: Build
        run: npm run build
      
      - name: Deploy
        uses: vercel/action@main
        with:
          vercel-token: ${{ secrets.VERCEL_TOKEN }}
          vercel-org-id: ${{ secrets.VERCEL_ORG_ID }}
          vercel-project-id: ${{ secrets.VERCEL_PROJECT_ID }}
```

---

## Rollback

### Se algo der errado:

```bash
# Vercel
vercel rollback

# Netlify
netlify deploy --prod

# S3 + CloudFront
# Redeployar versão anterior
aws s3 sync dist/ s3://seu-bucket
aws cloudfront create-invalidation --distribution-id E123 --paths "/*"
```

---

## Suporte a Versões Antigas

```bash
# Manter versão anterior online
# Exemplo: /admin (versão 1.0) vs /admin-v2 (versão 2.0)

# Nginx
location /admin-v1/ {
    alias /var/www/nexustwos-admin-v1/;
}

location /admin/ {
    alias /var/www/nexustwos-admin/;
}
```

---

## Referências

- [Vite Deploy](https://vitejs.dev/guide/static-deploy.html)
- [React Best Practices](https://react.dev/learn)
- [Vercel Docs](https://vercel.com/docs)
- [Netlify Docs](https://docs.netlify.com)

---

**Parabéns! Seu painel administrativo está no ar!** 🚀
