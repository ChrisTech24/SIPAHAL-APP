# Panduan Menjalankan SIPAHAL di HP / Emulator (VS Code)

Dokumen ini menjawab pertanyaan: **"aplikasinya baru bisa di browser, bagaimana supaya jalan di HP?"**

Penyebabnya sederhana: Flutter menjalankan aplikasi di **device yang dipilih**. Saat ini
yang aktif hanya `Chrome`/`Edge` (web), jadi aplikasi muncul di browser. Supaya tampil
seperti aplikasi HP, kita harus memilih **emulator Android** atau **HP Android asli**.

> Folder yang dibuka di VS Code harus `C:\SIPAHAL-APP-main\apk_sipahal`
> (folder root repo saja tidak cukup, dan jangan tertukar dengan proyek lain seperti
> `C:\project_flutter\projek_sipahal`).

---

## 1. Jalankan di Emulator Android (paling mudah)

### Cara A — lewat VS Code
1. Buka VS Code, `File > Open Folder...` → pilih `C:\SIPAHAL-APP-main\apk_sipahal`.
2. Pastikan extension **Flutter** dan **Dart** sudah terpasang.
3. Buka Command Palette (`Ctrl+Shift+P`) → ketik **Flutter: Launch Emulator** → pilih `Medium_Phone`.
4. Tunggu emulator Android muncul (bisa 1–2 menit pertama kali).
5. Di **status bar kanan bawah** VS Code, klik nama device (misalnya `Chrome`) lalu ganti ke
   **`Android SDK built for x86 64 (emulator-5554)`**.
6. Tekan **F5** (atau menu `Run > Start Debugging`).

Aplikasi akan tampil persis seperti di HP, lengkap dengan GPS.

### Cara B — lewat terminal VS Code
```bash
flutter emulators --launch Medium_Phone
flutter devices
flutter run -d emulator-5554
```

Kalau `flutter devices` menampilkan `emulator-5554`, berarti siap.

### GPS di emulator
Emulator tidak punya GPS sungguhan. Set lokasi palsu (contoh: Tanjungpinang):
```bash
adb emu geo fix 104.4467 0.9186
```
Atau lewat menu emulator: `...` → **Location** → isi Latitude `0.9186`, Longitude `104.4467` → **Set Location**.
Kalau GPS tetap gagal, aplikasi **tidak crash** — pengguna tetap bisa memilih titik manual di peta.

---

## 2. Jalankan di HP Android asli

1. Di HP: `Setelan > Tentang ponsel` → ketuk **Nomor build** 7× untuk mengaktifkan Opsi Pengembang.
2. `Setelan > Opsi pengembang` → aktifkan **USB debugging** (dan **Install via USB** bila ada).
3. Colok HP ke laptop dengan kabel data, pilih mode **File Transfer / MTP**.
4. Di HP muncul dialog **"Izinkan akses data perangkat?"** → **Izinkan**.
5. Cek di terminal:
   ```bash
   flutter devices
   ```
   HP akan muncul sebagai device (misalnya `SM-A125F`).
6. Jalankan:
   ```bash
   flutter run -d <id-device>
   ```
   atau pilih nama HP di status bar VS Code lalu tekan **F5**.

Aplikasi langsung terpasang di HP. Untuk membuat file APK yang bisa dibagikan:
```bash
flutter build apk --release
```
Hasil: `build\app\outputs\flutter-apk\app-release.apk`.

---

## 3. Kalau muncul error saat build Android

**`Building with plugins requires symlink support`**
→ Aktifkan **Developer Mode** Windows: `Setelan > Privasi & keamanan > Untuk pengembang >
Mode pengembang = Aktif`. (Di Windows 11: `start ms-settings:developers`.)

**`NDK not found`**
→ Sudah diarahkan ke NDK yang terpasang (`28.2.13676358`) di
`android/app/build.gradle.kts`. Kalau NDK berbeda, sesuaikan angka tersebut dengan
folder di `C:\Users\<nama>\AppData\Local\Android\sdk\ndk`.

**Gradle lambat / gagal download**
→ Butuh internet saat build pertama. Build berikutnya jauh lebih cepat.

---

## 4. Akun demo

| Peran      | Email                  | Kata sandi  |
|------------|------------------------|-------------|
| Warga      | `warga@sipahal.com`    | `warga123`  |
| Petugas    | `petugas@sipahal.com`  | `petugas123`|
| Petugas 2  | `rina@sipahal.com`     | `petugas123`|
| Admin      | `admin@sipahal.com`    | `admin123`  |

Tombol **"Isi akun demo"** di halaman login mengisi email & kata sandi otomatis.

---

## 5. Alur demo untuk presentasi

1. Masuk sebagai **Warga** → menu **Peta** → **Buat Laporan** → foto, kategori, deskripsi,
   **Ambil GPS** atau **Pilih di peta** → isi alamat → **Kirim Laporan** (status `menunggu`).
