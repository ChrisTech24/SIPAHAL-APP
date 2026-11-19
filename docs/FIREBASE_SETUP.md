# Panduan Mengaktifkan Firebase (Mode Cloud)

Dokumen ini menjelaskan cara menghubungkan aplikasi SIPAHAL ke **Firebase asli**
(Authentication, Cloud Firestore, Firebase Storage) sehingga indikator
*REST API / Firebase / BaaS integration* pada rubrik Phase 3 terpenuhi secara nyata.

Aplikasi tetap bisa berjalan **tanpa Firebase** (mode data lokal / demo). Firebase
aktif otomatis hanya jika file `android/app/google-services.json` ada dan
`Firebase.initializeApp()` berhasil.

---

## 0. Ringkasan perilaku

| Kondisi | Yang terjadi |
|---|---|
| `android/app/google-services.json` **tidak ada** | `FirebaseBackend.connect()` gagal → aplikasi memakai `AppStore` + `SharedPreferences`. Semua fitur demo tetap jalan. Profil menampilkan **Penyimpanan data: Lokal (demo)**. |
| File ada & Firebase valid | Login/daftar lewat **Firebase Auth**, data lewat **Cloud Firestore**, foto lewat **Firebase Storage**. Profil menampilkan **Penyimpanan data: Firebase (cloud)**. |
| Firebase error saat start (mis. config salah) | Dicatat di log (`Firebase nonaktif, memakai data lokal: ...`), aplikasi **tidak crash**, kembali ke mode lokal. |

Kelas yang terlibat:

- `lib/data/firebase_backend.dart` — koneksi, listener, auth, tulis data, counter, upload.
- `lib/data/app_store.dart` — cache lokal + jembatan cloud (write-through + snapshot).
- `lib/services/services.dart` — `AuthService`, `ReportService` (kontrak PRD tetap).
- `firebase/firestore.rules`, `firebase/storage.rules` — Security Rules.

---

## 1. Buat project Firebase

1. Buka <https://console.firebase.google.com> → **Add project** → beri nama, misal `sipahal`.
2. Google Analytics boleh dimatikan (tidak dipakai aplikasi ini).

## 2. Tambahkan aplikasi Android

1. Di halaman project → ikon **Android** → *Add app*.
2. **Android package name** harus sama dengan `applicationId`:
   ```
   com.example.apk_sipahal
   ```
3. Nickname bebas (`SIPAHAL`). SHA-1 tidak wajib untuk Auth email/password.
4. Unduh **`google-services.json`**, lalu letakkan persis di:
   ```
   apk_sipahal/android/app/google-services.json
   ```
5. Plugin Gradle sudah disiapkan dan **hanya aktif bila file itu ada**
   (`android/app/build.gradle.kts`, `android/settings.gradle.kts`).

> Jangan menaruh `google-services.json` di `apk_sipahal/` (root) — harus di folder `android/app/`.

## 3. Aktifkan layanan

### 3.1 Authentication
- Menu **Build → Authentication → Get started**.
- Tab **Sign-in method** → aktifkan **Email/Password**.
- (Opsional) matikan *Email link (passwordless)*.

### 3.2 Cloud Firestore
- Menu **Build → Firestore Database → Create database**.
- Pilih lokasi terdekat (mis. `asia-southeast2` / Jakarta).
- Mulai dengan **Production mode** (rules akan kita deploy).

### 3.3 Firebase Storage
- Menu **Build → Storage → Get started** → lokasi yang sama → Production mode.

## 4. Deploy Security Rules

Rules ada di folder `firebase/`:

```bash
cd firebase
npm install -g firebase-tools      # sekali saja
firebase login
firebase use --add                 # pilih project SIPAHAL
firebase deploy --only firestore:rules,storage
```

Atau salin isi `firebase/firestore.rules` dan `firebase/storage.rules` ke tab
**Rules** di Firebase Console lalu **Publish**.

Ringkasan aturan:

| Koleksi | Aturan |
|---|---|
| `users/{uid}` | Baca: semua yang login. Buat: diri sendiri, peran `warga`/`petugas`, tanpa field `password`. Ubah: pemilik (nama/telepon) atau admin. Hapus: tidak boleh. |
| `reports/{id}` | Baca: semua yang login. Buat: warga, `reporterId` = dirinya, status `menunggu`. Ubah: admin bebas; petugas hanya laporan miliknya & field progres. Hapus: tidak boleh. |
| `counters/{id}` | Baca: login. Tulis: warga/admin (untuk nomor laporan atomik). |
| Storage `report_photos/` | Baca: login. Tulis: login, gambar, maks 8 MB. |

> Catatan keamanan: pendaftaran mandiri dibatasi ke peran `warga`/`petugas`.
> Akun **admin** sebaiknya dibuat manual oleh pemilik project (lihat langkah 5).
> Untuk produksi, pembuatan akun petugas/admin idealnya lewat Admin SDK / Cloud Function.

## 5. Siapkan akun demo di Firebase

Mode cloud **tidak** memakai seed lokal, jadi akun demo harus ada di Firebase.

### 5.1 Buat user di Authentication

Menu **Authentication → Users → Add user**:

| Email | Kata sandi | Peran |
|---|---|---|
| `warga@sipahal.com` | `warga123` | warga |
| `petugas@sipahal.com` | `petugas123` | petugas |
| `rina@sipahal.com` | `petugas123` | petugas |
| `admin@sipahal.com` | `admin123` | admin |

Setelah dibuat, **salin UID** tiap user (kolom *User UID*).

### 5.2 Buat dokumen profil `users/{uid}`

Menu **Firestore → Start collection** bernama `users`, lalu satu dokumen per akun
dengan **Document ID = UID** dan field:

```json
{
  "uid": "UID_DARI_AUTH",
  "name": "Ayu Lestari",
  "email": "warga@sipahal.com",
  "phone": "0812-7000-1122",
  "role": "warga",
  "isActive": true,
  "createdAt": "2026-01-10T08:00:00.000"
}
```

`role` hanya boleh salah satu: `warga`, `petugas`, `admin`.
**Jangan** menambahkan field `password` — kata sandi hanya di Firebase Auth.

Contoh isi untuk akun lain:

| Email | name | role | phone |
|---|---|---|---|
| `petugas@sipahal.com` | Petugas DLH | `petugas` | `0812-7000-5566` |
| `rina@sipahal.com` | Rina Marlina | `petugas` | `0812-7000-7788` |
| `admin@sipahal.com` | Admin DLH | `admin` | `0812-7000-9900` |

### 5.3 Buat counter nomor laporan

Koleksi `counters`, dokumen ID `reports`, field:

```json
{ "value": 0 }
```

Nomor tampilan (`#0001`, `#0002`, …) dihitung atomik lewat transaksi Firestore
(`FirebaseBackend.nextDisplayNumber`), sehingga dua warga yang mengirim bersamaan
tidak mendapat nomor sama.

### 5.4 (Opsional) Data contoh laporan

Aplikasi tidak menyemai laporan contoh di mode cloud. Untuk demo, buat manual di
koleksi `reports` mengikuti skema di bagian 6, atau gunakan aplikasi untuk membuat
laporan baru.

## 6. Skema data di Firestore

Nama field sama dengan model Dart (`lib/models/models.dart`), sehingga
`Report.toJson()` / `AppUser.toPublicJson()` bisa langsung ditulis.

### `users/{uid}`
`uid`, `name`, `email`, `phone`, `role`, `isActive`, `createdAt` (ISO string).

### `reports/{reportId}`
`id`, `displayId`, `reporterId`, `reporterName`, `locationText`, `latitude`,
`longitude`, `category`, `description`, `status`, `rejectionReason`,
`assignedOfficerId`, `assignedOfficerName`, `photoData`, `createdAt`, `updatedAt`,
plus dua field bersarang:

```json
{
  "assignment": {
    "id": "a...", "reportId": "r...", "officerId": "UID",
    "assignedBy": "UID_ADMIN", "status": "ditugaskan",
    "assignedAt": "2026-01-10T09:00:00.000",
    "startedAt": null, "completedAt": null,
    "workNote": null, "proofPhotoPath": null
  },
  "history": [
    {
      "id": "h...", "reportId": "r...",
      "fromStatus": null, "toStatus": "menunggu",
      "changedBy": "UID_WARGA", "changedByName": "Ayu Lestari",
      "note": "Laporan dikirim warga",
      "createdAt": "2026-01-10T08:30:00.000"
    }
  ]
}
```

