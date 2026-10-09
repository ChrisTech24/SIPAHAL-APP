# SIPAHAL

### Sistem Informasi Pelaporan & Pemetaan Titik Pembuangan Sampah Liar

SIPAHAL adalah aplikasi mobile berbasis Flutter yang dirancang untuk membantu masyarakat melaporkan lokasi pembuangan sampah liar melalui informasi lokasi geografis (*geolocation*). Aplikasi ini bertujuan mendukung pemetaan titik pembuangan sampah liar dan membantu pengelolaan sampah yang lebih terarah.

## 📌 Latar Belakang

Pembuangan sampah liar merupakan salah satu permasalahan lingkungan yang dapat mengganggu kebersihan dan kenyamanan masyarakat. Kurangnya informasi mengenai lokasi pembuangan sampah liar dapat menyulitkan proses pemantauan dan penanganan.

Oleh karena itu, SIPAHAL dirancang sebagai solusi digital yang memungkinkan pengguna melaporkan lokasi pembuangan sampah liar secara lebih mudah dan membantu mengumpulkan informasi lokasi untuk keperluan pemetaan.

## 🎯 Tujuan

* Mempermudah masyarakat melaporkan titik pembuangan sampah liar.
* Mengumpulkan informasi lokasi pembuangan sampah liar secara terstruktur.
* Mendukung pemetaan lokasi untuk membantu pemantauan dan pengelolaan sampah.
* Mengembangkan solusi mobile yang memanfaatkan teknologi geolocation.

## ✨ Fitur Utama

Fitur yang direncanakan dalam pengembangan SIPAHAL meliputi:

* **Autentikasi Pengguna:** registrasi dan login pengguna.
* **Pelaporan Sampah Liar:** formulir laporan yang berisi deskripsi dan kategori sampah.
* **Geolocation:** pengambilan koordinat lokasi laporan.
* **Unggah Foto:** dokumentasi kondisi lokasi yang dilaporkan.
* **Pemetaan Lokasi:** menampilkan titik pembuangan sampah liar pada peta.
* **Daftar Laporan:** melihat laporan yang telah dibuat.

*Catatan: daftar fitur akan diperbarui sesuai dengan hasil implementasi.*

## 🛠️ Teknologi yang Digunakan

* **Flutter** — pengembangan antarmuka aplikasi mobile.
* **Dart** — bahasa pemrograman.
* **Git & GitHub** — pengelolaan kode sumber dan kolaborasi tim.
* **Figma** — perancangan UI/UX.

Teknologi tambahan untuk penyimpanan data, autentikasi, peta, dan geolocation akan dicantumkan setelah ditentukan dan diintegrasikan ke dalam aplikasi.

## 📂 Struktur Proyek

Struktur direktori akan disesuaikan dengan implementasi aplikasi. Contoh struktur yang direncanakan:

```text
sipahal/
├── lib/
│   ├── models/
│   ├── views/
│   ├── viewmodels/
│   ├── repositories/
│   ├── services/
│   ├── widgets/
│   ├── app.dart
│   └── main.dart
├── test/
├── assets/
├── pubspec.yaml
└── README.md
```

## 🚀 Cara Menjalankan Aplikasi

Pastikan Flutter SDK dan Git sudah terpasang di komputer.

1. Clone repositori:

   ```bash
   git clone URL_REPOSITORY_KALIAN
   ```

2. Masuk ke direktori proyek:

   ```bash
   cd sipahal
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

**Status:** Dalam pengembangan.

Tahapan pengembangan meliputi:

* [ ] Perancangan kebutuhan dan UI/UX.
* [ ] Implementasi antarmuka aplikasi.
* [ ] Implementasi navigasi dan validasi formulir.
* [ ] Implementasi pelaporan dan penyimpanan data.
* [ ] Integrasi geolocation, foto, dan peta.
* [ ] Pengujian aplikasi.
* [ ] Persiapan rilis aplikasi.

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
