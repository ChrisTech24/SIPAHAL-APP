# Panduan Reproduksi & Integration Evidence — SIPAHAL (Phase 3)

Dokumen ini berisi panduan menjalankan backend (`sipahal-api`) dan aplikasi mobile Flutter (`apk_sipahal`) serta langkah reproduksi pengujian integrasi end-to-end.

## Prasyarat Lingkungan
- **Backend (`sipahal-api`)**: PHP, Composer, Laravel, dan database yang sudah dikonfigurasi di `.env` serta dimigrasi.
- **Frontend (`apk_sipahal`)**: Flutter SDK, emulator Android / perangkat uji, dan paket dependensi (`flutter pub get`).

## Cara Menjalankan Backend (`sipahal-api`)
1. Buka terminal/Command Prompt di folder `sipahal-api`.
2. Pastikan konfigurasi `.env` dan database sudah sesuai.
3. Jalankan server API agar dapat diakses dari emulator Android (`10.0.2.2:8000/api`):
   ```bash
   php artisan serve --host=0.0.0.0 --port=8000