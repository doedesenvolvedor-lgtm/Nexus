"""
Exemplo de uso: Autenticação JWT para Streams

Este script demonstra como:
1. Fazer login
2. Obter token de streaming
3. Acessar stream M3U8 com token
"""

import requests
import json
from typing import Optional

# Configuração
API_BASE = "http://localhost:8000"  # Mudar para produção
DEMO_EMAIL = "user@example.com"
DEMO_PASSWORD = "password123"


class NexusStreamClient:
    def __init__(self, base_url: str = API_BASE):
        self.base_url = base_url
        self.user_token: Optional[str] = None
        self.stream_token: Optional[str] = None
    
    def login(self, email: str, password: str) -> dict:
        """Login e obter JWT de usuário."""
        response = requests.post(
            f"{self.base_url}/auth/login",
            json={"email": email, "password": password}
        )
        response.raise_for_status()
        data = response.json()
        self.user_token = data["access_token"]
        print(f"✅ Login bem-sucedido!")
        print(f"   User JWT: {self.user_token[:50]}...")
        return data
    
    def get_stream_url(self, media_id: str) -> str:
        """Obter URL de streaming com token JWT."""
        if not self.user_token:
            raise ValueError("Primeiro faça login com .login()")
        
        response = requests.get(
            f"{self.base_url}/media/{media_id}/play",
            headers={"Authorization": f"Bearer {self.user_token}"}
        )
        response.raise_for_status()
        data = response.json()
        
        self.stream_token = data["token"]
        stream_url = data["stream"]
        
        print(f"✅ Stream obtido!")
        print(f"   Título: {data['title']}")
        print(f"   Stream Token: {self.stream_token[:50]}...")
        print(f"   URL: {stream_url[:80]}...")
        print(f"   Expira em: {data['expires_in']} segundos")
        
        return stream_url
    
    def get_stream_token_only(self, media_id: str) -> dict:
        """Obter apenas o token (sem outros dados)."""
        if not self.user_token:
            raise ValueError("Primeiro faça login com .login()")
        
        response = requests.get(
            f"{self.base_url}/media/{media_id}/stream-token",
            headers={"Authorization": f"Bearer {self.user_token}"}
        )
        response.raise_for_status()
        data = response.json()
        
        print(f"✅ Token obtido!")
        print(f"   Token: {data['token'][:50]}...")
        print(f"   Expira em: {data['expires_in']} segundos")
        
        return data
    
    def validate_stream_access(self, stream_url: str) -> bool:
        """Testar se consegue acessar o stream com token."""
        response = requests.head(stream_url)
        if response.status_code == 200:
            print(f"✅ Stream acessível!")
            return True
        else:
            print(f"❌ Erro ao acessar stream: {response.status_code}")
            print(f"   {response.text}")
            return False


# Exemplo de uso
if __name__ == "__main__":
    print("=" * 60)
    print("🎬 NEXUS TWOS - STREAM JWT AUTH DEMO")
    print("=" * 60)
    
    client = NexusStreamClient()
    
    try:
        # 1. Login
        print("\n1️⃣  Fazendo login...")
        client.login(DEMO_EMAIL, DEMO_PASSWORD)
        
        # 2. Obter URL de stream (opção 1)
        print("\n2️⃣  Obtendo URL de stream...")
        stream_url = client.get_stream_url("media-123")  # Mudar ID
        
        # 3. Obter apenas token (opção 2)
        print("\n3️⃣  Obtendo token separadamente...")
        token_data = client.get_stream_token_only("media-123")
        
        # 4. Validar acesso
        print("\n4️⃣  Validando acesso ao stream...")
        client.validate_stream_access(stream_url)
        
        # 5. Mostrar URL completa
        print("\n5️⃣  URL Completa para player HLS:")
        print(f"   {stream_url}")
        
        print("\n" + "=" * 60)
        print("✅ DEMO COMPLETO!")
        print("=" * 60)
        
    except requests.exceptions.RequestException as e:
        print(f"\n❌ Erro: {e}")
        print("\nDica: Verifique se o backend está rodando em http://localhost:8000")


# Exemplo com HLS.js (para copiar no HTML)
HLIST_JS_EXAMPLE = """
<!-- index.html -->
<!DOCTYPE html>
<html>
<head>
    <title>Nexus Twos - Streaming</title>
    <script src="https://cdn.jsdelivr.net/npm/hls.js@latest"></script>
    <style>
        body { margin: 0; background: #090909; }
        video {
            width: 100%;
            height: 100vh;
            background: #000;
        }
        .info { color: #fff; padding: 10px; }
    </style>
</head>
<body>
    <div class="info">
        <h1>🎬 Nexustwos</h1>
        <p id="status">Carregando...</p>
    </div>
    
    <video id="video" controls></video>
    
    <script>
        // 1. Obter token do usuário (já fez login antes)
        const userToken = localStorage.getItem('user_token');
        const mediaId = 'media-123';  // Mudar ID
        
        async function loadStream() {
            try {
                // 2. Requisitar stream com autenticação
                const response = await fetch(
                    `http://api.nexustwos.com/media/${mediaId}/play`,
                    {
                        headers: {
                            'Authorization': `Bearer ${userToken}`
                        }
                    }
                );
                
                if (!response.ok) {
                    throw new Error(`HTTP ${response.status}`);
                }
                
                const data = await response.json();
                const streamUrl = data.stream;  // Já tem token incluso
                
                // 3. Carregar em HLS.js
                const video = document.getElementById('video');
                
                if (Hls.isSupported()) {
                    const hls = new Hls();
                    hls.loadSource(streamUrl);
                    hls.attachMedia(video);
                    
                    hls.on(Hls.Events.MANIFEST_PARSED, function() {
                        video.play();
                        document.getElementById('status').textContent = 
                            `✅ ${data.title} - Streaming`;
                    });
                    
                    hls.on(Hls.Events.ERROR, function(event, data) {
                        if (data.fatal) {
                            console.error('Erro fatal de streaming:', data);
                            document.getElementById('status').textContent = 
                                '❌ Erro ao carregar stream';
                        }
                    });
                } else if (video.canPlayType('application/vnd.apple.mpegurl')) {
                    // Safari nativo
                    video.src = streamUrl;
                }
            } catch (error) {
                console.error('Erro:', error);
                document.getElementById('status').textContent = 
                    `❌ ${error.message}`;
            }
        }
        
        loadStream();
    </script>
</body>
</html>
"""

print("\n" + "=" * 60)
print("💡 EXEMPLO HLS.JS")
print("=" * 60)
print(HLIST_JS_EXAMPLE)