Status yang sah hanya: `menunggu`, `diverifikasi`, `ditugaskan`, `dikerjakan`,
`selesai`, `ditolak`.

### Foto
- Mode cloud: `photoData` berisi **URL download Firebase Storage**
  (`https://firebasestorage.googleapis.com/...`) dari folder `report_photos/`.
- Mode lokal: `photoData` berisi **base64** (agar tetap jalan di web/emulator).

UI `ReportPhoto` mendukung keduanya (`Image.network` untuk URL, `Image.memory`
untuk base64).

## 7. Build & jalankan

```bash
cd apk_sipahal
flutter pub get
flutter run -d emulator-5554
```

Atau build APK:

```bash
flutter build apk --debug
adb install -r build/app/outputs/flutter-apk/app-debug.apk
adb shell am start -n com.example.apk_sipahal/.MainActivity
```

Saat build, Gradle mencetak salah satu baris:

```
SIPAHAL: Firebase aktif (google-services.json ditemukan).
SIPAHAL: google-services.json belum ada, memakai data lokal.
```

## 8. Checklist verifikasi

1. Login `warga@sipahal.com` / `warga123` → berhasil.
2. **Profil → Penyimpanan data** menunjukkan **Firebase (cloud)**.
3. Buat laporan baru (GPS / pilih titik) → dokumen baru muncul di koleksi
   `reports` Firebase Console, `displayId` berurutan, status `menunggu`.
4. Login admin → verifikasi laporan → status berubah di Console **dan** di perangkat
   lain secara real-time (snapshot listener).
5. Admin menugaskan laporan ke petugas → field `assignedOfficerId` & `assignment` terisi.
6. Login petugas → **Mulai** (`dikerjakan`) → **Selesaikan** + catatan & foto
   (`selesai`, `completedAt`, `workNote`, `proofPhotoPath` terisi).
7. Buka Firebase Console → **Storage** → foto ada di `report_photos/`, dan
   `photoData` laporan berisi URL.
8. Tutup & buka aplikasi → sesi Firebase pulih (tidak perlu login ulang).
9. Nonaktifkan akun di Console (`isActive: false`) → login ditolak dengan pesan
   "Akun ini sedang dinonaktifkan oleh admin."
10. Hapus `google-services.json` lalu build ulang → aplikasi tetap jalan dengan
    data lokal (fallback terbukti).

## 9. Troubleshooting

| Gejala | Penyebab & solusi |
|---|---|
| `Building with plugins requires symlink support` | Aktifkan **Developer Mode** Windows: `start ms-settings:developers`, lalu `flutter pub get` ulang. |
| `Firebase nonaktif, memakai data lokal: ...` | `google-services.json` tidak ada/salah lokasi, atau `applicationId` tidak cocok dengan package di Firebase. |
| `operation-not-allowed` | Provider **Email/Password** belum diaktifkan di Authentication. |
| `permission-denied` | Security Rules belum dideploy, atau `users/{uid}` belum dibuat sehingga `role()` gagal. |
| Login berhasil tapi aplikasi menolak | Dokumen `users/{uid}` tidak ada / `isActive` bukan `true`. |
| Upload foto gagal | Storage belum dibuat, rules belum deploy, atau file > 8 MB. |
| `minimum supported Gradle version` / plugin | Pastikan `settings.gradle.kts` memuat `com.google.gms.google-services` versi `4.4.2` (sudah disiapkan). |

## 10. Catatan & batasan

- Firebase **tidak** dipakai saat aplikasi dijalankan di web (`FirebaseBackend.connect`
  mengembalikan `null` untuk `kIsWeb`) — demo web tetap memakai data lokal.
- mode cloud tidak menyemai data contoh; akun harus disiapkan manual (bagian 5).
- `resetDemoData()` dinonaktifkan saat cloud aktif (tombolnya disembunyikan) agar
  data Firestore tidak tertimpa seed lokal.
- Security Rules memakai pembacaan dokumen profil (`get`) untuk menentukan peran.
  Ini cukup untuk skala demo; untuk produksi skala besar gunakan **Custom Claims**
  yang diset Cloud Function agar hemat biaya reads.
