import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../utils/constants.dart';

class DownloadProgress {
  final int totalBytes;
  final int receivedBytes;
  final double progress;

  DownloadProgress({
    required this.totalBytes,
    required this.receivedBytes,
    required this.progress,
  });
}

class DownloadService {
  final Map<String, http.StreamedResponse> _activeDownloads = {};

  /// Download de arquivo de mídia com tracker de progresso
  Stream<DownloadProgress> downloadFile({
    required String url,
    required String fileName,
    Map<String, String>? headers,
  }) async* {
    try {
      final request = http.Request('GET', Uri.parse(url));
      if (headers != null) {
        request.headers.addAll(headers);
      }

      final response = await http.Client().send(request).timeout(streamTimeout);

      if (response.statusCode != 200) {
        throw Exception('Falha ao baixar: HTTP ${response.statusCode}');
      }

      final totalBytes = response.contentLength ?? 0;
      var receivedBytes = 0;

      // Obter diretório de downloads
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/downloads/$fileName');
      await file.parent.create(recursive: true);

      // Stream de escrita do arquivo
      final sink = file.openWrite();
      await for (final chunk in response.stream) {
        sink.add(chunk);
        receivedBytes += chunk.length;

        yield DownloadProgress(
          totalBytes: totalBytes,
          receivedBytes: receivedBytes,
          progress: totalBytes > 0 ? receivedBytes / totalBytes : 0,
        );
      }

      await sink.close();
    } catch (e) {
      throw Exception('Erro ao baixar arquivo: $e');
    }
  }

  /// Verificar se arquivo já foi baixado
  Future<bool> isDownloaded(String fileName) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/downloads/$fileName');
    return file.exists();
  }

  /// Obter caminho do arquivo baixado
  Future<String?> getDownloadedPath(String fileName) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/downloads/$fileName');
    if (await file.exists()) {
      return file.path;
    }
    return null;
  }

  /// Remover arquivo baixado
  Future<void> deleteDownload(String fileName) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/downloads/$fileName');
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// Listar todos os downloads
  Future<List<String>> listDownloads() async {
    final dir = await getApplicationDocumentsDirectory();
    final downloadDir = Directory('${dir.path}/downloads');
    if (!await downloadDir.exists()) {
      return [];
    }
    return downloadDir
        .listSync()
        .whereType<File>()
        .map((f) => f.uri.pathSegments.last)
        .toList();
  }

  void cancelDownload(String url) {
    _activeDownloads[url]?.stream.listen(null, cancelOnError: true);
    _activeDownloads.remove(url);
  }
}
