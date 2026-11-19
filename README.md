# SIPAHAL

### Sistem Informasi Pelaporan & Pemetaan Titik Pembuangan Sampah Liar

SIPAHAL adalah aplikasi mobile berbasis Flutter yang dirancang untuk membantu masyarakat melaporkan lokasi pembuangan sampah liar melalui informasi lokasi geografis (*geolocation*). Aplikasi ini bertujuan mendukung pemetaan titik pembuangan sampah liar dan membantu pengelolaan sampah yang lebih terarah.

## Cara Menjalankan (VS Code)

Kode Flutter ada di folder `apk_sipahal`. Buka folder itu di VS Code (bukan folder root repo), karena di situ `pubspec.yaml` berada:

```bash
cd apk_sipahal
flutter pub get
flutter run -d emulator-5554   # atau pilih device Android di VS Code lalu tekan F5
```

- Panduan lengkap: [`docs/PANDUAN_MENJALANKAN.md`](docs/PANDUAN_MENJALANKAN.md)
- Tangkapan layar aplikasi: [`screenshots/`](screenshots/)
- Bukti rubrik Phase 3 (data, backend & integrasi platform): [`docs/RUBRIK_PHASE3.md`](docs/RUBRIK_PHASE3.md)
- Panduan mengaktifkan Firebase (cloud): [`docs/FIREBASE_SETUP.md`](docs/FIREBASE_SETUP.md)

## 📌 Latar Belakang

Pembuangan sampah liar merupakan salah satu permasalahan lingkungan yang dapat mengganggu kebersihan dan kenyamanan masyarakat. Kurangnya informasi mengenai lokasi pembuangan sampah liar dapat menyulitkan proses pemantauan dan penanganan.

Oleh karena itu, SIPAHAL dirancang sebagai solusi digital yang memungkinkan pengguna melaporkan lokasi pembuangan sampah liar secara lebih mudah dan membantu mengumpulkan informasi lokasi untuk keperluan pemetaan.

## 🎯 Tujuan

* Mempermudah masyarakat melaporkan titik pembuangan sampah liar.
* Mengumpulkan informasi lokasi pembuangan sampah liar secara terstruktur.
* Mendukung pemetaan lokasi untuk membantu pemantauan dan pengelolaan sampah.
* Mengembangkan solusi mobile yang memanfaatkan teknologi geolocation.

## ✨ Fitur Utama

Aplikasi memiliki tiga peran dengan hak akses berbeda:

**Warga / Pelapor**
* Registrasi dan login.
* Peta titik sampah liar dengan penanda per status.
* Membuat laporan: foto, kategori, deskripsi, dan lokasi (GPS atau pilih titik di peta).
* Daftar "Laporan Saya" beserta detail, timeline status, dan notifikasi.
* Profil dan reset data demo.

**Petugas DLH**
* Daftar tugas yang ditugaskan kepadanya.
* Mulai tugas (`dikerjakan`) dan menyelesaikan tugas dengan catatan + bukti foto (`selesai`).
* Riwayat pekerjaan, notifikasi, dan profil.

**Admin DLH**
* Dashboard ringkasan + sebaran titik laporan di peta.
* Verifikasi laporan, atau menolak dengan alasan wajib.
* Penugasan laporan terverifikasi ke petugas.
* Monitoring laporan per status.

Status laporan mengikuti PRD: `menunggu` → `diverifikasi` → `ditugaskan` → `dikerjakan` → `selesai`, atau `ditolak` (dengan alasan).

## 🛠️ Teknologi yang Digunakan

* **Flutter** — pengembangan antarmuka aplikasi mobile.
* **Dart** — bahasa pemrograman.
* **flutter_map + OpenStreetMap** — peta dan marker (tanpa API key Google Maps).
* **geolocator** — pengambilan koordinat GPS dan penanganan izin lokasi.
* **image_picker** — kamera/galeri untuk foto kondisi dan bukti pekerjaan.
* **shared_preferences** — cache lokal (data demo + sesi login).
* **Firebase** — Authentication, Cloud Firestore, dan Storage untuk mode cloud
  (aktif otomatis bila `android/app/google-services.json` dipasang; jika tidak, aplikasi
  memakai data lokal).
