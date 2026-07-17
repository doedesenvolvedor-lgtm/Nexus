"""
Exemplo de uso: Rate Limiting

Demonstra como o rate limiting funciona e como tratar respostas 429.
"""

import requests
import json
import time
from typing import Optional

# Configuração
API_BASE = "http://localhost:8000"


class RateLimitDemo:
    """Demonstra rate limiting em ação."""
    
    def __init__(self, base_url: str = API_BASE):
        self.base_url = base_url
        self.user_token: Optional[str] = None
    
    def demo_global_limit(self):
        """Demonstra limite global (1000 req/hora por IP)."""
        print("\n" + "="*60)
        print("1️⃣  DEMO: Limite Global por IP (1000 req/hora)")
        print("="*60)
        
        print("\nFazendo 5 requisições...")
        for i in range(1, 6):
            response = requests.get(
                f"{self.base_url}/health",
                timeout=5
            )
            
            headers = response.headers
            print(f"\nRequisição {i}:")
            print(f"  Status: {response.status_code}")
            print(f"  Limite: {headers.get('X-RateLimit-Limit')}")
            print(f"  Restante: {headers.get('X-RateLimit-Remaining')}")
            print(f"  Reset em: {headers.get('X-RateLimit-Reset')}s")
            
            time.sleep(0.1)
    
    def demo_login_brute_force_protection(self):
        """Demonstra proteção contra brute force (5 tentativas/15min)."""
        print("\n" + "="*60)
        print("2️⃣  DEMO: Proteção Brute Force no Login (5 tentativas/15min)")
        print("="*60)
        
        print("\nFazendo 7 tentativas de login...")
        for i in range(1, 8):
            response = requests.post(
                f"{self.base_url}/auth/login",
                json={
                    "email": "wrong@example.com",
                    "password": "wrongpassword",
                },
                timeout=5
            )
            
            headers = response.headers
            print(f"\nTentativa {i}:")
            print(f"  Status: {response.status_code}")
            print(f"  Limite: {headers.get('X-RateLimit-Limit')}")
            print(f"  Restante: {headers.get('X-RateLimit-Remaining')}")
            
            if response.status_code == 429:
                retry_after = headers.get('Retry-After', 'N/A')
                print(f"  ❌ BLOQUEADO! Retry-After: {retry_after}s")
                print(f"  Resposta: {response.json()}")
                break
            
            time.sleep(0.2)
    
    def demo_stream_bandwidth_limit(self, media_id: str = "test-movie"):
        """Demonstra limite de streams (100 req/min)."""
        print("\n" + "="*60)
        print("3️⃣  DEMO: Limite de Streams (100 req/min)")
        print("="*60)
        
        if not self.user_token:
            print("⚠️  Token de usuário necessário. Faça login primeiro.")
            return
        
        print("\nFazendo 3 requisições de stream...")
        for i in range(1, 4):
            response = requests.get(
                f"{self.base_url}/media/{media_id}/play",
                headers={"Authorization": f"Bearer {self.user_token}"},
                timeout=5
            )
            
            headers = response.headers
            print(f"\nRequisição {i}:")
            print(f"  Status: {response.status_code}")
            print(f"  Limite: {headers.get('X-RateLimit-Limit')}")
            print(f"  Restante: {headers.get('X-RateLimit-Remaining')}")
            
            if response.status_code == 429:
                print(f"  ❌ LIMITE ATINGIDO")
                print(f"  {response.json()}")
                break
            
            time.sleep(0.1)
    
    def handle_rate_limit(self, response: requests.Response):
        """Como tratar resposta 429 no código."""
        if response.status_code == 429:
            retry_after = int(response.headers.get('Retry-After', 60))
            limit_info = response.json()
            
            print(f"\n⏱️  Rate limit atingido!")
            print(f"  Tente novamente em: {retry_after}s")
            print(f"  Mensagem: {limit_info['detail']}")
            print(f"  Limite: {limit_info['limit']}")
            print(f"  Restante: {limit_info['remaining']}")
            
            return retry_after
        
        return 0


# Exemplo em código de produção
def call_with_rate_limit_handling(url: str, max_retries: int = 3):
    """
    Exemplo de como fazer requisições com tratamento de rate limit.
    
    Retenta automaticamente com backoff exponencial.
    """
    
    retries = 0
    wait_time = 1
    
    while retries < max_retries:
        try:
            response = requests.get(url, timeout=10)
            
            if response.status_code == 429:
                retry_after = int(response.headers.get('Retry-After', 60))
                print(f"⏱️  Rate limited. Aguardando {retry_after}s...")
                time.sleep(retry_after)
                retries += 1
                continue
            
            response.raise_for_status()
            return response.json()
        
        except requests.exceptions.RequestException as e:
            print(f"❌ Erro: {e}")
            wait_time *= 2  # Backoff exponencial
            time.sleep(wait_time)
            retries += 1
    
    raise Exception(f"Falhou após {max_retries} tentativas")


