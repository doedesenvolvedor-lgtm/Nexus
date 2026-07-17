import 'package:flutter/foundation.dart';
import 'dart:async';

/// Cache entry com TTL e invalidação
class CacheEntry<T> {
  final T value;
  final DateTime createdAt;
  final Duration ttl;
  
  CacheEntry({
    required this.value,
    required this.ttl,
  }) : createdAt = DateTime.now();
  
  bool get isExpired => DateTime.now().difference(createdAt) > ttl;
  
  int get ageMs => DateTime.now().difference(createdAt).inMilliseconds;
}

/// Serviço de cache otimizado com LRU e invalidação
class CacheService {
  static final CacheService _instance = CacheService._internal();
  
  factory CacheService() {
    return _instance;
  }
  
  CacheService._internal();
  
  // Cache: chave -> valor com TTL
  final Map<String, CacheEntry> _cache = {};
  
  // LRU tracking: chave -> acesso
  final Map<String, DateTime> _accessTime = {};
  
  // Tamanho máximo do cache
  static const int maxCacheSize = 100;
  static const Duration defaultTTL = Duration(minutes: 5);
  
  /// Armazena valor no cache com TTL
  void set<T>(
    String key,
    T value, {
    Duration ttl = defaultTTL,
  }) {
    debugPrint('🔵 [Cache] SET: $key (TTL: ${ttl.inSeconds}s)');
    
    _cache[key] = CacheEntry<T>(
      value: value,
      ttl: ttl,
    );
    _accessTime[key] = DateTime.now();
    
    _enforceMaxSize();
  }
  
  /// Recupera valor do cache
  T? get<T>(String key) {
    final entry = _cache[key] as CacheEntry<T>?;
    
    if (entry == null) {
      debugPrint('🔴 [Cache] MISS: $key');
      return null;
    }
    
    if (entry.isExpired) {
      debugPrint('⏰ [Cache] EXPIRED: $key');
      _cache.remove(key);
      _accessTime.remove(key);
      return null;
    }
    
    // Atualiza access time para LRU
    _accessTime[key] = DateTime.now();
    debugPrint('🟢 [Cache] HIT: $key (age: ${entry.ageMs}ms)');
    
    return entry.value;
  }
  
  /// Remove entrada do cache
  void remove(String key) {
    _cache.remove(key);
    _accessTime.remove(key);
    debugPrint('🗑️  [Cache] REMOVED: $key');
  }
  
  /// Remove todas as entradas com prefixo
  void removeByPrefix(String prefix) {
    final keysToRemove = _cache.keys
        .where((key) => key.startsWith(prefix))
        .toList();
    
    for (final key in keysToRemove) {
      remove(key);
    }
    
    debugPrint('🗑️  [Cache] REMOVED ${keysToRemove.length} entries with prefix: $prefix');
  }
  
  /// Limpa todo o cache
  void clear() {
    _cache.clear();
    _accessTime.clear();
    debugPrint('🗑️  [Cache] CLEARED');
  }
  
  /// Retorna tamanho do cache
  int get size => _cache.length;
  
  /// Estatísticas do cache
  Map<String, dynamic> getStats() {
    int expired = 0;
    int totalAge = 0;
    
    for (final entry in _cache.values) {
      if (entry.isExpired) expired++;
      totalAge += entry.ageMs;
    }
    
    return {
      'size': _cache.length,
      'expired': expired,
      'maxSize': maxCacheSize,
      'averageAgeMs': _cache.isEmpty ? 0 : totalAge ~/ _cache.length,
    };
  }
  
  /// Limpa entradas expiradas
  void cleanExpired() {
    final expiredKeys = _cache.entries
        .where((e) => e.value.isExpired)
        .map((e) => e.key)
        .toList();
    
    for (final key in expiredKeys) {
      remove(key);
    }
    
    debugPrint('🧹 [Cache] CLEANED ${expiredKeys.length} expired entries');
  }
  
  /// Enforça tamanho máximo usando LRU
  void _enforceMaxSize() {
    if (_cache.length <= maxCacheSize) return;
    
    // Remove o menos recentemente acessado
    final lruKey = _accessTime.entries
        .reduce((a, b) => a.value.isBefore(b.value) ? a : b)
        .key;
    
    remove(lruKey);
    debugPrint('⚠️  [Cache] EVICTED LRU: $lruKey (size: ${_cache.length})');
  }
  
  /// Get com fallback: tenta cache, se não encontrar, executa função
  Future<T> getOrFetch<T>(
    String key,
    Future<T> Function() fetchFn, {
    Duration ttl = defaultTTL,
  }) async {
    final cached = get<T>(key);
    if (cached != null) return cached;
    
    debugPrint('🔄 [Cache] FETCHING: $key');
    final value = await fetchFn();
    set(key, value, ttl: ttl);
    
    return value;
  }
  
  /// Padrão de cache com invalidação automática
  Future<T> withCache<T>(
    String cacheKey,
    Future<T> Function() fn, {
    Duration ttl = defaultTTL,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final cached = get<T>(cacheKey);
      if (cached != null) return cached;
    }
    
    final result = await fn();
    set(cacheKey, result, ttl: ttl);
    return result;
  }
}

/// Extension para facilitar uso em Widgets
extension CacheServiceExtension on String {
  /// Usa esta string como chave de cache
  T? getCached<T>() => CacheService().get<T>(this);
  
  void setCached<T>(T value, {Duration? ttl}) {
    CacheService().set<T>(this, value, ttl: ttl ?? CacheService.defaultTTL);
  }
  
  void removeCached() => CacheService().remove(this);
}

/// Decorator para cache automático em funções
typedef CachedAsyncFunction<T> = Future<T> Function();

/// Pattern de cache para requisições HTTP frequentes
class ApiCacheManager {
  static const cachePrefix = 'api_';
  
  // Cache keys
  static const String mediaListKey = '${cachePrefix}media_list';
  static const String userProfileKey = '${cachePrefix}user_profile';
  static const String subscriptionsKey = '${cachePrefix}subscriptions';
  
  static final CacheService _cache = CacheService();
  
  /// Invalida todo o cache de API
  static void invalidateAll() {
    _cache.removeByPrefix(cachePrefix);
  }
  
  /// Invalida cache de entidade específica
  static void invalidate(String entity) {
    _cache.removeByPrefix('${cachePrefix}${entity}_');
  }
  
  /// Get com cache e retry
  static Future<T> getWithCache<T>(
    String key,
    Future<T> Function() fn, {
    Duration ttl = const Duration(minutes: 5),
    bool forceRefresh = false,
  }) async {
    return _cache.withCache<T>(
      key,
      fn,
      ttl: ttl,
      forceRefresh: forceRefresh,
    );
  }
}
