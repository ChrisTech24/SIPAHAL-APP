# PRD untuk AI Agent (Maps & Geolocation) SIPAHAL

## Tujuan
Menyediakan GPS, pemilihan lokasi pada peta, marker laporan, dan navigasi petugas tanpa mengubah database/status.

## Scope
- Permission lokasi.
- Mengambil lokasi saat ini.
- Memilih titik manual.
- Marker laporan.
- Peta warga, petugas, dan admin.
- Navigasi eksternal.
- Fallback alamat manual.

## Kontrak data
```dart
class LocationData {
  final String address;
  final double latitude;
  final double longitude;
  const LocationData({required this.address, required this.latitude, required this.longitude});
}
```

## Public API
```dart
Future<LocationData> getCurrentLocation();
Future<LocationData?> pickLocation();
Future<void> openNavigation({required double latitude, required double longitude});
```

Widget yang disediakan: `MapPicker`, `ReportMap`, `LocationPreview`.

## Perilaku
- Tampilkan loading saat GPS dimuat.
- Tangani permission ditolak tanpa crash.
- Sediakan input manual sebagai fallback.
- Marker memakai latitude/longitude dari ReportModel.
- Klik marker membuka ringkasan laporan.
- Widget maps hanya mengembalikan LocationData; tidak menulis database langsung.

## Acceptance criteria
- GPS mengembalikan koordinat valid.
- Permission denied tertangani.
- User dapat memilih lokasi manual.
- Marker laporan tampil.
- Petugas dapat membuka navigasi.
- API key/permission didokumentasikan.

## Batasan
Jangan mengubah Firebase collection, status, login, atau UI utama tanpa koordinasi.

## Output
LocationService, MapPicker/ReportMap, konfigurasi permission/API key, dan panduan testing emulator/device.
