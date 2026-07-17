#!/bin/bash
# benchmark_cache.sh - Teste de impacto do cache
# Uso: bash nginx/benchmark_cache.sh

API_URL="${1:-http://localhost:8000}"
STREAMS_COUNT="${2:-10}"
REQUESTS_PER_STREAM="${3:-50}"

echo "================================"
echo "🚀 CACHE BENCHMARK TEST"
echo "================================"
echo ""
echo "Configuração:"
echo "  API URL: $API_URL"
echo "  Streams a testar: $STREAMS_COUNT"
echo "  Requisições por stream: $REQUESTS_PER_STREAM"
echo ""

# Função para testar cache
test_cache() {
    local url=$1
    local name=$2
    
    echo "📊 Testando: $name"
    echo "   URL: $url"
    echo ""
    
    local times=()
    local cache_hits=0
    local cache_misses=0
    
    for i in $(seq 1 $REQUESTS_PER_STREAM); do
        # Executar curl e capturar tempo
        response=$(curl -s -w "\n%{time_total}|%{http_code}|%{cache_status}" "$url" 2>&1)
        time_taken=$(echo "$response" | tail -1 | cut -d'|' -f1)
        http_code=$(echo "$response" | tail -1 | cut -d'|' -f2)
        cache_status=$(echo "$response" | tail -1 | cut -d'|' -f3)
        
        times+=($time_taken)
        
        if [ "$cache_status" == "HIT" ]; then
            ((cache_hits++))
        else
            ((cache_misses++))
        fi
        
        if [ $((i % 10)) -eq 0 ]; then
            echo -n "."
        fi
    done
    echo ""
    echo ""
    
    # Calcular estatísticas
    local sum=0
    for t in "${times[@]}"; do
        sum=$(echo "$sum + $t" | bc)
    done
    
    local avg=$(echo "scale=3; $sum / $REQUESTS_PER_STREAM" | bc)
    local min=$(printf '%s\n' "${times[@]}" | sort -n | head -1)
    local max=$(printf '%s\n' "${times[@]}" | sort -n | tail -1)
    
    echo "   Resultados:"
    echo "   ├─ Tempo médio: ${avg}ms"
    echo "   ├─ Tempo mín: ${min}ms"
    echo "   ├─ Tempo máx: ${max}ms"
    echo "   ├─ Cache HIT: $cache_hits / $REQUESTS_PER_STREAM"
    echo "   └─ Cache MISS: $cache_misses / $REQUESTS_PER_STREAM"
    echo ""
}

# Testar diferentes tipos de conteúdo
echo "1️⃣  Testando Segments (TS) - Deve cachear 100%"
test_cache "$API_URL/streams/test/1080p/segment_001.ts" "Segment TS"

echo "2️⃣  Testando Playlist (M3U8) - Deve cachear após 1ª requisição"
test_cache "$API_URL/streams/test/master.m3u8" "Master Playlist"

echo "3️⃣  Testando API Dinâmica - NÃO deve cachear"
test_cache "$API_URL/media/test-movie/play" "API Dinâmica"

echo ""
echo "================================"
echo "✅ BENCHMARK COMPLETO"
echo "================================"
echo ""
echo "Interpretação:"
echo "  Segments (TS):    Tempo deve diminuir após requisição 2"
echo "  Playlists (M3U8): Tempo deve diminuir significativamente"
echo "  API Dinâmica:     Tempo deve ser consistente (sem cache)"
echo ""
