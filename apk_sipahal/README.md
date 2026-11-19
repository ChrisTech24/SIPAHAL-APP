# SIPAHAL — Flutter App

Aplikasi pelaporan & pemetaan titik pembuangan sampah liar.

## Menjalankan

```bash
flutter pub get
flutter run -d emulator-5554   # Android emulator
# atau: flutter run            # pilih device saat diminta
```

Panduan lengkap (emulator, HP asli, APK, akun demo, alur presentasi):
**[../docs/PANDUAN_MENJALANKAN.md](../docs/PANDUAN_MENJALANKAN.md)**

Bukti rubrik Phase 3 (data, backend, persistence, auth, evidence):
**[../docs/RUBRIK_PHASE3.md](../docs/RUBRIK_PHASE3.md)**

## Struktur

```text
lib/
├── core/        tema & util format tanggal
├── models/      User, Report, Assignment, StatusHistory, LocationData
├── data/        AppStore (cache + data demo) + FirebaseBackend (Auth/Firestore/Storage)
├── services/    AuthService, ReportService, LocationService
├── pages/       opening, warga, petugas, admin, detail laporan, shared
├── widgets/     komponen UI & peta (flutter_map)
└── main.dart
test/            unit test alur status laporan
```

## Catatan

- Peta: OpenStreetMap (tanpa API key).
- Backend: **Firebase** (Auth + Firestore + Storage) di `lib/data/firebase_backend.dart`,
  dengan cache lokal `AppStore` sesuai `docs/PRD_BACKEND_SIPAHAL.md`.
  Firebase aktif otomatis bila `android/app/google-services.json` dipasang; tanpa file itu
  aplikasi tetap jalan memakai data lokal. Panduan: `../docs/FIREBASE_SETUP.md`.
- Security Rules: `../firebase/firestore.rules`, `../firebase/storage.rules`.
- Akun demo: `warga@sipahal.com` / `petugas@sipahal.com` / `rina@sipahal.com` /
  `admin@sipahal.com` (lihat `docs/PANDUAN_MENJALANKAN.md`).
