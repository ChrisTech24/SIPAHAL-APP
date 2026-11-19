# Bukti Rubrik Phase 3 — Data, Backend & Platform Integration

**Mata kuliah:** Pemrograman Perangkat Bergerak
**Proyek:** SIPAHAL — Sistem Informasi Pelaporan & Pemetaan Titik Pembuangan Sampah Liar
**Fase:** 3 (Data, Backend & Platform Integration) · **Bobot:** 20%
**Kode aplikasi:** `apk_sipahal/` · **Tangkapan layar:** `screenshots/`

Dokumen ini memetakan setiap indikator rubrik ke **bukti nyata di dalam project**: file kode,
perilaku yang bisa dijalankan ulang, dan tangkapan layar hasil uji di emulator Android 14.
Semua klaim di bawah bisa diverifikasi sendiri dengan langkah pada bagian
[8. Cara mereproduksi bukti](#8-cara-mereproduksi-bukti).

---

## 1. Ringkasan penilaian

| Indikator | Bobot | Target | Status | Bukti utama |
|---|---|---|---|---|
| REST API / Firebase / BaaS integration | 30% | Level 4 | Kode integrasi Firebase siap; aktif otomatis saat `google-services.json` dipasang, fallback lokal tanpa crash | `lib/data/firebase_backend.dart`, `lib/data/app_store.dart`, `firebase/*.rules`, `docs/FIREBASE_SETUP.md` |
| Async / state / loading / error handling | 25% | Level 4 | Terpenuhi | `lib/widgets/common.dart` (`PrimaryButton.loading`, `EmptyState`, `showSnack`), validasi form di semua halaman |
| Local persistence / cache + mobile capability | 20% | Level 4 | Terpenuhi | `SharedPreferences` (`sipahal_state_v3`), GPS `geolocator`, kamera/galeri `image_picker`, `geo:` navigation, responsif tablet |
| Auth & security basics | 15% | Level 3–4 | Terpenuhi; Firebase Auth + Security Rules aktif di mode cloud | `AuthService`, `FirebaseBackend`, `firestore.rules`, pemisahan peran di `home_router.dart` |
| Integration evidence & verification | 10% | Level 4 | Terpenuhi | `test/app_store_test.dart` (2 test lulus), `flutter analyze` bersih, 22 screenshot alur end-to-end |

**Catatan transparansi:** rubrik menyebut *REST API / Firebase / BaaS*. Project ini memakai
**Firebase asli** (`firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_storage`)
lewat `FirebaseBackend` — bukan sekadar kontrak. Supaya aplikasi tetap bisa dibuka penilai
tanpa kredensial cloud, koneksi Firebase bersifat **opsional dan otomatis**: bila
`android/app/google-services.json` belum dipasang, aplikasi memakai `AppStore` +
`SharedPreferences` (mode lokal) tanpa crash. Status mode aktif terlihat di
**Profil → Penyimpanan data** (`Firebase (cloud)` / `Lokal (demo)`).
Karena kredensial Firebase belum tersedia di mesin pengembangan, **mode cloud belum diuji
langsung**; yang sudah diverifikasi adalah build, fallback, dan alur demo. Langkah
mengaktifkan dan memverifikasi cloud ada di [`docs/FIREBASE_SETUP.md`](FIREBASE_SETUP.md).

---

## 2. Indikator 1 — Integrasi data / backend (30%)

### 2.1 Arsitektur berlapis

```text
UI (lib/pages/*, lib/widgets/*)
        │  hanya memanggil service / store, tidak ada query data langsung
        ▼
Service layer (lib/services/services.dart)
   AuthService · ReportService · LocationService
        │
        ▼
Data layer (lib/data/app_store.dart)  ← satu sumber kebenaran (single source of truth)
        │            │
        │            └──► FirebaseBackend (lib/data/firebase_backend.dart)
        │                   Auth · Firestore listener/write · Storage · counter atomik
        ▼
Model (lib/models/models.dart) + SharedPreferences (cache lokal)
```

- **Satu pintu perubahan data.** Semua aksi (buat laporan, verifikasi, tolak, tugaskan,
  mulai, selesai) melewati `ReportService` → `AppStore`. Tidak ada penulisan data langsung
  dari widget, sesuai PRD frontend: *"Jangan menulis query Firebase langsung di setiap widget"*.
- **Write-through ke cloud.** Saat Firebase aktif, `AppStore` menulis perubahan ke Firestore
  (`saveReport`, `saveUser`) **dan** menyimpannya ke cache lokal; snapshot listener Firestore
  (`users`, `reports`) menyegarkan daftar di semua perangkat secara real-time.
- **Kontrak service sama dengan PRD backend** (`docs/PRD_BACKEND_SIPAHAL.md`, bagian
  *Public service contract*):

| Kontrak PRD | Implementasi |
|---|---|
| `signIn`, `signOut` | `AuthService.signIn` / `AuthService.signOut` |
| `createReport(CreateReportInput)` | `ReportService.createReport` → `AppStore.createReport` |
| `watchMyReports`, `watchPendingReports` | `ReportService.watchMyReports` / `watchPendingReports` |
| `verifyReport`, `rejectReport`, `assignReport` | method dengan nama & parameter sama |
| `startAssignment`, `completeAssignment` | method dengan nama & parameter sama |
| `uploadReportPhoto` | `ReportService.uploadReportPhoto` → Firebase Storage (URL) atau base64 saat mode lokal |

- **Collection & field mengikuti PRD**: `users` (`uid, name, email, phone, role, isActive,
  createdAt`), `reports` (`id, displayId, reporterId, locationText, latitude, longitude,
  category, description, status, rejectionReason, assignedOfficerId, createdAt, updatedAt`),
  `counters` (nomor tampilan), serta `assignment` & `history` bersarang di dokumen laporan
  (sesuai `lib/models/models.dart`). Pemetaan lengkap ada di `docs/FIREBASE_SETUP.md` bagian 6.
- **Hanya 6 status** yang sah: `menunggu`, `diverifikasi`, `ditugaskan`, `dikerjakan`,
  `selesai`, `ditolak` (`enum ReportStatus`).
- **Model mapping**: `AppUser.fromJson/toJson`, `Report.fromJson/toJson`,
  `Assignment`, `StatusHistoryEntry`, `LocationData` — dipakai saat simpan/muat cache.

### 2.2 Alur data & aturan transisi status

`AppStore._transition` menjadi satu-satunya tempat perubahan status. Setiap transisi
menyatakan status asal yang diizinkan (`allowed`), sehingga data tidak bisa "melompat":

| Aksi | Dari | Ke |
|---|---|---|
| Warga kirim laporan | — | `menunggu` |
| Admin verifikasi | `menunggu` | `diverifikasi` |
| Admin tolak (+ alasan wajib) | `menunggu`, `diverifikasi` | `ditolak` |
| Admin tugaskan | `diverifikasi` | `ditugaskan` |
| Petugas mulai | `ditugaskan` | `dikerjakan` |
| Petugas selesai (+ catatan) | `dikerjakan` | `selesai` |

Setiap perubahan juga:
- menulis **satu entri `StatusHistoryEntry`** (dari → ke, aktor, catatan, waktu) →
  tampil sebagai timeline di halaman detail (screenshot `06-detail.png`);
- memperbarui `Assignment` (`startedAt`, `completedAt`, `workNote`, `proofPhotoPath`);
- memperbarui `updatedAt` dan menyimpan ke cache.

### 2.3 Bukti runtime
`screenshots/04-warga-map.png` (data laporan masuk ke peta + counter),
`screenshots/08-verifikasi.png` (admin memverifikasi),
`screenshots/09-penugasan.png` + `10-pilih-petugas.png` (penugasan),
`screenshots/21-laporan-terkirim.png` (laporan baru warga langsung terlihat admin),
`screenshots/06-detail.png` (timeline hasil transisi status).

### 2.4 Integrasi Firebase (Auth + Firestore + Storage)

`lib/data/firebase_backend.dart` menghubungkan aplikasi ke Firebase:

| Kemampuan | Implementasi |
|---|---|
| Inisialisasi | `FirebaseBackend.connect()` → `Firebase.initializeApp()`; gagal = mode lokal (dicatat di log, tanpa crash) |
| Login/daftar | `signInWithEmailAndPassword` / `createUserWithEmailAndPassword`, profil dibaca dari `users/{uid}`, akun nonaktif langsung ditolak |
| Sesi | `authStateChanges()` + `currentUser` dipulihkan saat aplikasi dibuka |
| Baca data | Snapshot listener `users` dan `reports` → `AppStore` diperbarui real-time |
| Tulis data | `saveReport()` / `saveUser()` write-through setiap transisi status & update profil |
| Nomor laporan | Transaksi Firestore `counters/reports` → `#0001` unik walau pengiriman bersamaan |
| Foto | `Firebase Storage` `report_photos/`, URL https disimpan di `photoData`, dirender `Image.network` |
| Keamanan | `users/{uid}` tanpa password; rules di `firebase/firestore.rules` & `firebase/storage.rules` |

Bukti fallback (tanpa kredensial) juga tervalidasi: build APK berhasil, aplikasi menampilkan
`Profil → Penyimpanan data: Lokal (demo)` (`screenshots/23-status-penyimpanan.png`), dan log
menunjukkan `Firebase nonaktif, memakai data lokal` tanpa crash.
Panduan mengaktifkan cloud: [`docs/FIREBASE_SETUP.md`](FIREBASE_SETUP.md).

---

## 3. Indikator 2 — Async, state, loading, error (25%)

### 3.1 Loading
- `PrimaryButton(loading: ...)` menampilkan indikator + menonaktifkan tombol selama proses
  (`lib/widgets/common.dart`), dipakai di login, daftar akun, form buat laporan, sheet
  selesaikan tugas.
- GPS: tombol **Ambil GPS** berubah status selama `LocationService.getCurrentLocation()`
  berjalan (timeout 25 detik) — `lib/pages/warga.dart`.
- Peta: `flutter_map` menampilkan tile bertahap; `AsyncValue` (spinner) tersedia untuk
  data async di `lib/widgets/common.dart`.

### 3.2 Error
- Kegagalan service ditangkap `try/catch` lalu ditampilkan tanpa crash:
  - form login/daftar → kotak error merah di dalam kartu (`_error`), termasuk pesan
    "Kata sandi salah", "Email sudah dipakai akun lain", dan pesan salah peran;
  - aksi admin/petugas → `showSnack(..., error: true)`;
  - GPS → `LocationFailure` dengan pesan spesifik: GPS mati, izin ditolak, izin diblokir
    permanen (dengan tombol buka pengaturan), plus fallback "Pilih di peta".
- Guard bisnis juga melempar pesan yang bisa dibaca pengguna, contoh:
  `Status "Menunggu" tidak bisa diubah ke "Selesai".`, `Alasan penolakan wajib diisi.`,
  `Catatan pekerjaan minimal 5 karakter.`

### 3.3 Empty state
`EmptyState` (ikon + judul + pesan + aksi opsional) dipakai di:
- Laporan Saya kosong, Daftar Tugas kosong, Riwayat kosong,
- Verifikasi/Penugasan/Monitoring kosong (`Belum ada laporan dengan status ini.`),
- Notifikasi kosong (`Belum ada notifikasi`).

### 3.4 Validasi & umpan balik sukses
- Validasi sebelum kirim: email/kata sandi wajib, kata sandi minimal 6 karakter, semua kolom
  registrasi wajib, deskripsi laporan minimal 10 karakter, alasan penolakan wajib, catatan
  penyelesaian minimal 5 karakter.
- Konfirmasi aksi penting memakai `confirmDialog` (Mulai tugas, Selesaikan, Tolak, Keluar).
- Umpan balik sukses memakai snackbar (`showSnack`) + perubahan status badge & timeline.

### 3.5 Async yang benar
Operasi async di alur utama dilindungi pemeriksaan `if (!mounted) return;` /
`if (!context.mounted) return;` sebelum `setState` atau memakai `BuildContext`, sehingga tidak
muncul error "setState after dispose". UI reaktif memakai `ListenableBuilder` ke `AppStore`
(notifier), sehingga perubahan data langsung tercermin di semua halaman tanpa refresh manual.

**Bukti:** `03-login.png` (validasi kosong), `13-petugas-selesaikan.png` (validasi catatan),
`05-laporan-saya.png`, `15-notifikasi.png`, `11-petugas-tugas.png`.

---

## 4. Indikator 3 — Local persistence/cache + mobile capability (20%)

### 4.1 Persistence
- `AppStore.init()` memuat state dari `SharedPreferences` (key `sipahal_state_v3`):
  daftar user, laporan (termasuk riwayat status & penugasan), counter nomor laporan, dan
  **sesi login aktif** (`session`).
- Setiap perubahan memanggil `_save()` → JSON (`users`, `reports`, `counter`, `session`)
  disimpan; saat aplikasi dibuka lagi, sesi dan data pulih (tidak perlu login ulang).
- Seed data demo otomatis dibuat bila cache kosong; `resetDemoData()` mengembalikan data contoh
  (tombol **Profil → Reset data demo**).
- Cache rusak ditangani: `jsonDecode` dibungkus `try/catch`, gagal → seed ulang, aplikasi tetap
  jalan.
- Saat Firebase aktif, data contoh **tidak** disemai (agar tidak menimpa Firestore) dan tombol
  **Reset data demo** disembunyikan; cache lokal hanya menyimpan sesi & salinan terakhir.

### 4.2 Kemampuan mobile yang terintegrasi
| Kemampuan | Implementasi | Bukti |
|---|---|---|
| GPS + izin runtime | `geolocator`, `ACCESS_FINE_LOCATION`/`ACCESS_COARSE_LOCATION` di `AndroidManifest.xml`, alur izin ditolak/diblokir | `17-buat-laporan.png`, `21-laporan-terkirim.png` |
| Peta & marker | `flutter_map` + OpenStreetMap, marker per status, peta mini di detail | `04-warga-map.png`, `06-detail.png`, `07-admin-dashboard.png` |
| Pilih titik manual | `MapPickerPage` mengembalikan `LocationData` | `18-pilih-titik.png` |
| Kamera / galeri | `image_picker` untuk foto kondisi & bukti pekerjaan | form buat laporan & selesaikan tugas |
| Navigasi eksternal | skema `geo:` via `url_launcher`, fallback Google Maps (`queries` di manifest) | tombol buka peta pada detail laporan |
| Penyimpanan foto lintas platform | base64 saat mode lokal; URL Firebase Storage (`Image.network`) saat cloud | `06-detail.png`, `23-status-penyimpanan.png` |
| Layout adaptif | `NavigationRail` + konten `maxWidth: 900` untuk admin di layar ≥ 900 dp; form pembuka dibatasi lebarnya | uji `wm size 2560x1600` |

---

## 5. Indikator 4 — Auth & security basics (15%)

### 5.1 Yang sudah diterapkan
- **Autentikasi**: `AuthService.signIn` memvalidasi email terdaftar, kata sandi, dan status akun
  aktif (`isActive`). Saat Firebase aktif, verifikasi kredensial dilakukan **Firebase Auth**
  (token + refresh otomatis), dan profil/`role` dibaca dari dokumen `users/{uid}`.
  Pesan error tidak membocorkan data sensitif.
- **Otorisasi berbasis peran**:
  - `homeForUser()` memilih shell sesuai `Role` — warga/petugas/admin tidak bisa masuk ke
    halaman peran lain (`lib/pages/home_router.dart`);
  - login menolak akun dengan peran berbeda: *"Akun ini terdaftar sebagai Petugas DLH.
    Silakan masuk dari menu peran tersebut."*;
  - data dibatasi per peran: `reportsFor()` → warga hanya laporan miliknya, petugas hanya
    tugas yang ditugaskan kepadanya, admin semua (`AppStore.reportsFor`);
  - aksi admin/petugas selalu memeriksa status asal yang sah, sehingga laporan tidak bisa
    diubah statusnya oleh alur yang salah.
- **Keamanan di sisi server (mode cloud)**: `firebase/firestore.rules` dan
  `firebase/storage.rules` menolak tulis dari peran yang salah, mewajibkan status awal
  `menunggu`, membatasi warga agar tidak mengubah status, dan membatasi petugas pada laporan
  yang ditugaskan kepadanya. Field `password` ditolak di dokumen user.
- **Sesi**: `signOut` memanggil `FirebaseAuth.signOut()` (mode cloud) atau menghapus sesi
  tersimpan (mode lokal); tombol Keluar memakai dialog konfirmasi.
- **Tanpa secret di kode**: tidak ada API key/token yang di-hardcode. Peta memakai tile
  OpenStreetMap publik via **HTTPS** (`https://tile.openstreetmap.org/...`); tidak ada
  Google Maps key yang perlu disembunyikan. Konfigurasi Firebase berada di
  `google-services.json` yang di-gitignore.
- **Input tidak dipercaya**: semua teks di-`trim()`, email dinormalisasi ke huruf kecil,
  validasi panjang kata sandi dan catatan dilakukan sebelum menyentuh data.

### 5.2 Kondisi per mode

| Aspek | Mode lokal (tanpa kredensial) | Mode cloud (Firebase aktif) |
|---|---|---|
| Kata sandi | Plaintext di `SharedPreferences`, hanya untuk akun demo | Dikelola Firebase Auth; tidak pernah ditulis ke Firestore |
| Sesi/token | `uid` di cache lokal | Firebase ID token + refresh otomatis |
| Aturan akses | Guard di UI/store | Security Rules Firestore & Storage (server-side) + guard UI |
| Foto | base64 di dokumen laporan | Upload Storage, URL https di `photoData` |

Aturan yang sudah ada di repo (bukan lagi rancangan) ada di
[`firebase/firestore.rules`](../firebase/firestore.rules) dan
[`firebase/storage.rules`](../firebase/storage.rules), dengan ringkasan pada
[`docs/FIREBASE_SETUP.md`](FIREBASE_SETUP.md) bagian 4.

**Yang belum diverifikasi:** eksekusi nyata terhadap project Firebase (login cloud, tulis
Firestore, upload Storage) karena `google-services.json` belum tersedia. Semua langkah untuk
mengaktifkan dan checklist verifikasinya sudah disiapkan di `docs/FIREBASE_SETUP.md`.

---

## 6. Indikator 5 — Integration evidence & verification (10%)

### 6.1 Otomatis
```bash
cd apk_sipahal
flutter analyze     # No issues found!
flutter test        # 2 test lulus
```

Isi test (`apk_sipahal/test/app_store_test.dart`):
1. `alur status laporan berjalan sesuai PRD` — login warga → buat laporan (`menunggu`) →
   admin verifikasi → admin tugaskan → petugas mulai → petugas selesai; memeriksa status
   akhir, petugas yang ditugaskan, dan **jumlah entri riwayat = 5**.
2. `penolakan wajib memiliki alasan` — menolak tanpa alasan harus gagal/melempar error.

### 6.2 Manual end-to-end (sudah dijalankan di emulator `Medium_Phone`, Android 14)
1. Warga login → peta memuat 6 laporan + filter status.
2. Warga membuat laporan baru: GPS → deskripsi → kirim → status `menunggu`, muncul di peta
   dan Laporan Saya (`21-laporan-terkirim.png`, `17-buat-laporan.png`).
3. Admin membuka Verifikasi, memverifikasi laporan baru (`08-verifikasi.png`), lalu
   menugaskannya ke petugas (`09-penugasan.png`, `10-pilih-petugas.png`).
4. Petugas melihat tugas (`11-petugas-tugas.png`), menekan **Mulai sekarang**
   (`12-petugas-mulai.png`) → `dikerjakan`, lalu **Selesaikan** dengan catatan
   (`13-petugas-selesaikan.png`) → `selesai` dan muncul "Catatan petugas"
   (`14-petugas-selesai.png`).
5. Timeline dan halaman Notifikasi ikut terbarui (`06-detail.png`, `15-notifikasi.png`).
6. Persistensi: tutup dan buka ulang aplikasi → sesi & data tetap ada.
7. Mode build: Profil menampilkan sumber data aktif (`23-status-penyimpanan.png`). Dengan
   `google-services.json` terpasang, status berubah menjadi **Firebase (cloud)** dan alur di
   atas tersinkron ke Console — checklist lengkap di `docs/FIREBASE_SETUP.md` bagian 8.

### 6.3 Peta acceptance criteria PRD → bukti

| Acceptance criteria (PRD Backend / Frontend / Maps) | Bukti |
|---|---|
| Login valid berhasil, role terbaca dari data user | `03-login.png`, `home_router.dart`, test #1 |
| Laporan baru berstatus `menunggu` | `21-laporan-terkirim.png`, test #1 |
| Hanya admin dapat verifikasi/tolak/tugaskan | guard transisi `_transition`, `08`–`10.png` |
| Penolakan wajib alasan | validasi + test #2 |
| Petugas hanya melihat tugas miliknya | `reportsFor`, `11-petugas-tugas.png`, `22-petugas-rina.png` |
| Semua perubahan status masuk riwayat | `06-detail.png`, `history.length == 5` pada test |
| Warga mengirim laporan dengan `LocationData` | `17`, `18`, `21.png` |
| GPS valid, izin ditolak tertangani, bisa pilih manual | `LocationService`, `18-pilih-titik.png` |
| Marker laporan tampil & klik membuka ringkasan | `04`, `07.png` |
| Petugas dapat membuka navigasi | `openNavigation` + `geo:` di manifest |
| Loading / empty / error / validasi / feedback | bagian 3 + screenshot terkait |
| Admin responsif (web/tablet) | uji `wm size 2560x1600`, `07-admin-dashboard.png` |

---

## 7. Daftar screenshot (semua ada di `screenshots/`)

| File | Isi |
|---|---|
| `01-opening.png` | Halaman pembuka |
| `02-role.png` | Pilih jenis akun |
| `03-login.png` | Login + isi akun demo |
| `04-warga-map.png` | Peta titik sampah + tombol Buat Laporan |
| `05-laporan-saya.png` | Daftar laporan warga |
| `06-detail.png` | Detail laporan + peta + timeline status |
| `07-admin-dashboard.png` | Dashboard admin + sebaran titik (mode lebar) |
| `08-verifikasi.png` | Verifikasi laporan |
| `09-penugasan.png` | Daftar siap ditugaskan |
| `10-pilih-petugas.png` | Pilih petugas |
| `11-petugas-tugas.png` | Daftar tugas petugas |
| `12-petugas-mulai.png` | Konfirmasi mulai tugas |
| `13-petugas-selesaikan.png` | Form selesaikan tugas |
| `14-petugas-selesai.png` | Laporan berstatus selesai + catatan petugas |
| `15-notifikasi.png` | Notifikasi perubahan status |
| `16-profil.png` | Profil warga |
| `17-buat-laporan.png` | Form laporan + GPS |
| `18-pilih-titik.png` | Pilih titik manual di peta |
| `20-profil-admin.png` | Profil admin |
| `21-laporan-terkirim.png` | Laporan baru masuk ke peta admin |
| `22-petugas-rina.png` | Tugas untuk petugas kedua |
| `23-status-penyimpanan.png` | Profil: status penyimpanan `Lokal (demo)` / `Firebase (cloud)` |

---

## 8. Cara mereproduksi bukti

```bash
# 1. Siapkan project
cd apk_sipahal
flutter pub get

# 2. Jalankan emulator Android, lalu aplikasi
flutter emulators --launch Medium_Phone
flutter run -d emulator-5554

# 3. (opsional) GPS palsu untuk emulator
adb emu geo fix 104.4467 0.9186

# 4. Uji otomatis
flutter analyze
flutter test

# 5. Build & pasang APK
flutter build apk --debug
adb install -r build/app/outputs/flutter-apk/app-debug.apk
adb shell am start -n com.example.apk_sipahal/.MainActivity

# 6. Reset ke data demo
adb shell pm clear com.example.apk_sipahal
```

**Akun demo:** `warga@sipahal.com` / `warga123` · `petugas@sipahal.com` / `petugas123` ·
`rina@sipahal.com` / `petugas123` · `admin@sipahal.com` / `admin123`.
Tombol *"Isi akun demo (ketuk)"* di halaman login mengisi kredensial otomatis.

Panduan langkah demi langkah (emulator, HP asli, APK, troubleshooting):
`docs/PANDUAN_MENJALANKAN.md`.
Panduan Firebase (project, akun demo cloud, rules, checklist):
`docs/FIREBASE_SETUP.md`.

### 8.1 Mengaktifkan mode Firebase (ringkas)

```bash
# 1. Buat project Firebase + app Android (package com.example.apk_sipahal)
# 2. Unduh google-services.json -> apk_sipahal/android/app/google-services.json
# 3. Aktifkan Authentication (Email/Password), Firestore, Storage
# 4. Deploy rules
cd firebase
firebase use --add
firebase deploy --only firestore:rules,storage
# 5. Buat 4 akun demo + dokumen users/{uid} + counters/reports (lihat panduan)
# 6. Build ulang
cd ../apk_sipahal && flutter run -d emulator-5554
```

Tanpa langkah ini, aplikasi tetap berjalan dengan data lokal.

---

## 9. Kesimpulan

| Indikator | Bukti yang tersedia | Keterangan |
|---|---|---|
| Integrasi data (30%) | Firebase Auth/Firestore/Storage di `firebase_backend.dart`, write-through + snapshot listener, counter atomik, Security Rules, kontrak service PRD | Kode siap; aktif otomatis saat kredensial dipasang, fallback lokal teruji |
| Async/state (25%) | Loading, empty, error, validasi, konfirmasi, snackbar, `mounted` check | Teruji lewat aksi nyata di emulator |
| Persistence + mobile (20%) | Cache `SharedPreferences` + sesi, GPS/izin, kamera, peta, `geo:`, layout adaptif | Bertahan setelah app ditutup |
| Auth & security (15%) | Role routing, tolak peran salah, blokir akun nonaktif, tanpa secret, HTTPS, rules Firestore/Storage | Firebase Auth & rules aktif di mode cloud |
| Evidence (10%) | `analyze` bersih, 2 test lulus, 22 screenshot alur penuh, langkah reproduksi + panduan Firebase | Bisa diulang oleh penilai |
