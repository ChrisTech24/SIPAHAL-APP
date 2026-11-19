import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import '../models/models.dart';

/// Jembatan ke Firebase (Authentication, Cloud Firestore, Storage).
///
/// Backend ini bersifat opsional: aktif hanya bila
/// `android/app/google-services.json` sudah dipasang dan
/// `Firebase.initializeApp()` berhasil. Kalau belum, aplikasi otomatis
/// memakai penyimpanan lokal (`AppStore`) supaya demo tetap bisa dijalankan.
class FirebaseBackend {
  FirebaseBackend._();

  static const usersCollection = 'users';
  static const reportsCollection = 'reports';
  static const countersCollection = 'counters';

  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFirestore get _db => FirebaseFirestore.instance;
  FirebaseStorage get _storage => FirebaseStorage.instance;

  StreamSubscription<User?>? _sessionSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _reportsSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _usersSub;

  bool _attached = false;
  bool _registering = false;

  // Callback ke AppStore, supaya lapisan data tidak saling mengimpor.
  void Function(AppUser? user)? onSession;
  void Function(List<AppUser> users)? onUsers;
  void Function(List<Report> reports)? onReports;
  void Function(Object error)? onError;

  /// Mengembalikan `null` bila Firebase belum dikonfigurasi / gagal init.
  static Future<FirebaseBackend?> connect() async {
    if (kIsWeb) return null;
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
      return FirebaseBackend._();
    } catch (error) {
      debugPrint('Firebase nonaktif, memakai data lokal: $error');
      return null;
    }
  }

  /// Mulai memantau sesi, daftar user, dan daftar laporan dari Firestore.
  Future<void> attach({
    required void Function(AppUser? user) onSession,
    required void Function(List<AppUser> users) onUsers,
    required void Function(List<Report> reports) onReports,
    required void Function(Object error) onError,
  }) async {
    if (_attached) return;
    this.onSession = onSession;
    this.onUsers = onUsers;
    this.onReports = onReports;
    this.onError = onError;
    _attached = true;

    await _restoreSession();
    _listenUsers();
    _listenReports();

    _sessionSub ??= _auth.authStateChanges().listen((user) async {
      if (_registering) return;
      if (user == null) {
        onSession(null);
        return;
      }
      await _loadProfile(user.uid);
    });
  }

  Future<void> _restoreSession() async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      await _loadProfile(user.uid);
    } catch (error) {
      // Offline / rules menolak: biarkan cache lokal yang dipakai.
      debugPrint('Gagal memulihkan sesi Firebase: $error');
    }
  }

  Future<void> _loadProfile(String uid) async {
    final doc = await _db
        .collection(usersCollection)
        .doc(uid)
        .get()
        .timeout(const Duration(seconds: 6));
    final data = doc.data();
    if (data == null) {
      onSession?.call(null);
      return;
    }
    final profile = AppUser.fromJson({...data, 'uid': uid});
    if (!profile.isActive) {
      await _auth.signOut();
      onSession?.call(null);
      return;
    }
    onSession?.call(profile);
  }

  void _listenUsers() {
    _usersSub ??= _db.collection(usersCollection).snapshots().listen((
      snapshot,
    ) {
      final users = <AppUser>[];
      for (final doc in snapshot.docs) {
        try {
          users.add(AppUser.fromJson({...doc.data(), 'uid': doc.id}));
        } catch (error) {
          debugPrint('User ${doc.id} dilewati: $error');
        }
      }
      onUsers?.call(users);
    }, onError: _reportError);
  }

  void _listenReports() {
    _reportsSub ??= _db.collection(reportsCollection).snapshots().listen((
      snapshot,
    ) {
      final reports = <Report>[];
      for (final doc in snapshot.docs) {
        try {
          reports.add(Report.fromJson({...doc.data(), 'id': doc.id}));
        } catch (error) {
          debugPrint('Laporan ${doc.id} dilewati: $error');
        }
      }
      onReports?.call(reports);
    }, onError: _reportError);
  }

  void _reportError(Object error) {
    debugPrint('Firestore stream error: $error');
    onError?.call(error);
  }

  // ---------------------------------------------------------------------------
  // Autentikasi
  // ---------------------------------------------------------------------------

  Future<AppUser> signIn(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final uid = credential.user!.uid;
      final doc = await _db.collection(usersCollection).doc(uid).get();
      final data = doc.data();
      if (data == null) {
        await _auth.signOut();
        throw Exception(
          'Akun ini belum punya profil SIPAHAL. Minta admin DLH membuatkan profil.',
        );
      }
      final profile = AppUser.fromJson({...data, 'uid': uid});
      if (!profile.isActive) {
        await _auth.signOut();
        throw Exception('Akun ini sedang dinonaktifkan oleh admin.');
      }
      return profile;
    } on FirebaseAuthException catch (error) {
      throw Exception(_authMessage(error));
    }
  }

  Future<AppUser> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required Role role,
  }) async {
    _registering = true;
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = AppUser(
        uid: credential.user!.uid,
        name: name.trim(),
        email: email.trim().toLowerCase(),
        phone: phone.trim(),
        role: role,
        createdAt: DateTime.now(),
      );
      await _db
          .collection(usersCollection)
          .doc(user.uid)
          .set(user.toPublicJson());
      await credential.user!.updateDisplayName(user.name);
      return user;
    } on FirebaseAuthException catch (error) {
      throw Exception(_authMessage(error));
    } finally {
      _registering = false;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  // ---------------------------------------------------------------------------
  // Data
  // ---------------------------------------------------------------------------

  Future<void> saveUser(AppUser user) => _db
      .collection(usersCollection)
      .doc(user.uid)
      .set(user.toPublicJson(), SetOptions(merge: true));

  Future<void> saveReport(Report report) => _db
      .collection(reportsCollection)
      .doc(report.id)
      .set(report.toJson(), SetOptions(merge: false));

  /// Nomor tampilan (`#0001`) dibuat atomik lewat dokumen counter.
  Future<int> nextDisplayNumber() async {
    final ref = _db.collection(countersCollection).doc('reports');
    return _db.runTransaction<int>((transaction) async {
      final snapshot = await transaction.get(ref);
      final current = (snapshot.data()?['value'] as num?)?.toInt() ?? 0;
      final next = current + 1;
      transaction.set(ref, {'value': next}, SetOptions(merge: true));
      return next;
    });
  }

  Future<String> uploadPhoto(String type, Uint8List bytes) async {
    final path =
        'report_photos/$type-${DateTime.now().microsecondsSinceEpoch}.jpg';
    final ref = _storage.ref(path);
    await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
    return ref.getDownloadURL();
  }

  String _authMessage(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-email':
        return 'Format email tidak valid.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email atau kata sandi salah.';
      case 'email-already-in-use':
        return 'Email sudah dipakai akun lain.';
      case 'weak-password':
        return 'Kata sandi minimal 6 karakter.';
      case 'too-many-requests':
        return 'Terlalu banyak percobaan. Coba lagi beberapa saat.';
      case 'network-request-failed':
        return 'Tidak ada koneksi internet. Periksa jaringan lalu coba lagi.';
      case 'operation-not-allowed':
        return 'Login email/kata sandi belum diaktifkan di Firebase Console.';
      default:
        return error.message ?? 'Gagal memproses akun.';
    }
  }

  Future<void> dispose() async {
    await _sessionSub?.cancel();
    await _reportsSub?.cancel();
    await _usersSub?.cancel();
  }
}
