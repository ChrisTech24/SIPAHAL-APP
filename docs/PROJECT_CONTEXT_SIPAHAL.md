# Project Context SIPAHAL

## Tujuan
SIPAHAL adalah aplikasi pelaporan dan pemetaan titik pembuangan sampah liar. Warga membuat laporan dengan lokasi, foto, kategori, dan deskripsi. Admin memverifikasi dan menugaskan laporan. Petugas menangani lokasi dan mengunggah bukti sampai selesai.

## Platform
- Flutter mobile: warga dan petugas.
- Flutter web/desktop: admin.
- Backend: Firebase sesuai proposal.
- Maps: GPS/geolocation dan peta digital.

## Role
- warga: membuat dan memantau laporan.
- petugas: menerima, mengerjakan, dan menyelesaikan tugas.
- admin: verifikasi, penolakan, penugasan, dan monitoring.

## Status resmi
`menunggu`, `diverifikasi`, `ditugaskan`, `dikerjakan`, `selesai`, `ditolak`.

Transisi:
`menunggu -> diverifikasi -> ditugaskan -> dikerjakan -> selesai` atau `menunggu -> ditolak`.

## Data lokasi resmi
```text
locationText: String
latitude: double
longitude: double
```

## Aturan kerja
- Backend tidak mengubah UI tanpa koordinasi.
- Maps tidak mengubah database/status.
- Frontend tidak mengubah nama field/kontrak.
- Semua agent membaca file ini sebelum coding.
- Jika konfigurasi belum tersedia, laporkan; jangan mengarang.
