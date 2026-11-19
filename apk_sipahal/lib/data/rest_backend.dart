import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';

class RestApiException implements Exception {
  const RestApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class RestBackend {
  RestBackend({
    required this.baseUrl,
    http.Client? client,
  }) : _client = client ?? http.Client();

  /// Contoh:
  /// - Android Emulator: http://10.0.2.2:8000/api
  /// - HP fisik (satu jaringan Wi-Fi/hotspot dengan PC): http://`<IPv4_PC>`:8000/api
  /// - Server HTTPS: https://api.sipahal.my.id/api
  final String baseUrl;
  final http.Client _client;

  static const _tokenKey = 'sipahal_auth_token_v1';
  static const _timeout = Duration(seconds: 15);

  String? _token;
  String? get token => _token;
  bool get hasToken => _token != null && _token!.isNotEmpty;

  Future<void> initToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
  }

  Future<void> _saveToken(String? token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    if (token == null || token.isEmpty) {
      await prefs.remove(_tokenKey);
    } else {
      await prefs.setString(_tokenKey, token);
    }
  }

  Map<String, String> _headers({bool auth = true}) => {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        if (auth && _token != null) 'Authorization': 'Bearer $_token',
      };

  Uri _uri(String path) {
    final cleanBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final cleanPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$cleanBase$cleanPath');
  }

  Future<T> _guardRequest<T>(Future<T> Function() action) async {
    try {
      return await action().timeout(_timeout);
    } on RestApiException {
      rethrow;
    } on TimeoutException {
      throw const RestApiException(
        'Koneksi ke server melebihi batas waktu. Periksa jaringan dan server API.',
      );
    } on SocketException {
      throw const RestApiException(
        'Tidak dapat terhubung ke server API. Pastikan server Laravel aktif dan URL benar.',
      );
    } on http.ClientException {
      throw const RestApiException(
        'Gagal menghubungi server API. Periksa koneksi dan alamat baseUrl.',
      );
    } catch (error) {
      throw RestApiException('Terjadi kesalahan saat memproses data: $error');
    }
  }

  Map<String, dynamic> _decodeResponse(http.Response response) {
    Map<String, dynamic> body = {};
    if (response.body.isNotEmpty) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        body = decoded;
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    final message = (body['message'] as String?) ??
        switch (response.statusCode) {
          401 => 'Sesi berakhir. Silakan masuk kembali.',
          403 => 'Anda tidak memiliki izin untuk aksi ini.',
          404 => 'Data tidak ditemukan di server.',
          422 => 'Data yang dikirim tidak valid.',
          _ => 'Terjadi kesalahan server (${response.statusCode}).',
        };
    throw RestApiException(message, statusCode: response.statusCode);
  }

  // ---------------------------------------------------------------------------
  // Autentikasi
  // ---------------------------------------------------------------------------

  Future<AppUser> signIn(String email, String password) {
    return _guardRequest(() async {
      final res = await _client.post(
        _uri('/auth/login'),
        headers: _headers(auth: false),
        body: jsonEncode({
          'email': email.trim().toLowerCase(),
          'password': password,
        }),
      );

      final data = _decodeResponse(res);
      final token = data['token'] as String?;
      final userJson = data['user'] as Map<String, dynamic>?;
      if (token == null || userJson == null) {
        throw const RestApiException('Respons login dari server tidak lengkap.');
      }

      final user = AppUser.fromJson(userJson);
      if (!user.isActive) {
        throw const RestApiException(
          'Akun ini sedang dinonaktifkan oleh admin.',
          statusCode: 403,
        );
      }

      await _saveToken(token);
      return user;
    });
  }

