import 'dart:convert';
import 'dart:typed_data';

import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/app_store.dart';
import '../models/models.dart';

/// Autentikasi demo dengan kontrak yang sama seperti Firebase Auth.
class AuthService {
  AuthService({AppStore? store}) : _store = store ?? AppStore.instance;

  final AppStore _store;

  AppUser? get currentUser => _store.currentUser;

  /// Demo: langsung mengirim pengguna aktif saat ini.
  Stream<AppUser?> get authStateChanges async* {
    yield _store.currentUser;
  }

  Future<AppUser?> signIn(String email, String password) =>
      _store.signIn(email, password);

  Future<AppUser> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required Role role,
  }) => _store.register(
    name: name,
    email: email,
    phone: phone,
    password: password,
    role: role,
  );

  Future<void> signOut() => _store.signOut();
}

/// Service laporan: satu pintu untuk semua perubahan status.
class ReportService {
  ReportService({AppStore? store}) : _store = store ?? AppStore.instance;

  final AppStore _store;

  Stream<List<Report>> watchMyReports(String userId) =>
      _store.watchMyReports(userId);

  Stream<List<Report>> watchPendingReports() => _store.watchPendingReports();

  Stream<List<Report>> watchAllReports() => _store.watchAllReports();

  Stream<List<Report>> watchOfficerReports(String officerId) =>
      _store.watchOfficerReports(officerId);

  Future<String> createReport(CreateReportInput input) async =>
      (await _store.createReport(input)).id;

  Future<void> verifyReport(String reportId, String adminId) =>
      _store.verifyReport(reportId, adminId);

  Future<void> rejectReport(String reportId, String adminId, String reason) =>
      _store.rejectReport(reportId, adminId, reason);

  Future<void> assignReport(
    String reportId,
    String officerId,
    String adminId,
  ) => _store.assignReport(reportId, officerId, adminId);

  Future<void> startAssignment(String reportId, String officerId) =>
      _store.startAssignment(reportId, officerId);

  Future<void> completeAssignment(
    String reportId,
    String officerId,
    String note, {
    String? proofPath,
  }) => _store.completeAssignment(
    reportId,
    officerId,
    note,
    proofPath: proofPath,
  );

  /// Foto laporan: Firebase Storage bila cloud aktif, kalau tidak base64
  /// (base64 dipakai supaya demo juga jalan di web tanpa konfigurasi).
  Future<String> uploadReportPhoto(
    String reportId,
    Uint8List bytes,
    String type,
  ) async {
    final url = await _store.uploadPhoto(type, bytes);
    return url ?? base64Encode(bytes);
  }
}

/// GPS, pencarian lokasi teks, + navigasi eksternal. Tidak menulis database.
class LocationService {
  static const fallbackCenter = LatLng(0.9186, 104.4467);
  static const fallbackZoom = 13.5;
  static const fallbackAddress = 'Tanjungpinang, Kepulauan Riau';

  Future<LocationData> getCurrentLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationFailure(
        'GPS belum aktif. Nyalakan lokasi di HP, atau pilih titik manual di peta.',
        canOpenSettings: true,
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw const LocationFailure(
        'Izin lokasi ditolak. Kamu masih bisa memilih titik manual di peta.',
      );
    }
    if (permission == LocationPermission.deniedForever) {
      throw const LocationFailure(
        'Izin lokasi diblokir permanen. Aktifkan lewat pengaturan aplikasi.',
        canOpenSettings: true,
      );
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 25),
      ),
    );

    return LocationData(
      address: '',
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }

  /// Cari koordinat dari ketikan nama tempat/alamat (contoh: "Tugu Sirih").
  Future<LocationData> searchLocation(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      throw const LocationFailure('Ketik nama tempat atau alamat terlebih dahulu.');
    }

    final searchQuery = trimmed.toLowerCase().contains('tanjungpinang') ||
            trimmed.toLowerCase().contains('kepri') ||
            trimmed.toLowerCase().contains('indonesia')
        ? trimmed
        : '$trimmed Tanjungpinang';

    final uri = Uri.https(
      'nominatim.openstreetmap.org',
      '/search',
      {
        'q': searchQuery,
        'format': 'json',
        'limit': '1',
      },
    );

    final response = await http.get(
      uri,
      headers: {
        'User-Agent': 'com.example.apk_sipahal',
        'Accept-Language': 'id',
      },
    );

    if (response.statusCode != 200) {
      throw const LocationFailure(
        'Gagal mencari lokasi ke server peta. Coba lagi atau pilih di peta.',
      );
    }

    final list = jsonDecode(response.body) as List<dynamic>;
    if (list.isEmpty) {
      throw LocationFailure(
        'Lokasi "$trimmed" tidak ditemukan. Coba tambahkan nama jalan/kota atau pilih di peta.',
      );
    }

    final first = list.first as Map<String, dynamic>;
    final lat = double.tryParse(first['lat']?.toString() ?? '');
    final lon = double.tryParse(first['lon']?.toString() ?? '');
    if (lat == null || lon == null) {
      throw const LocationFailure('Koordinat hasil pencarian tidak valid.');
    }

    final displayName = (first['display_name']?.toString() ?? '').trim();
    return LocationData(
      address: displayName.isEmpty ? trimmed : displayName,
      latitude: lat,
      longitude: lon,
    );
  }

  Future<bool> openNavigation({
    required double latitude,
    required double longitude,
    String? label,
  }) async {
    final name = Uri.encodeComponent(label ?? 'Lokasi laporan');
    final geo = Uri.parse(
      'geo:$latitude,$longitude?q=$latitude,$longitude($name)',
    );
    if (await canLaunchUrl(geo)) {
      return launchUrl(geo, mode: LaunchMode.externalApplication);
    }

    final osm = Uri.parse(
      'https://www.openstreetmap.org/?mlat=$latitude&mlon=$longitude#map=16/$latitude/$longitude',
    );
    return launchUrl(osm, mode: LaunchMode.externalApplication);
  }
}

/// Akun demo untuk memudahkan presentasi.
class DemoAccount {
  const DemoAccount({
    required this.role,
    required this.email,
    required this.password,
  });

  final Role role;
  final String email;
  final String password;
}

const demoAccounts = <DemoAccount>[
  DemoAccount(
    role: Role.warga,
    email: 'warga@sipahal.com',
    password: 'warga123',
  ),
  DemoAccount(
    role: Role.petugas,
    email: 'petugas@sipahal.com',
    password: 'petugas123',
  ),
  DemoAccount(
    role: Role.admin,
    email: 'admin@sipahal.com',
    password: 'admin123',
  ),
];