# Headers de resposta com rate limit
RATE_LIMIT_HEADERS = {
    "X-RateLimit-Limit": "Número máximo de requisições",
    "X-RateLimit-Remaining": "Requisições restantes",
    "X-RateLimit-Reset": "Segundos até reset",
    "Retry-After": "Segundos até poder tentar novamente (apenas se 429)",
}


# Exemplo com JavaScript/TypeScript
JAVASCRIPT_EXAMPLE = """
// Como tratar 429 em JavaScript/TypeScript

async function fetchWithRateLimit(url, options = {}) {
    const maxRetries = 3;
    let retries = 0;
    
    while (retries < maxRetries) {
        const response = await fetch(url, options);
        
        // Verificar headers de rate limit
        const rateLimit = {
            limit: response.headers.get('X-RateLimit-Limit'),
            remaining: response.headers.get('X-RateLimit-Remaining'),
            reset: response.headers.get('X-RateLimit-Reset'),
        };
        
        console.log(`Rate Limit: ${rateLimit.remaining}/${rateLimit.limit}`);
        
        if (response.status === 429) {
            const retryAfter = parseInt(response.headers.get('Retry-After') || 60);
            console.warn(`Rate limit atingido! Aguardando ${retryAfter}s...`);
            
            // Aguardar antes de tentar novamente
            await new Promise(resolve => setTimeout(resolve, retryAfter * 1000));
            retries++;
            continue;
        }
        
        if (!response.ok) {
            throw new Error(`HTTP ${response.status}`);
        }
        
        return response.json();
    }
    
    throw new Error(`Falhou após ${maxRetries} tentativas`);
}

// Uso
const data = await fetchWithRateLimit(
    'https://api.nexustwos.com/media/movie-123/play',
    {
        headers: {
            'Authorization': `Bearer ${userToken}`
        }
    }
);
"""


# Exemplo com Python Requests
PYTHON_EXAMPLE = """
import requests
import time
from datetime import datetime, timedelta

class RateLimitClient:
    def __init__(self, base_url, max_retries=3):
        self.base_url = base_url
        self.max_retries = max_retries
        self.session = requests.Session()
        self.rate_limits = {}
    
    def request(self, method, endpoint, **kwargs):
        '''Faz request com tratamento automático de rate limit'''
        
        retries = 0
        url = f"{self.base_url}{endpoint}"
        
        while retries < self.max_retries:
            try:
                response = self.session.request(method, url, **kwargs)
                
                # Salvar headers de rate limit
                self.rate_limits[endpoint] = {
                    'limit': response.headers.get('X-RateLimit-Limit'),
                    'remaining': response.headers.get('X-RateLimit-Remaining'),
                    'reset': response.headers.get('X-RateLimit-Reset'),
                }
                
                # Se rate limited, aguardar e tentar novamente
                if response.status_code == 429:
                    retry_after = int(response.headers.get('Retry-After', 60))
                    print(f"⏱️  Rate limit atingido. Aguardando {retry_after}s...")
                    time.sleep(retry_after)
                    retries += 1
                    continue
                
                response.raise_for_status()
                return response
            
            except requests.exceptions.RequestException as e:
                print(f"❌ Erro: {e}")
                retries += 1
                if retries < self.max_retries:
                    time.sleep(2 ** retries)
        
        raise Exception(f"Request falhou após {self.max_retries} tentativas")

# Uso
client = RateLimitClient('https://api.nexustwos.com')
response = client.request('get', '/media/movie-123/play',
    headers={'Authorization': f'Bearer {token}'})
"""


if __name__ == "__main__":
    print("🚀 RATE LIMITING DEMO")
    
    demo = RateLimitDemo()
    
    # Demo 1: Limite global
    demo.demo_global_limit()
    
    # Demo 2: Proteção brute force
    # demo.demo_login_brute_force_protection()
    
    print("\n" + "="*60)
    print("💡 COMO TRATAR 429 EM SEU CÓDIGO")
    print("="*60)
    print("\n📝 Python:")
    print(PYTHON_EXAMPLE)
    print("\n📝 JavaScript:")
    print(JAVASCRIPT_EXAMPLE)
