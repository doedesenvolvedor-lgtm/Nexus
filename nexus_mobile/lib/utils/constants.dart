import 'dart:io';

// API URL configuravel via variavel de ambiente ou fallback
const String _defaultApiUrl = 'http://10.0.2.2:8000';
const String _envApiUrl = String.fromEnvironment('API_URL', defaultValue: _defaultApiUrl);

// Para Android emulador, usa 10.0.2.2 como localhost
// Para iOS simulator ou web, usa localhost
// Para dispositivo fisico, precisa configurar o IP
String get apiUrl {
  // Verificar se estamos em ambiente web (precisa ser compile-time constant)
  return _envApiUrl;
}

// Timeout configurations
const Duration apiTimeout = Duration(seconds: 30);
const Duration streamTimeout = Duration(seconds: 60);
