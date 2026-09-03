import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../errors/exceptions.dart';
import '../utils/app_logger.dart';

class ApiClient {
  final http.Client _client;
  final Duration timeout;

  ApiClient({http.Client? client, this.timeout = const Duration(seconds: 15)})
      : _client = client ?? http.Client();

  Future<Map<String, dynamic>> get(String url, {Map<String, String>? headers}) async {
    try {
      AppLogger.debug('GET -> $url');
      final response = await _client
          .get(Uri.parse(url), headers: _defaultHeaders(headers))
          .timeout(timeout);
      return _processResponse(response);
    } on SocketException catch (e) {
      throw ServerException('Network connection error: ${e.message}');
    } on TimeoutException {
      throw ServerException('Request timed out after ${timeout.inSeconds} seconds');
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Unexpected network error: $e');
    }
  }

  Future<Map<String, dynamic>> post(String url,
      {required Map<String, dynamic> body, Map<String, String>? headers}) async {
    try {
      AppLogger.debug('POST -> $url');
      final response = await _client
          .post(
            Uri.parse(url),
            headers: _defaultHeaders(headers),
            body: jsonEncode(body),
          )
          .timeout(timeout);
      return _processResponse(response);
    } on SocketException catch (e) {
      throw ServerException('Network connection error: ${e.message}');
    } on TimeoutException {
      throw ServerException('Request timed out after ${timeout.inSeconds} seconds');
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Unexpected network error: $e');
    }
  }

  Map<String, String> _defaultHeaders(Map<String, String>? custom) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      ...?custom,
    };
  }

  Map<String, dynamic> _processResponse(http.Response response) {
    AppLogger.debug('Response status: ${response.statusCode}');
    if (response.body.isEmpty) return {};

    try {
      final decoded = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
        return {'data': decoded};
      } else {
        final errorMsg = decoded is Map && decoded['message'] != null
            ? decoded['message'].toString()
            : 'HTTP Error ${response.statusCode}';
        throw ServerException(errorMsg, statusCode: response.statusCode);
      }
    } on FormatException {
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {'raw': response.body};
      }
      throw ServerException('Invalid server response (Status: ${response.statusCode})',
          statusCode: response.statusCode);
    }
  }

  void close() {
    _client.close();
  }
}
