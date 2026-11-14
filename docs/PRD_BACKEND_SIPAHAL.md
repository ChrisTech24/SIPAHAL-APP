# PRD untuk AI Agent (Backend) SIPAHAL

## Tujuan
Membangun backend Firebase untuk autentikasi, database laporan, penugasan, histori status, dan foto.

## Scope
- Firebase Authentication email/password.
- Cloud Firestore.
- Firebase Storage.
- Role warga, petugas, admin.
- Service Dart dan Security Rules.

## Collection
### USERS
`uid, name, email, phone, role, isActive, createdAt`

### REPORTS
`id, displayId, reporterId, locationText, latitude, longitude, category, description, status, rejectionReason, assignedOfficerId, createdAt, updatedAt`

### ASSIGNMENTS
`id, reportId, officerId, assignedBy, status, assignedAt, startedAt, completedAt, workNote`

### STATUS_HISTORY
`id, reportId, fromStatus, toStatus, changedBy, note, createdAt`

### REPORTS/{reportId}/PHOTOS
`id, storagePath, downloadUrl, type, uploadedBy, createdAt`

## Status
Gunakan hanya: `menunggu`, `diverifikasi`, `ditugaskan`, `dikerjakan`, `selesai`, `ditolak`.

## Public service contract
```dart
Future<UserModel?> signIn(String email, String password);
Future<void> signOut();
Future<String> createReport(CreateReportInput input);
Stream<List<ReportModel>> watchMyReports(String userId);
Stream<List<ReportModel>> watchPendingReports();
Future<void> verifyReport(String reportId, String adminId);
Future<void> rejectReport(String reportId, String adminId, String reason);
Future<void> assignReport(String reportId, String officerId, String adminId);
Future<void> startAssignment(String reportId, String officerId);
Future<void> completeAssignment(String reportId, String officerId, String note);
Future<String> uploadReportPhoto(String reportId, File file, String type);
```

## Acceptance criteria
- Login valid berhasil dan role terbaca dari USERS.
- Laporan baru berstatus `menunggu`.
- Hanya admin dapat verifikasi, menolak, dan menugaskan.
- Penolakan wajib memiliki alasan.
- Petugas hanya melihat tugas miliknya.
- Semua perubahan status masuk STATUS_HISTORY.
- Foto tersimpan di Storage dan URL di Firestore.
- Rules mencegah warga mengubah status sendiri.

## Output
Model/service Dart, konfigurasi Firebase, rules, seed akun demo, dan instruksi setup/test.

## Batasan
Jangan mengubah widget frontend atau kontrak field/status tanpa koordinasi.