2. Keluar, masuk sebagai **Admin** → tab **Verifikasi** → **Verifikasi**
   (atau **Tolak** dengan alasan wajib).
3. Tab **Penugasan** → **Tugaskan** → pilih petugas → status `ditugaskan`.
4. Masuk sebagai **Petugas** → **Mulai** → status `dikerjakan` → **Selesaikan**
   + catatan + bukti foto → status `selesai`.
5. Masuk lagi sebagai **Warga** → **Notifikasi** / detail laporan → lihat timeline status.

Semua transisi juga tercatat di **Riwayat status** pada detail laporan.

---

## 6. Catatan teknis

- **Dua mode penyimpanan** (otomatis, tanpa mengubah kode):
  - **Lokal (demo)** — jika `android/app/google-services.json` belum ada: data disimpan di HP
    (`shared_preferences`) lewat `AppStore`. Cocok untuk presentasi tanpa internet.
  - **Firebase (cloud)** — jika file itu ada: login lewat **Firebase Auth**, data di
    **Cloud Firestore**, foto di **Firebase Storage**. Profil menampilkan status mode aktif.
  - Panduan mengaktifkan Firebase (project, akun demo, rules, checklist):
    [`FIREBASE_SETUP.md`](FIREBASE_SETUP.md).
- Peta memakai **OpenStreetMap** (`flutter_map`), jadi **tidak butuh API key** Google Maps.
- Foto: base64 saat mode lokal, URL Firebase Storage saat mode cloud.
- `flutter run -d chrome` tetap bisa dipakai untuk melihat versi web, tetapi GPS dan
  kamera hanya berfungsi penuh di Android (Firebase tidak aktif di web).
- Data demo disimpan permanen di HP. Untuk kembali ke data contoh, buka **Profil →
  Reset data demo** (atau jalankan `adb shell pm clear com.example.apk_sipahal`).
  Tombol reset otomatis disembunyikan saat mode cloud aktif agar Firestore tidak tertimpa.

---

## 7. File APK siap pasang

```text
apk_sipahal\build\app\outputs\flutter-apk\app-debug.apk
```

Pasang ke emulator/HP:

```bash
adb install -r build\app\outputs\flutter-apk\app-debug.apk
adb shell am start -n com.example.apk_sipahal/.MainActivity
```

Untuk versi rilis (tanpa debug, lebih kecil):

```bash
flutter build apk --release
```

---

## 8. Tangkapan layar aplikasi

Ada di folder `screenshots\` (hasil uji di emulator Android 14):

| File | Isi |
|------|-----|
| `01-opening.png` | Halaman pembuka |
| `02-role.png` | Pilih jenis akun |
| `03-login.png` | Login + isi akun demo |
| `04-warga-map.png` | Peta titik sampah + tombol Buat Laporan |
| `05-laporan-saya.png` | Daftar laporan warga |
| `06-detail.png` | Detail laporan + peta + timeline |
| `07-admin-dashboard.png` | Dashboard admin + sebaran titik |
| `08-verifikasi.png` | Verifikasi laporan |
| `09-penugasan.png` | Daftar siap ditugaskan |
| `10-pilih-petugas.png` | Pilih petugas |
| `11-petugas-tugas.png` | Daftar tugas petugas |
| `12-petugas-mulai.png` | Konfirmasi mulai tugas |
| `13-petugas-selesaikan.png` | Form selesaikan tugas |
| `14-petugas-selesai.png` | Laporan berstatus selesai |
| `15-notifikasi.png` | Notifikasi perubahan status |
| `16-profil.png` | Profil warga |
| `17-buat-laporan.png` | Form laporan + GPS |
| `18-pilih-titik.png` | Pilih titik manual di peta |
| `20-profil-admin.png` | Profil admin |
| `21-laporan-terkirim.png` | Laporan baru masuk peta |
| `22-petugas-rina.png` | Tugas untuk petugas kedua |

---

## 9. Status pengujian

Sudah diuji langsung di emulator (`Medium_Phone`, Android 14):

- Login & logout untuk 3 peran, termasuk validasi peran salah.
- Warga membuat laporan baru: GPS → deskripsi → kirim → muncul di peta & daftar
  dengan status `menunggu`.
- Admin memverifikasi laporan baru, lalu menugaskannya ke petugas.
- Petugas menerima tugas, menekan **Mulai** (`dikerjakan`), lalu **Selesaikan**
  dengan catatan (`selesai`).
- Timeline riwayat status dan halaman Notifikasi ikut terbarui.
- `flutter analyze` bersih dan `flutter test` lulus (2 test alur status).

Bukti pemetaan tiap indikator penilaian (data/backend, async, persistence, auth, evidence):
`docs/RUBRIK_PHASE3.md`.

