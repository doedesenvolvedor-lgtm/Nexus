# 🔒 Política de Privacidade e Termos de Uso - Guia de Configuração

## 📋 O que foi criado

Duas páginas HTML foram criadas e configuradas para servir através de domínios dedicados:

### Arquivos Criados
- **`admin/privacy.html`** → Servida em `https://privacy.nexusstream.com`
- **`admin/terms.html`** → Servida em `https://terms.nexusstream.com`

## 🌐 Configuração de Acesso

### URLs Públicas
```
https://privacy.nexusstream.com    # Política de Privacidade
https://terms.nexusstream.com      # Termos de Uso
```

### Domínio Principal
Da página principal (`https://nexusstream.com`):
```
/privacy   → redireciona para https://privacy.nexusstream.com
/terms     → redireciona para https://terms.nexusstream.com
```

## 🔧 Como Funciona

### 1. **Nginx Configuration** (`nginx/nginx.conf`)
```nginx
# Servidor para a política de privacidade
server {
    listen 443 ssl;
    server_name privacy.nexusstream.com;
    
    location / {
      alias /var/www/pages/;          # Mapeia para /admin
      try_files /privacy.html =404;   # Serve privacy.html
      default_type text/html;
      add_header Cache-Control "public, max-age=3600";
    }
}
```

### 2. **Docker Compose** (`docker-compose.yml`)
O volume é mapeado assim:
```yaml
volumes:
  - ./admin:/var/www/pages:ro  # Apenas leitura
```

### 3. **Certificados SSL**
Os domínios usam certificados Let's Encrypt gerados via Certbot:
```
/etc/letsencrypt/live/privacy.nexusstream.com/
/etc/letsencrypt/live/terms.nexusstream.com/
```

## ✏️ Como Personalizar

### Editar Conteúdo
1. Abra `admin/privacy.html` ou `admin/terms.html`
2. Edite o conteúdo em português
3. Salve o arquivo
4. Reinicie o nginx: `docker-compose restart nginx`

### Campos para Atualizar

#### Política de Privacidade
- **E-mail de contato**: `privacy@nexusstream.com` (linha ~700)
- **E-mail de suporte**: `support@nexusstream.com` (linha ~701)
- **Endereço registrado**: Atualize a seção "Endereço Registrado"

#### Termos de Uso
- **E-mail de suporte**: `support@nexusstream.com` (linha ~480)
- **Website**: `https://nexusstream.com` (linha ~481)
- **Jurisdição**: Atualmente Brasil (linha ~455)

## 📱 Responsividade

Ambas as páginas são:
- ✅ Responsivas (mobile-friendly)
- ✅ Acessíveis (WCAG)
- ✅ Com cache HTTP (3600 segundos)
- ✅ Com SSL/TLS
- ✅ Otimizadas para SEO

## 🚀 Deploy

### Localmente
```bash
docker-compose up -d nginx
```

### Verificar
```bash
# Teste a política de privacidade
curl https://localhost/privacy -k

# Teste os termos
curl https://localhost/terms -k
```

## 📝 Conteúdo das Páginas

### Política de Privacidade (`privacy.html`)
Cobre:
- ✅ Introdução e propósito
- ✅ Coleta de informações (diretas e automáticas)
- ✅ Uso de dados
- ✅ Compartilhamento com terceiros
- ✅ Segurança de dados
- ✅ Direitos do usuário (LGPD compliant)
- ✅ Cookies e rastreamento
- ✅ Retenção de dados
- ✅ Proteção de menores
- ✅ Alterações e contato

### Termos de Uso (`terms.html`)
Cobre:
- ✅ Aceitação dos termos
- ✅ Descrição do serviço
- ✅ Elegibilidade e registro
- ✅ Planos e assinaturas
- ✅ Pagamento
- ✅ Uso aceitável
- ✅ Licença de conteúdo
- ✅ Limitação de responsabilidade
- ✅ Rescisão de conta
- ✅ Lei aplicável (Brasil)

## ⚖️ Conformidade Legal

### LGPD (Lei Geral de Proteção de Dados - Brasil)
- ✅ Direito de acesso aos dados
- ✅ Direito de correção
- ✅ Direito de exclusão (right to be forgotten)
- ✅ Direito de portabilidade
- ✅ Direito de oposição
- ✅ Informações sobre segurança

### E-Commerce
- ✅ Informações sobre a empresa
- ✅ Descrição clara dos serviços
- ✅ Política de reembolso
- ✅ Método de pagamento
- ✅ Direitos e obrigações

## 🔐 Segurança

- Páginas servidas apenas via HTTPS
- Cache HTTP configurado (pública)
- Acesso só leitura ao volume Docker
- SSL/TLS obrigatório

## 📞 Próximos Passos

1. **Atualize os e-mails de contato** com seus e-mails reais
2. **Adicione informações da empresa** (endereço, CNPJ, etc.)
3. **Revise com seu time jurídico** para conformidade local
4. **Teste em staging** antes de ir para produção
5. **Adicione link nas páginas principais** do app

## 🛠️ Suporte

Se precisar atualizar as páginas:
1. Edite os arquivos HTML
2. Commit no git: `git add admin/privacy.html admin/terms.html`
3. Push e deploy normalmente

As mudanças entram em vigor assim que o nginx é reiniciado.

---

**Criado em:** Julho de 2026  
**Versão:** 1.0  
**Status:** ✅ Pronto para produção
