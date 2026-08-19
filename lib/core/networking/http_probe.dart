import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// Minimal HTTP client used for probing hosts and sending commands.
///
/// Brand-agnostic: payloads, headers and target ports are protocol-specific
/// and live in integrations.
abstract class HttpProbe {
  /// Performs a GET request to [url].
  ///
  /// Returns the response body when the host answers with HTTP 200, and
  /// `null` otherwise (including timeouts and connection failures).
  Future<String?> get(String url, {required Duration timeout});

  /// Performs a POST request to [url] with [body] and optional [headers].
  ///
  /// Returns the response body when the host answers with HTTP 200, and
  /// `null` otherwise (including timeouts and connection failures).
  Future<String?> post(
    String url, {
    required String body,
    Map<String, String>? headers,
    required Duration timeout,
  });

  /// Releases any underlying resources.
  Future<void> close();
}

/// [HttpProbe] implementation backed by [HttpClient].
class DartHttpProbe implements HttpProbe {
  DartHttpProbe({HttpClient? client}) : _client = client ?? HttpClient();

  final HttpClient _client;

  @override
  Future<String?> get(String url, {required Duration timeout}) async {
    try {
      final request = await _client.getUrl(Uri.parse(url)).timeout(timeout);
      final response = await request.close().timeout(timeout);
      if (response.statusCode != HttpStatus.ok) {
        return null;
      }
      return await response.transform(utf8.decoder).join().timeout(timeout);
    } on Exception {
      return null;
    }
  }

  @override
  Future<String?> post(
    String url, {
    required String body,
    Map<String, String>? headers,
    required Duration timeout,
  }) async {
    try {
      final request = await _client.postUrl(Uri.parse(url)).timeout(timeout);
      headers?.forEach((key, value) => request.headers.set(key, value));
      final bytes = latin1.encode(body);
      request.contentLength = bytes.length;
      request.add(bytes);
      final response = await request.close().timeout(timeout);
      if (response.statusCode != HttpStatus.ok) {
        return null;
      }
      return await response.transform(utf8.decoder).join().timeout(timeout);
    } on Exception {
      return null;
    }
  }

  @override
  Future<void> close() async {
    _client.close(force: true);
  }
}
