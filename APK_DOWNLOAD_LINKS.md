# 📱 Link para Baixar APK - Nexus App

## 🎯 Informações de Download

### APK Disponível
- **Nome**: `nexus-app.apk`
- **Tamanho**: 55 MB
- **Versão**: Release
- **Status**: ✅ Pronto para download

---

## 🔗 Links de Download

### 1. **Download Direto (Local)**
```
Arquivo local: /workspaces/Nexus/backend/storage/releases/nexus-app.apk
```

### 2. **Via Backend API (quando rodando)**

**Obter informações de versão mais recente:**
```bash
curl -X GET http://localhost:8000/releases/latest
```

**Resposta esperada:**
```json
{
  "name": "nexus-app.apk",
  "size_mb": 55.0,
  "download_url": "/releases/nexus-app.apk",
  "date": "2026-07-20T21:31:00",
  "type": "APK Release",
  "direct_link": "/releases/nexus-app.apk"
}
```

**Listar todas as versões disponíveis:**
```bash
curl -X GET http://localhost:8000/releases/info
```

---

## 🚀 Como Usar os Links

### Opção 1: Download Local (Desenvolvimento)
```bash
cp /workspaces/Nexus/backend/storage/releases/nexus-app.apk ~/Desktop/
# Ou
adb install /workspaces/Nexus/backend/storage/releases/nexus-app.apk
```

### Opção 2: Via Backend Rodando Localmente
1. Inicie o backend:
```bash
cd /workspaces/Nexus/backend
python -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

2. Acesse o link no navegador ou cURL:
```bash
# Link direto
http://localhost:8000/releases/nexus-app.apk

# Ou obter informações
curl http://localhost:8000/releases/latest
```

### Opção 3: Em Produção (VPS)
Após fazer deploy em VPS:
```
https://seu-dominio.com/releases/nexus-app.apk
https://seu-dominio.com/releases/latest
https://seu-dominio.com/releases/info
```

---

## 📋 Endpoints Disponíveis

| Endpoint | Método | Descrição |
|----------|--------|-----------|
| `/releases/latest` | GET | Retorna informações da versão mais recente |
| `/releases/info` | GET | Lista todas as versões disponíveis |
| `/releases/nexus-app.apk` | GET | Download direto do APK |
| `/releases/{filename}` | HEAD | Verifica existência do arquivo |

---

## 🔄 Atualizar APK

### Quando você gerar um novo APK:

1. **Build novo APK:**
```bash
cd /workspaces/Nexus/nexus_mobile
flutter build apk --release
```

2. **Copiar para releases:**
```bash
cp build/app/outputs/apk/release/app-release.apk \
   /workspaces/Nexus/backend/storage/releases/nexus-app.apk
```

3. **Reiniciar backend (se rodando):**
```bash
# Ctrl+C no terminal onde está rodando
# Depois:
cd /workspaces/Nexus/backend
python -m uvicorn app.main:app --reload
```

---

## ✅ QR Code para Compartilhamento

Quando em produção, você pode gerar um QR code que aponta para:
```
https://seu-dominio.com/releases/nexus-app.apk
```

Escaneando este QR code, qualquer pessoa conseguirá baixar o APK diretamente.

---

## 📱 Instalação Manual no Celular

### Android:
1. Baixar o APK
2. Abrir arquivo no celular (se permitir arquivos desconhecidos)
3. Clicar em "Instalar"

### Via adb (Android Debug Bridge):
```bash
adb install nexus-app.apk
```

---

## 🛠️ Troubleshooting

**P: O link retorna 404?**
- Verifique se o arquivo existe em `/workspaces/Nexus/backend/storage/releases/`
- Reinicie o backend
- Verifique se o backend está rodando na porta correta

**P: O APK é muito grande?**
- Use `--split-per-abi` para criar APKs menores por arquitetura

**P: Preciso criar um novo APK?**
- Execute: `flutter build apk --release --split-per-abi`
- Copie os arquivos gerados para `/workspaces/Nexus/backend/storage/releases/`

---

## 📊 Monitoramento

Para acompanhar downloads (quando em produção), verifique logs:
```bash
tail -f /var/log/nexus/app.log | grep releases
```