  Future<AppUser> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    Role role = Role.warga,
  }) {
    return _guardRequest(() async {
      final res = await _client.post(
        _uri('/auth/register'),
        headers: _headers(auth: false),
        body: jsonEncode({
          'name': name.trim(),
          'email': email.trim().toLowerCase(),
          'phone': phone.trim(),
          'password': password,
          'role': role.id,
        }),
      );

      final data = _decodeResponse(res);
      final token = data['token'] as String?;
      final userJson = data['user'] as Map<String, dynamic>?;
      if (token == null || userJson == null) {
        throw const RestApiException('Respons registrasi tidak lengkap.');
      }

      final user = AppUser.fromJson(userJson);
      if (!user.isActive) {
        throw const RestApiException(
          'Akun ini sedang dinonaktifkan oleh admin.',
          statusCode: 403,
        );
      }

      await _saveToken(token);
      return user;
    });
  }

  Future<AppUser?> fetchCurrentUser() async {
    if (!hasToken) return null;
    return _guardRequest(() async {
      final res = await _client.get(_uri('/auth/me'), headers: _headers());
      final data = _decodeResponse(res);
      final userJson = (data['user'] ?? data) as Map<String, dynamic>;
      final user = AppUser.fromJson(userJson);
      if (!user.isActive) {
        throw const RestApiException(
          'Akun ini sedang dinonaktifkan oleh admin.',
          statusCode: 403,
        );
      }
      return user;
    });
  }

  Future<void> signOut() async {
    try {
      if (hasToken) {
        await _client
            .post(_uri('/auth/logout'), headers: _headers())
            .timeout(const Duration(seconds: 5));
      }
    } catch (_) {
      // Tetap hapus token lokal meskipun server sedang tidak terjangkau.
    } finally {
      await _saveToken(null);
    }
  }

  // ---------------------------------------------------------------------------
  // Officers & Reports CRUD
  // ---------------------------------------------------------------------------

  Future<List<AppUser>> fetchUsers() {
    return _guardRequest(() async {
      final res = await _client.get(_uri('/officers'), headers: _headers());
      final data = _decodeResponse(res);
      final list = (data['data'] as List?) ?? [];
      return list
          .map((e) => AppUser.fromJson(e as Map<String, dynamic>))
          .toList();
    });
  }

  Future<List<Report>> fetchReports() {
    return _guardRequest(() async {
      final res = await _client.get(_uri('/reports'), headers: _headers());
      final data = _decodeResponse(res);
      final list = (data['data'] as List?) ?? [];
      return list
          .map((e) => Report.fromJson(e as Map<String, dynamic>))
          .toList();
    });
  }

  Future<String> uploadPhoto(String type, Uint8List bytes) {
    return _guardRequest(() async {
      final request = http.MultipartRequest('POST', _uri('/reports/upload'));
      if (_token != null) {
        request.headers['Authorization'] = 'Bearer $_token';
      }
      request.headers['Accept'] = 'application/json';
      request.fields['type'] = type;
      request.files.add(
        http.MultipartFile.fromBytes(
          'photo',
          bytes,
          filename: '$type-${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
      );

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      final data = _decodeResponse(response);
      final url = data['url'] as String?;
      if (url == null || url.isEmpty) {
        throw const RestApiException('Server tidak mengembalikan URL foto.');
      }
      return url;
    });
  }

  Future<Report> createReport(CreateReportInput input) {
    return _guardRequest(() async {
      final res = await _client.post(
        _uri('/reports'),
        headers: _headers(),
        body: jsonEncode({
          'locationText': input.location.address.trim(),
          'latitude': input.location.latitude,
          'longitude': input.location.longitude,
          'category': input.category,
          'description': input.description.trim(),
          'photoData': input.photoData,
        }),
      );

      final data = _decodeResponse(res);
      final reportJson = (data['data'] ?? data) as Map<String, dynamic>;
      return Report.fromJson(reportJson);
    });
  }

  Future<Report> verifyReport(String reportId) {
    return _guardRequest(() async {
      final res = await _client.patch(
        _uri('/reports/$reportId/verify'),
        headers: _headers(),
      );
      final data = _decodeResponse(res);
      return Report.fromJson((data['data'] ?? data) as Map<String, dynamic>);
    });
  }

  Future<Report> rejectReport(String reportId, String reason) {
    return _guardRequest(() async {
      final res = await _client.patch(
        _uri('/reports/$reportId/reject'),
        headers: _headers(),
        body: jsonEncode({'rejectionReason': reason.trim()}),
      );
      final data = _decodeResponse(res);
      return Report.fromJson((data['data'] ?? data) as Map<String, dynamic>);
    });
  }

  Future<Report> assignReport(String reportId, String officerId) {
    return _guardRequest(() async {
      final res = await _client.patch(
        _uri('/reports/$reportId/assign'),
        headers: _headers(),
        body: jsonEncode({'officerId': officerId}),
      );
      final data = _decodeResponse(res);
      return Report.fromJson((data['data'] ?? data) as Map<String, dynamic>);
    });
  }

  Future<Report> startAssignment(String reportId) {
    return _guardRequest(() async {
      final res = await _client.patch(
        _uri('/reports/$reportId/start'),
        headers: _headers(),
      );
      final data = _decodeResponse(res);
      return Report.fromJson((data['data'] ?? data) as Map<String, dynamic>);
    });
  }

  Future<Report> completeAssignment(
    String reportId,
    String note, {
    String? proofPath,
  }) {
    return _guardRequest(() async {
      final res = await _client.patch(
        _uri('/reports/$reportId/complete'),
        headers: _headers(),
        body: jsonEncode({
          'note': note.trim(),
          'proofPhotoPath': proofPath,
        }),
      );
      final data = _decodeResponse(res);
      return Report.fromJson((data['data'] ?? data) as Map<String, dynamic>);
    });
  }
}