import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';
import 'firebase_backend.dart';
import 'rest_backend.dart';

/// Penyimpanan state utama aplikasi SIPAHAL.
/// Mendukung mode REST API (Laravel) dengan cache lokal SharedPreferences,
/// serta fallback Firebase / data demo bila REST API belum aktif.
class AppStore extends ChangeNotifier {
  AppStore._();

  static final AppStore instance = AppStore._();
  static const _storageKey = 'sipahal_state_v3';

  // Ganti URL ini sesuai lingkungan pengujian:
  // - Android Emulator: http://10.0.2.2:8000/api
  // - HP fisik (satu Wi-Fi/hotspot dengan PC): http://<IPv4_PC>:8000/api
  static const _defaultApiBaseUrl = 'http://10.0.2.2:8000/api';

  final List<AppUser> _users = <AppUser>[];
  final List<Report> _reports = <Report>[];
  final StreamController<void> _changes = StreamController<void>.broadcast();

  SharedPreferences? _prefs;
  AppUser? _currentUser;
  int _counter = 0;
  bool _ready = false;
  FirebaseBackend? _cloud;
  RestBackend? _api;

  bool get isReady => _ready;

  /// `true` bila aplikasi terhubung ke Firebase.
  bool get usingFirebase => _cloud != null;

  /// `true` bila aplikasi terhubung ke REST API Laravel.
  bool get usingApi => _api != null;

  AppUser? get currentUser => _currentUser;

  List<AppUser> get users => List.unmodifiable(_users);

  List<AppUser> get officers =>
      _users.where((u) => u.role == Role.petugas && u.isActive).toList();

  /// Laporan terbaru lebih dulu.
  List<Report> get reports {
    final list = List<Report>.from(_reports);
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return List.unmodifiable(list);
  }

  AppUser? userById(String? id) {
    if (id == null) return null;
    for (final u in _users) {
      if (u.uid == id) return u;
    }
    return null;
  }

  Future<void> refresh() async {
    final api = _api;
    if (api != null && api.hasToken) {
      try {
        final remoteReports = await api.fetchReports();
        _reports
          ..clear()
          ..addAll(remoteReports);
        _syncCounterFromReports();

        try {
          final remoteOfficers = await api.fetchUsers();
          for (final officer in remoteOfficers) {
            _upsertUser(officer);
          }
        } catch (error) {
          debugPrint('Gagal memuat daftar petugas saat refresh: $error');
        }

        await _save();
        notifyListeners();
        return;
      } catch (error) {
        debugPrint('Gagal refresh laporan dari API: $error');
      }
    }

    notifyListeners();
  }

  Future<void> init() async {
    if (_ready) return;
    _prefs = await SharedPreferences.getInstance();
    final raw = _prefs!.getString(_storageKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        _users
          ..clear()
          ..addAll(
            ((data['users'] as List?) ?? []).map(
              (e) => AppUser.fromJson(e as Map<String, dynamic>),
            ),
          );
        _reports
          ..clear()
          ..addAll(
            ((data['reports'] as List?) ?? []).map(
              (e) => Report.fromJson(e as Map<String, dynamic>),
            ),
          );
        _counter = (data['counter'] as num?)?.toInt() ?? _reports.length;
        final sessionId = data['session'] as String?;
        _currentUser = userById(sessionId);
      } catch (error) {
        debugPrint('Gagal memuat cache lokal: $error');
      }
    }

    // 1. Coba sambungkan ke REST API Laravel.
    final api = RestBackend(baseUrl: _defaultApiBaseUrl);
    await api.initToken();
    try {
      if (api.hasToken) {
        final me = await api.fetchCurrentUser();
        if (me != null) {
          _currentUser = me;
          _upsertUser(me);
        }
        final remoteReports = await api.fetchReports();
        _reports
          ..clear()
          ..addAll(remoteReports);
        _syncCounterFromReports();

        try {
          final remoteOfficers = await api.fetchUsers();
          for (final officer in remoteOfficers) {
            _upsertUser(officer);
          }
        } catch (error) {
          debugPrint('Gagal memuat petugas saat init: $error');
        }
      }
      _api = api;
    } catch (error) {
      debugPrint('REST API belum terjangkau saat init, pakai cache/demo: $error');
      // Jika token tidak valid / 401, tetap simpan instance _api agar login bisa lewat server.
      if (error is RestApiException && error.statusCode == 401) {
        await api.signOut();
        _currentUser = null;
        _api = api;
      } else {
        _api = api;
      }
    }

