# PRD untuk AI Agent (Frontend) SIPAHAL

## Tujuan
Membangun UI Flutter sesuai Figma dan mengintegrasikan service backend serta maps.

## Halaman
### Warga
Opening, role selection, login, register, peta, buat laporan, laporan saya, detail laporan, notifikasi, profil.

### Petugas
Login, daftar tugas, detail tugas, mulai tugas, upload bukti, riwayat, notifikasi, profil.

### Admin
Login, dashboard, verifikasi, tolak + alasan, penugasan, monitoring, backup placeholder, profil.

## Alur
```text
Warga membuat laporan -> menunggu
Admin verifikasi -> diverifikasi
Admin tugaskan -> ditugaskan
Petugas mulai -> dikerjakan
Petugas selesai -> selesai
Admin menolak -> ditolak + alasan
```

## Integrasi
- Gunakan AuthService, ReportService, AssignmentService, dan StorageService dari backend.
- Gunakan LocationService, MapPicker, dan ReportMap dari agent maps.
- Jangan menulis query Firebase langsung di setiap widget.
- Mock service boleh digunakan sementara dengan kontrak yang sama.

## UI wajib
Loading, empty, error, validasi form, success feedback, status badge, timeline, dan responsive admin web.

## Acceptance criteria
- Role menuju halaman yang benar.
- Warga mengirim laporan dengan LocationData.
- Data alur utama berasal dari service, bukan hardcode.
- Admin dapat verifikasi, menolak, dan menugaskan.
- Petugas dapat mulai dan menyelesaikan tugas.
- Warga melihat status terbaru.

## Batasan
Jangan mengubah nama collection, field, status, atau signature service tanpa koordinasi.

## Output
Halaman Flutter, widget reusable, navigasi role, integrasi service, loading/error/empty state, dan panduan menjalankan demo.