* **url_launcher** — membuka navigasi eksternal (`geo:`).
* **intl** — format tanggal/waktu Bahasa Indonesia.
* **Git & GitHub** — pengelolaan kode sumber dan kolaborasi tim.
* **Figma** — perancangan UI/UX.

## 📂 Struktur Proyek

```text
apk_sipahal/
├── lib/
│   ├── core/          # tema warna dan util
│   ├── models/        # Role, ReportStatus, AppUser, Report, Assignment, LocationData
│   ├── data/          # AppStore (cache lokal) + FirebaseBackend (Auth, Firestore, Storage)
│   ├── services/      # AuthService, ReportService, LocationService
│   ├── pages/         # opening, warga, petugas, admin, detail, notifikasi, profil
│   ├── widgets/       # komponen UI + peta (ReportMap, MapPicker, LocationPreview)
│   └── main.dart
├── test/              # test alur status & validasi penolakan
├── android/           # konfigurasi Android (izin lokasi, label SIPAHAL)
├── firebase/          # security rules Firestore & Storage + firebase.json
├── pubspec.yaml
└── README.md
```

## 🚀 Cara Menjalankan Aplikasi

Pastikan Flutter SDK dan Git sudah terpasang di komputer.

1. Clone repositori:

   ```bash
   git clone URL_REPOSITORY_KALIAN
   ```

2. Masuk ke folder aplikasi:

   ```bash
   cd sipahal/apk_sipahal
   ```

3. Unduh dependensi:

   ```bash
   flutter pub get
   ```

4. Periksa konfigurasi Flutter:

   ```bash
   flutter doctor
   ```

5. Jalankan aplikasi pada emulator atau perangkat yang terhubung:

   ```bash
   flutter run
   ```

## 📊 Status Pengembangan

**Status:** Prototipe selesai dan sudah diuji end-to-end di emulator Android 14.

* [x] Perancangan kebutuhan dan UI/UX.
* [x] Implementasi antarmuka aplikasi (warga, petugas, admin).
* [x] Implementasi navigasi dan validasi formulir.
* [x] Implementasi pelaporan dan penyimpanan data (cache lokal + integrasi Firebase).
* [x] Integrasi geolocation, foto, dan peta.
* [x] Pengujian aplikasi (`flutter analyze`, `flutter test`, uji manual).
* [ ] Aktivasi Firebase produksi (pasang `google-services.json` + deploy rules) —
  lihat [`docs/FIREBASE_SETUP.md`](docs/FIREBASE_SETUP.md).

## 👥 Tim Pengembang

|            Nama            |    NIM     | Peran / Deskripsi Tugas       |
| -------------------------- | ---------- | ---------------------------   |
| Atsilah Halimatus Sa'diyah | 2401020142 | Project Manager               |
| Nabiilah Rifa Musyifa      | 2401020162 | UI/UX Designer                |
| Siti Melka Rehngenana      | 2401020132 | Backend & Database Developer  |
| Christine Simbolon         | 2401020158 | Geolocation & Maps Specialist |
| Christian Aprilio Sihite   | 2401020151 | Lead Frontend Developer       |
| Nurfaizah Rasikha          | 2401020156 | Documentation Specialist      |

## 🎓 Informasi Proyek

* **Mata Kuliah:** Pemrograman Perangkat Bergerak
* **Platform:** Mobile
* **Framework:** Flutter
* **Bahasa Pemrograman:** Dart
* **Institusi:** Universitas Maritim Raja Ali Haji

## 📄 Lisensi

Lisensi proyek akan ditentukan sesuai kebutuhan tim dan ketentuan penggunaan kode.

---

*Proyek SIPAHAL dikembangkan sebagai bagian dari kegiatan pembelajaran dan pengembangan aplikasi mobile.*