    // 2. Jika tidak memakai REST API, coba sambungkan Firebase.
    if (_api == null) {
      _cloud = await FirebaseBackend.connect();
      if (_cloud != null) {
        try {
          await _cloud!.attach(
            onSession: _applyCloudSession,
            onUsers: _applyCloudUsers,
            onReports: _applyCloudReports,
            onError: (error) => debugPrint('Sinkronisasi Firestore: $error'),
          );
        } catch (error) {
          debugPrint('Gagal memakai Firebase, beralih ke data lokal: $error');
          _cloud = null;
        }
      }
    }

    // 3. Jika keduanya tidak aktif, siapkan seed data demo lokal.
    if (_api == null && _cloud == null) {
      if (_users.isEmpty || _reports.isEmpty) {
        _seed();
        await _save();
      } else {
        _ensureDemoAccounts();
      }
    } else {
      await _save();
    }

    _ready = true;
    notifyListeners();
  }

  void _upsertUser(AppUser user) {
    _users.removeWhere((u) => u.uid == user.uid);
    _users.add(user);
  }

  void _upsertReport(Report report) {
    _reports.removeWhere((r) => r.id == report.id);
    _reports.add(report);
    _syncCounterFromReports();
  }

  void _syncCounterFromReports() {
    var maxNum = _counter;
    for (final r in _reports) {
      final digits = RegExp(r'\d+').firstMatch(r.displayId)?.group(0);
      if (digits != null) {
        final parsed = int.tryParse(digits);
        if (parsed != null && parsed > maxNum) {
          maxNum = parsed;
        }
      }
    }
    if (maxNum > _counter) {
      _counter = maxNum;
    }
  }

  // ---------------------------------------------------------------------------
  // Sinkronisasi dari Firebase
  // ---------------------------------------------------------------------------

  void _applyCloudSession(AppUser? user) {
    if (_currentUser?.uid == user?.uid) return;
    _currentUser = user;
    _save();
    notifyListeners();
  }

  void _applyCloudUsers(List<AppUser> users) {
    _users
      ..clear()
      ..addAll(users);
    if (_currentUser != null) {
      _currentUser = userById(_currentUser!.uid) ?? _currentUser;
    }
    _save();
    notifyListeners();
  }

  void _applyCloudReports(List<Report> reports) {
    _reports
      ..clear()
      ..addAll(reports);
    _save();
    notifyListeners();
  }

  /// Upload foto: REST API -> Firebase Storage -> null (fallback base64 lokal).
  Future<String?> uploadPhoto(String type, Uint8List bytes) async {
    final api = _api;
    if (api != null) {
      return api.uploadPhoto(type, bytes);
    }
    final cloud = _cloud;
    if (cloud == null) return null;
    return cloud.uploadPhoto(type, bytes);
  }

  // ---------------------------------------------------------------------------
  // Autentikasi
  // ---------------------------------------------------------------------------

  Future<AppUser> signIn(String email, String password) async {
    final api = _api;
    if (api != null) {
      final user = await api.signIn(email, password);
      _currentUser = user;
      _upsertUser(user);
      try {
        final remoteReports = await api.fetchReports();
        _reports
          ..clear()
          ..addAll(remoteReports);
        _syncCounterFromReports();
      } catch (error) {
        debugPrint('Gagal memuat laporan setelah login: $error');
      }
      await _save();
      notifyListeners();
      return user;
    }

    final cloud = _cloud;
    if (cloud != null) {
      final user = await cloud.signIn(email, password);
      _currentUser = user;
      await _save();
      notifyListeners();
      return user;
    }

    final normalized = email.trim().toLowerCase();
    AppUser? found;
    for (final u in _users) {
      if (u.email.toLowerCase() == normalized) found = u;
    }
    if (found == null) {
      throw Exception(
        'Email belum terdaftar. Daftar dulu atau pakai akun demo.',
      );
    }
    if (found.password.isNotEmpty && found.password != password) {
      throw Exception('Kata sandi salah. Periksa kembali.');
    }
    if (!found.isActive) {
      throw Exception('Akun ini sedang dinonaktifkan oleh admin.');
    }
    _currentUser = found;
    await _save();
    notifyListeners();
    return found;
  }

  Future<AppUser> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required Role role,
  }) async {
    final api = _api;
    if (api != null) {
      final user = await api.register(
        name: name,
        email: email,
        phone: phone,
        password: password,
        role: role,
      );
      _upsertUser(user);
      _currentUser = user;
      try {
        final remoteReports = await api.fetchReports();
        _reports
          ..clear()
          ..addAll(remoteReports);
        _syncCounterFromReports();
      } catch (_) {}
      await _save();
      notifyListeners();
      return user;
    }

    final cloud = _cloud;
    if (cloud != null) {
      final user = await cloud.register(
        name: name,
        email: email,
        phone: phone,
        password: password,
        role: role,
      );
      _users.removeWhere((u) => u.uid == user.uid);
      _users.add(user);
      _currentUser = user;
      await _save();
      notifyListeners();
      return user;
    }

    final normalized = email.trim().toLowerCase();
    if (_users.any((u) => u.email.toLowerCase() == normalized)) {
      throw Exception('Email sudah dipakai akun lain.');
    }
    final user = AppUser(
      uid: 'u${DateTime.now().microsecondsSinceEpoch}',
      name: name.trim(),
      email: normalized,
      phone: phone.trim(),
      role: role,
      createdAt: DateTime.now(),
      password: password,
    );
    _users.add(user);
    _currentUser = user;
    await _save();
    notifyListeners();
    return user;
  }

  Future<void> signOut() async {
    await _api?.signOut();
    await _cloud?.signOut();
    _currentUser = null;
    await _save();
    notifyListeners();
  }

  Future<void> updateProfile({String? name, String? phone}) async {
    final user = _currentUser;
    if (user == null) return;
    final index = _users.indexWhere((u) => u.uid == user.uid);
    if (index == -1) return;
    final updated = _users[index].copyWith(name: name, phone: phone);
    _users[index] = updated;
    _currentUser = updated;
    for (var i = 0; i < _reports.length; i++) {
      if (_reports[i].reporterId == updated.uid) {
        _reports[i] = Report(
          id: _reports[i].id,
          displayId: _reports[i].displayId,
          reporterId: _reports[i].reporterId,
          reporterName: updated.name,
          locationText: _reports[i].locationText,
          latitude: _reports[i].latitude,
          longitude: _reports[i].longitude,
          category: _reports[i].category,
          description: _reports[i].description,
          status: _reports[i].status,
          rejectionReason: _reports[i].rejectionReason,
          assignedOfficerId: _reports[i].assignedOfficerId,
          assignedOfficerName: _reports[i].assignedOfficerName,
          photoData: _reports[i].photoData,
          assignment: _reports[i].assignment,
          history: _reports[i].history,
          createdAt: _reports[i].createdAt,
          updatedAt: _reports[i].updatedAt,
        );
      }
    }
    await _save();
    final cloud = _cloud;
    if (cloud != null) {
      await _pushUser(updated);
      for (final report in _reports.where((r) => r.reporterId == updated.uid)) {
        await _pushReport(report);
      }
    }
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Laporan & alur status
  // ---------------------------------------------------------------------------

  Future<Report> createReport(CreateReportInput input) async {
    final api = _api;
    if (api != null) {
      final created = await api.createReport(input);
      _upsertReport(created);
      await _save();
      notifyListeners();
      return created;
    }

    final cloud = _cloud;
    if (cloud != null) {
      try {
        _counter = await cloud.nextDisplayNumber();
      } catch (error) {
        debugPrint('Counter Firestore gagal, memakai counter lokal: $error');
        _counter++;
      }
    } else {
      _counter++;
    }
    final report = Report(
      id: 'r${DateTime.now().microsecondsSinceEpoch}',
      displayId: '#${_counter.toString().padLeft(4, '0')}',
      reporterId: input.reporterId,
      reporterName: input.reporterName,
      locationText: input.location.address.trim(),
      latitude: input.location.latitude,
      longitude: input.location.longitude,
      category: input.category,
      description: input.description.trim(),
      status: ReportStatus.menunggu,
      photoData: input.photoData,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      history: [
        StatusHistoryEntry(
          id: 'h${DateTime.now().microsecondsSinceEpoch}',
          reportId: '',
          fromStatus: null,
          toStatus: ReportStatus.menunggu,
          changedBy: input.reporterId,
          changedByName: input.reporterName,
          note: 'Laporan dikirim warga',
          createdAt: DateTime.now(),
        ),
      ],
    );
    _reports.add(report);
    await _save();
    final cloudRef = _cloud;
    if (cloudRef != null) {
      try {
        await cloudRef.saveReport(report);
      } catch (error) {
        debugPrint('Gagal menyimpan laporan ke Firestore: $error');
        _reports.removeWhere((r) => r.id == report.id);
        await _save();
        rethrow;
      }
    }
    notifyListeners();
    return report;
  }

  Future<void> verifyReport(String reportId, String adminId) async {
    final api = _api;
    if (api != null) {
      final updated = await api.verifyReport(reportId);
      _upsertReport(updated);
      await _save();
      notifyListeners();
      return;
    }
    await _transition(
      reportId: reportId,
      to: ReportStatus.diverifikasi,
      actorId: adminId,
      note: 'Laporan diverifikasi dan menunggu penugasan',
      allowed: const {ReportStatus.menunggu},
    );
  }

  Future<void> rejectReport(
    String reportId,
    String adminId,
    String reason,
  ) async {
    final trimmed = reason.trim();
    if (trimmed.isEmpty) {
      throw Exception('Alasan penolakan wajib diisi.');
    }
    final api = _api;
    if (api != null) {
      final updated = await api.rejectReport(reportId, trimmed);
      _upsertReport(updated);
      await _save();
      notifyListeners();
      return;
    }
    await _transition(
      reportId: reportId,
      to: ReportStatus.ditolak,
      actorId: adminId,
      note: trimmed,
      rejectionReason: trimmed,
      allowed: const {ReportStatus.menunggu, ReportStatus.diverifikasi},
    );
  }

  Future<void> assignReport(
    String reportId,
    String officerId,
    String adminId,
  ) async {
    final api = _api;
    if (api != null) {
      final updated = await api.assignReport(reportId, officerId);
      _upsertReport(updated);
      await _save();
      notifyListeners();
      return;
    }
    final officer = userById(officerId);
    if (officer == null) throw Exception('Petugas tidak ditemukan.');
    await _transition(
      reportId: reportId,
      to: ReportStatus.ditugaskan,
      actorId: adminId,
      note: 'Ditugaskan kepada ${officer.name}',
      officer: officer,
      allowed: const {ReportStatus.diverifikasi},
    );
  }

  Future<void> startAssignment(String reportId, String officerId) async {
    final api = _api;
    if (api != null) {
      final updated = await api.startAssignment(reportId);
      _upsertReport(updated);
      await _save();
      notifyListeners();
      return;
    }
    await _transition(
      reportId: reportId,
      to: ReportStatus.dikerjakan,
      actorId: officerId,
      note: 'Petugas mulai mengerjakan di lokasi',
      allowed: const {ReportStatus.ditugaskan},
    );
  }

  Future<void> completeAssignment(
    String reportId,
    String officerId,
    String note, {
    String? proofPath,
  }) async {
    final api = _api;
    if (api != null) {
      final updated = await api.completeAssignment(
        reportId,
        note,
        proofPath: proofPath,
      );
      _upsertReport(updated);
      await _save();
      notifyListeners();
      return;
    }
    await _transition(
      reportId: reportId,
      to: ReportStatus.selesai,
      actorId: officerId,
      note: note.trim().isEmpty
          ? 'Sampah sudah dibersihkan petugas'
          : note.trim(),
      proofPath: proofPath,
      allowed: const {ReportStatus.dikerjakan},
    );
  }

  Future<void> _transition({
    required String reportId,
    required ReportStatus to,
    required String actorId,
    required String note,
    required Set<ReportStatus> allowed,
    String? rejectionReason,
    AppUser? officer,
    String? proofPath,
  }) async {
    final index = _reports.indexWhere((r) => r.id == reportId);
    if (index == -1) throw Exception('Laporan tidak ditemukan.');
    final report = _reports[index];
    if (!allowed.contains(report.status)) {
      throw Exception(
        'Status "${report.status.label}" tidak bisa diubah ke "${to.label}".',
      );
    }
    final actor = userById(actorId);
    final entry = StatusHistoryEntry(
      id: 'h${DateTime.now().microsecondsSinceEpoch}',
      reportId: reportId,
      fromStatus: report.status,
      toStatus: to,
      changedBy: actorId,
      changedByName: actor?.name ?? 'Sistem',
      note: note,
      createdAt: DateTime.now(),
    );

    Assignment? assignment = report.assignment;
    if (to == ReportStatus.ditugaskan && officer != null) {
      assignment = Assignment(
        id: 'a${DateTime.now().microsecondsSinceEpoch}',
        reportId: reportId,
        officerId: officer.uid,
        assignedBy: actorId,
        status: ReportStatus.ditugaskan,
        assignedAt: DateTime.now(),
      );
    } else if (assignment != null) {
      assignment = assignment.copyWith(
        status: to,
        startedAt: to == ReportStatus.dikerjakan ? DateTime.now() : null,
        completedAt: to == ReportStatus.selesai ? DateTime.now() : null,
        workNote: to == ReportStatus.selesai ? note : null,
        proofPhotoPath: proofPath,
      );
    }

    _reports[index] = report.copyWith(
      status: to,
      rejectionReason: rejectionReason,
      assignedOfficerId: officer?.uid,
      assignedOfficerName: officer?.name,
      assignment: assignment,
      history: [...report.history, entry],
      updatedAt: DateTime.now(),
    );
    await _save();
    await _pushReport(_reports[index]);
    notifyListeners();
  }

  List<Report> reportsFor(AppUser user) {
    switch (user.role) {
      case Role.warga:
        return reports.where((r) => r.reporterId == user.uid).toList();
      case Role.petugas:
        return reports.where((r) => r.assignedOfficerId == user.uid).toList();
      case Role.admin:
        return reports;
    }
  }

  // ---------------------------------------------------------------------------
  // Streams (kontrak service)
  // ---------------------------------------------------------------------------

  Stream<List<Report>> _watch(List<Report> Function() selector) async* {
    yield selector();
    await for (final _ in _changes.stream) {
      yield selector();
    }
  }

  Stream<List<Report>> watchMyReports(String userId) =>
      _watch(() => reports.where((r) => r.reporterId == userId).toList());

  Stream<List<Report>> watchPendingReports() => _watch(
    () => reports.where((r) => r.status == ReportStatus.menunggu).toList(),
  );

  Stream<List<Report>> watchAllReports() => _watch(() => reports);

  Stream<List<Report>> watchOfficerReports(String officerId) => _watch(
    () => reports.where((r) => r.assignedOfficerId == officerId).toList(),
  );

  void _notifyChange() => _changes.add(null);

  @override
  void notifyListeners() {
    super.notifyListeners();
    _notifyChange();
  }

  // ---------------------------------------------------------------------------
  // Penyimpanan
  // ---------------------------------------------------------------------------

  Future<void> _pushUser(AppUser user) async {
    final cloud = _cloud;
    if (cloud == null) return;
    try {
      await cloud.saveUser(user);
    } catch (error) {
      debugPrint('Gagal menyimpan user ke Firestore: $error');
    }
  }

  Future<void> _pushReport(Report report) async {
    final cloud = _cloud;
    if (cloud == null) return;
    try {
      await cloud.saveReport(report);
    } catch (error) {
      debugPrint('Gagal menyimpan laporan ke Firestore: $error');
    }
  }

  Future<void> _save() async {
    final prefs = _prefs;
    if (prefs == null) return;
    final useRemoteAuth = _api != null || _cloud != null;
    final data = {
      'users': _users
          .map((u) => useRemoteAuth ? u.toPublicJson() : u.toJson())
          .toList(),
      'reports': _reports.map((r) => r.toJson()).toList(),
      'counter': _counter,
      'session': _currentUser?.uid,
    };
    await prefs.setString(_storageKey, jsonEncode(data));
  }

  Future<void> resetDemoData() async {
    if (_api != null || _cloud != null) {
      throw Exception(
        'Data demo tidak bisa direset saat aplikasi memakai backend server.',
      );
    }
    _users.clear();
    _reports.clear();
    _counter = 0;
    _currentUser = null;
    _seed();
    await _save();
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Data demo
  // ---------------------------------------------------------------------------

  void _ensureDemoAccounts() {
    final demo = _demoUsers();
    for (final u in demo) {
      if (!_users.any((x) => x.email == u.email)) _users.add(u);
    }
  }

  List<AppUser> _demoUsers() {
    final now = DateTime.now();
    return [
      AppUser(
        uid: 'u-warga',
        name: 'Ayu Lestari',
        email: 'warga@sipahal.com',
        phone: '0812-7000-1122',
        role: Role.warga,
        createdAt: now.subtract(const Duration(days: 40)),
        password: 'warga123',
      ),
      AppUser(
        uid: 'u-warga-2',
        name: 'Budi Santoso',
        email: 'budi@sipahal.com',
        phone: '0812-7000-3344',
        role: Role.warga,
        createdAt: now.subtract(const Duration(days: 32)),
        password: 'warga123',
      ),
      AppUser(
        uid: 'u-petugas',
        name: 'Andri Saputra',
        email: 'petugas@sipahal.com',
        phone: '0813-5500-7788',
        role: Role.petugas,
        createdAt: now.subtract(const Duration(days: 60)),
        password: 'petugas123',
      ),
      AppUser(
        uid: 'u-petugas-2',
        name: 'Rina Marlina',
        email: 'rina@sipahal.com',
        phone: '0813-5500-9900',
        role: Role.petugas,
        createdAt: now.subtract(const Duration(days: 58)),
        password: 'petugas123',
      ),
      AppUser(
        uid: 'u-admin',
        name: 'Dewi Anggraini',
        email: 'admin@sipahal.com',
        phone: '0811-9000-5566',
        role: Role.admin,
        createdAt: now.subtract(const Duration(days: 90)),
        password: 'admin123',
      ),
    ];
  }

  void _seed() {
    final now = DateTime.now();
    _users.addAll(_demoUsers());
    _counter = 6;

    Report build({
      required String id,
      required int number,
      required String reporterId,
      required String reporterName,
      required String locationText,
      required double lat,
      required double lon,
      required String category,
      required String description,
      required ReportStatus status,
      required Duration age,
      String? officerId,
      String? officerName,
      String? rejectionReason,
      String? photoData,
      Assignment? assignment,
      required List<StatusHistoryEntry> history,
    }) => Report(
      id: id,
      displayId: '#${number.toString().padLeft(4, '0')}',
      reporterId: reporterId,
      reporterName: reporterName,
      locationText: locationText,
      latitude: lat,
      longitude: lon,
      category: category,
      description: description,
      status: status,
      rejectionReason: rejectionReason,
      assignedOfficerId: officerId,
      assignedOfficerName: officerName,
      photoData: photoData,
      assignment: assignment,
      createdAt: now.subtract(age),
      updatedAt: history.isEmpty ? now.subtract(age) : history.last.createdAt,
      history: history,
    );

    StatusHistoryEntry h(
      String reportId,
      ReportStatus? from,
      ReportStatus to,
      String actorId,
      String actorName,
      String note,
      Duration age,
    ) => StatusHistoryEntry(
      id: 'h-$reportId-${to.id}',
      reportId: reportId,
      fromStatus: from,
      toStatus: to,
      changedBy: actorId,
      changedByName: actorName,
      note: note,
      createdAt: now.subtract(age),
    );

    _reports.addAll([
      build(
        id: 'r-1',
        number: 1,
        reporterId: 'u-warga',
        reporterName: 'Ayu Lestari',
        locationText: 'Jalan Merdeka, dekat Tugu Sirih',
        lat: 0.9189,
        lon: 104.4468,
        category: 'Sampah rumah tangga',
        description:
            'Sampah menumpuk di pinggir jalan sejak tiga hari lalu dan mulai berbau.',
        status: ReportStatus.menunggu,
        age: const Duration(hours: 4),
        history: [
          h(
            'r-1',
            null,
            ReportStatus.menunggu,
            'u-warga',
            'Ayu Lestari',
            'Laporan dikirim warga',
            const Duration(hours: 4),
          ),
        ],
      ),
      build(
        id: 'r-2',
        number: 2,
        reporterId: 'u-warga-2',
        reporterName: 'Budi Santoso',
        locationText: 'Pasar Bintan Center, Jalan Wiratno',
        lat: 0.9245,
        lon: 104.4402,
        category: 'Sampah plastik',
        description:
            'Tumpukan kantong plastik dan botol di belakang area pasar.',
        status: ReportStatus.diverifikasi,
        age: const Duration(hours: 9),
        history: [
          h(
            'r-2',
            null,
            ReportStatus.menunggu,
            'u-warga-2',
            'Budi Santoso',
            'Laporan dikirim warga',
            const Duration(hours: 9),
          ),
          h(
            'r-2',
            ReportStatus.menunggu,
            ReportStatus.diverifikasi,
            'u-admin',
            'Dewi Anggraini',
            'Laporan valid, siap ditugaskan',
            const Duration(hours: 8),
          ),
        ],
      ),
      build(
        id: 'r-3',
        number: 3,
        reporterId: 'u-warga',
        reporterName: 'Ayu Lestari',
        locationText: 'Kampung Bulang, Jalan Ahmad Yani',
        lat: 0.9133,
        lon: 104.4512,
        category: 'Sampah konstruksi',
        description: 'Puing bangunan dibuang di lahan kosong pinggir jalan.',
        status: ReportStatus.ditugaskan,
        age: const Duration(days: 1, hours: 3),
        officerId: 'u-petugas',
        officerName: 'Andri Saputra',
        assignment: Assignment(
          id: 'a-3',
          reportId: 'r-3',
          officerId: 'u-petugas',
          assignedBy: 'u-admin',
          status: ReportStatus.ditugaskan,
          assignedAt: now.subtract(const Duration(hours: 20)),
        ),
        history: [
          h(
            'r-3',
            null,
            ReportStatus.menunggu,
            'u-warga',
            'Ayu Lestari',
            'Laporan dikirim warga',
            const Duration(days: 1, hours: 3),
          ),
          h(
            'r-3',
            ReportStatus.menunggu,
            ReportStatus.diverifikasi,
            'u-admin',
            'Dewi Anggraini',
            'Laporan valid, siap ditugaskan',
            const Duration(days: 1),
          ),
          h(
            'r-3',
            ReportStatus.diverifikasi,
            ReportStatus.ditugaskan,
            'u-admin',
            'Dewi Anggraini',
            'Ditugaskan kepada Andri Saputra',
            const Duration(hours: 20),
          ),
        ],
      ),
      build(
        id: 'r-4',
        number: 4,
        reporterId: 'u-warga-2',
        reporterName: 'Budi Santoso',
        locationText: 'Tanjung Unggat, Jalan Sultan Hasanuddin',
        lat: 0.9041,
        lon: 104.4583,
        category: 'Sampah organik',
        description:
            'Sisa sayur dan buah dibuang di saluran air pinggir jalan.',
        status: ReportStatus.dikerjakan,
        age: const Duration(days: 2),
        officerId: 'u-petugas',
        officerName: 'Andri Saputra',
        assignment: Assignment(
          id: 'a-4',
          reportId: 'r-4',
          officerId: 'u-petugas',
          assignedBy: 'u-admin',
          status: ReportStatus.dikerjakan,
          assignedAt: now.subtract(const Duration(days: 1, hours: 12)),
          startedAt: now.subtract(const Duration(hours: 5)),
        ),
        history: [
          h(
            'r-4',
            null,
            ReportStatus.menunggu,
            'u-warga-2',
            'Budi Santoso',
            'Laporan dikirim warga',
            const Duration(days: 2),
          ),
          h(
            'r-4',
            ReportStatus.menunggu,
            ReportStatus.diverifikasi,
            'u-admin',
            'Dewi Anggraini',
            'Laporan valid, siap ditugaskan',
            const Duration(days: 1, hours: 20),
          ),
          h(
            'r-4',
            ReportStatus.diverifikasi,
            ReportStatus.ditugaskan,
            'u-admin',
            'Dewi Anggraini',
            'Ditugaskan kepada Andri Saputra',
            const Duration(days: 1, hours: 12),
          ),
          h(
            'r-4',
            ReportStatus.ditugaskan,
            ReportStatus.dikerjakan,
            'u-petugas',
            'Andri Saputra',
            'Petugas mulai mengerjakan di lokasi',
            const Duration(hours: 5),
          ),
        ],
      ),
      build(
        id: 'r-5',
        number: 5,
        reporterId: 'u-warga',
        reporterName: 'Ayu Lestari',
        locationText: 'Pelantar KUD, kawasan Tepi Laut',
        lat: 0.9210,
        lon: 104.4442,
        category: 'Sampah plastik',
        description: 'Sampah plastik berserakan di atas pelantar kayu.',
        status: ReportStatus.selesai,
        age: const Duration(days: 5),
        officerId: 'u-petugas-2',
        officerName: 'Rina Marlina',
        assignment: Assignment(
          id: 'a-5',
          reportId: 'r-5',
          officerId: 'u-petugas-2',
          assignedBy: 'u-admin',
          status: ReportStatus.selesai,
          assignedAt: now.subtract(const Duration(days: 4, hours: 20)),
          startedAt: now.subtract(const Duration(days: 4, hours: 2)),
          completedAt: now.subtract(const Duration(days: 4)),
          workNote:
              'Sampah sudah diangkut ke TPS dan area pelantar dibersihkan.',
        ),
        history: [
          h(
            'r-5',
            null,
            ReportStatus.menunggu,
            'u-warga',
            'Ayu Lestari',
            'Laporan dikirim warga',
            const Duration(days: 5),
          ),
          h(
            'r-5',
            ReportStatus.menunggu,
            ReportStatus.diverifikasi,
            'u-admin',
            'Dewi Anggraini',
            'Laporan valid, siap ditugaskan',
            const Duration(days: 4, hours: 22),
          ),
          h(
            'r-5',
            ReportStatus.diverifikasi,
            ReportStatus.ditugaskan,
            'u-admin',
            'Dewi Anggraini',
            'Ditugaskan kepada Rina Marlina',
            const Duration(days: 4, hours: 20),
          ),
          h(
            'r-5',
            ReportStatus.ditugaskan,
            ReportStatus.dikerjakan,
            'u-petugas-2',
            'Rina Marlina',
            'Petugas mulai mengerjakan di lokasi',
            const Duration(days: 4, hours: 2),
          ),
          h(
            'r-5',
            ReportStatus.dikerjakan,
            ReportStatus.selesai,
            'u-petugas-2',
            'Rina Marlina',
            'Sampah sudah diangkut ke TPS dan area pelantar dibersihkan.',
            const Duration(days: 4),
          ),
        ],
      ),
      build(
        id: 'r-6',
        number: 6,
        reporterId: 'u-warga-2',
        reporterName: 'Budi Santoso',
        locationText: 'Jalan Diponegoro, depan ruko',
        lat: 0.9161,
        lon: 104.4489,
        category: 'Sampah lainnya',
        description: 'Ada karung sampah di depan ruko.',
        status: ReportStatus.ditolak,
        age: const Duration(days: 3),
        rejectionReason:
            'Lokasi sudah masuk jadwal pengangkutan rutin DLH, bukan titik sampah liar.',
        history: [
          h(
            'r-6',
            null,
            ReportStatus.menunggu,
            'u-warga-2',
            'Budi Santoso',
            'Laporan dikirim warga',
            const Duration(days: 3),
          ),
          h(
            'r-6',
            ReportStatus.menunggu,
            ReportStatus.ditolak,
            'u-admin',
            'Dewi Anggraini',
            'Lokasi sudah masuk jadwal pengangkutan rutin DLH, bukan titik sampah liar.',
            const Duration(days: 2, hours: 20),
          ),
        ],
      ),
    ]);
  }
}