import 'package:flutter/material.dart';

/// Role pengguna sesuai PROJECT_CONTEXT_SIPAHAL.md
enum Role {
  warga('warga', 'Warga / Pelapor'),
  petugas('petugas', 'Petugas DLH'),
  admin('admin', 'Admin DLH');

  const Role(this.id, this.label);

  final String id;
  final String label;

  static Role fromId(String? id) =>
      Role.values.firstWhere((r) => r.id == id, orElse: () => Role.warga);
}

/// Status resmi (hanya enam ini yang boleh dipakai).
enum ReportStatus {
  menunggu('menunggu', 'Menunggu'),
  diverifikasi('diverifikasi', 'Diverifikasi'),
  ditugaskan('ditugaskan', 'Ditugaskan'),
  dikerjakan('dikerjakan', 'Dikerjakan'),
  selesai('selesai', 'Selesai'),
  ditolak('ditolak', 'Ditolak');

  const ReportStatus(this.id, this.label);

  final String id;
  final String label;

  static ReportStatus fromId(String? id) {
    final normalized = id?.trim().toLowerCase();
    if (normalized == 'terverifikasi' || normalized == 'diverifikasi') {
      return ReportStatus.diverifikasi;
    }
    return ReportStatus.values.firstWhere(
      (s) => s.id == normalized,
      orElse: () => ReportStatus.menunggu,
    );
  }

  bool get isActive =>
      this == menunggu ||
      this == diverifikasi ||
      this == ditugaskan ||
      this == dikerjakan;

  Color get color => switch (this) {
    menunggu => const Color(0xFFFFF1CF),
    diverifikasi => const Color(0xFFD9F0FF),
    ditugaskan => const Color(0xFFE4E9FF),
    dikerjakan => const Color(0xFFD6F5EC),
    selesai => const Color(0xFFDDF3C9),
    ditolak => const Color(0xFFFFE1E1),
  };

  Color get textColor => switch (this) {
    menunggu => const Color(0xFF8A5B00),
    diverifikasi => const Color(0xFF0B5C87),
    ditugaskan => const Color(0xFF2A3E9E),
    dikerjakan => const Color(0xFF0B6B57),
    selesai => const Color(0xFF2F6B17),
    ditolak => const Color(0xFFA32020),
  };

  IconData get icon => switch (this) {
    menunggu => Icons.schedule_rounded,
    diverifikasi => Icons.verified_rounded,
    ditugaskan => Icons.assignment_ind_rounded,
    dikerjakan => Icons.engineering_rounded,
    selesai => Icons.check_circle_rounded,
    ditolak => Icons.cancel_rounded,
  };
}

/// Kontrak lokasi resmi: locationText + latitude + longitude.
class LocationData {
  const LocationData({
    required this.address,
    required this.latitude,
    required this.longitude,
  });

  final String address;
  final double latitude;
  final double longitude;

  String get coordinates =>
      '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';

  Map<String, dynamic> toJson() => {
    'address': address,
    'latitude': latitude,
    'longitude': longitude,
  };

  factory LocationData.fromJson(Map<String, dynamic> json) => LocationData(
    address: (json['address'] ?? '') as String,
    latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
    longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
  );
}

class AppUser {
  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.isActive = true,
    required this.createdAt,
    this.password = '',
  });

  final String uid;
  final String name;
  final String email;
  final String phone;
  final Role role;
  final bool isActive;
  final DateTime createdAt;

  /// Hanya untuk demo lokal (nanti diganti Firebase Authentication).
  final String password;

  AppUser copyWith({String? name, String? phone}) => AppUser(
    uid: uid,
    name: name ?? this.name,
    email: email,
    phone: phone ?? this.phone,
    role: role,
    isActive: isActive,
    createdAt: createdAt,
    password: password,
  );

  Map<String, dynamic> toJson() => {
    'uid': uid,
    'name': name,
    'email': email,
    'phone': phone,
    'role': role.id,
    'isActive': isActive,
    'createdAt': createdAt.toIso8601String(),
    'password': password,
  };

  /// Dokumen Firestore: kata sandi tidak pernah ikut dikirim ke server.
  Map<String, dynamic> toPublicJson() => {
    'uid': uid,
    'name': name,
    'email': email,
    'phone': phone,
    'role': role.id,
    'isActive': isActive,
    'createdAt': createdAt.toIso8601String(),
  };

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
    uid: json['uid'] as String,
    name: json['name'] as String? ?? '',
    email: json['email'] as String? ?? '',
    phone: json['phone'] as String? ?? '',
    role: Role.fromId(json['role'] as String?),
    isActive: json['isActive'] as bool? ?? true,
    createdAt:
        DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    password: json['password'] as String? ?? '',
  );
}

class StatusHistoryEntry {
  const StatusHistoryEntry({
    required this.id,
    required this.reportId,
    required this.fromStatus,
    required this.toStatus,
    required this.changedBy,
    required this.changedByName,
    required this.createdAt,
    this.note,
  });

  final String id;
  final String reportId;
  final ReportStatus? fromStatus;
  final ReportStatus toStatus;
  final String changedBy;
  final String changedByName;
  final String? note;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'reportId': reportId,
    'fromStatus': fromStatus?.id,
    'toStatus': toStatus.id,
    'changedBy': changedBy,
    'changedByName': changedByName,
    'note': note,
    'createdAt': createdAt.toIso8601String(),
  };

  factory StatusHistoryEntry.fromJson(Map<String, dynamic> json) =>
      StatusHistoryEntry(
        id: json['id'] as String,
        reportId: json['reportId'] as String? ?? '',
        fromStatus: json['fromStatus'] == null
            ? null
            : ReportStatus.fromId(json['fromStatus'] as String?),
        toStatus: ReportStatus.fromId(json['toStatus'] as String?),
        changedBy: json['changedBy'] as String? ?? '',
        changedByName: json['changedByName'] as String? ?? '',
        note: json['note'] as String?,
        createdAt:
            DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.now(),
      );
}

class Assignment {
  const Assignment({
    required this.id,
    required this.reportId,
    required this.officerId,
    required this.assignedBy,
    required this.status,
    required this.assignedAt,
    this.startedAt,
    this.completedAt,
    this.workNote,
    this.proofPhotoPath,
  });

  final String id;
  final String reportId;
  final String officerId;
  final String assignedBy;
  final ReportStatus status;
  final DateTime assignedAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final String? workNote;
  final String? proofPhotoPath;

  Assignment copyWith({
    ReportStatus? status,
    DateTime? startedAt,
    DateTime? completedAt,
    String? workNote,
    String? proofPhotoPath,
  }) => Assignment(
    id: id,
    reportId: reportId,
    officerId: officerId,
    assignedBy: assignedBy,
    status: status ?? this.status,
    assignedAt: assignedAt,
    startedAt: startedAt ?? this.startedAt,
    completedAt: completedAt ?? this.completedAt,
    workNote: workNote ?? this.workNote,
    proofPhotoPath: proofPhotoPath ?? this.proofPhotoPath,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'reportId': reportId,
    'officerId': officerId,
    'assignedBy': assignedBy,
    'status': status.id,
    'assignedAt': assignedAt.toIso8601String(),
    'startedAt': startedAt?.toIso8601String(),
    'completedAt': completedAt?.toIso8601String(),
    'workNote': workNote,
    'proofPhotoPath': proofPhotoPath,
  };

  factory Assignment.fromJson(Map<String, dynamic> json) => Assignment(
    id: json['id'] as String,
    reportId: json['reportId'] as String? ?? '',
    officerId: json['officerId'] as String? ?? '',
    assignedBy: json['assignedBy'] as String? ?? '',
    status: ReportStatus.fromId(json['status'] as String?),
    assignedAt:
        DateTime.tryParse(json['assignedAt'] as String? ?? '') ??
        DateTime.now(),
    startedAt: DateTime.tryParse(json['startedAt'] as String? ?? ''),
    completedAt: DateTime.tryParse(json['completedAt'] as String? ?? ''),
    workNote: json['workNote'] as String?,
    proofPhotoPath: json['proofPhotoPath'] as String?,
  );
}

class Report {
  const Report({
    required this.id,
    required this.displayId,
    required this.reporterId,
    required this.reporterName,
    required this.locationText,
    required this.latitude,
    required this.longitude,
    required this.category,
    required this.description,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.rejectionReason,
    this.assignedOfficerId,
    this.assignedOfficerName,
    this.photoData,
    this.assignment,
    this.history = const [],
  });

  final String id;
  final String displayId;
  final String reporterId;
  final String reporterName;
  final String locationText;
  final double latitude;
  final double longitude;
  final String category;
  final String description;
  final ReportStatus status;
  final String? rejectionReason;
  final String? assignedOfficerId;
  final String? assignedOfficerName;
  final String? photoData;
  final Assignment? assignment;
  final List<StatusHistoryEntry> history;
  final DateTime createdAt;
  final DateTime updatedAt;

  LocationData get location => LocationData(
    address: locationText,
    latitude: latitude,
    longitude: longitude,
  );

  bool get hasValidCoordinates =>
      latitude != 0 && longitude != 0 && latitude.abs() <= 90;

  Report copyWith({
    ReportStatus? status,
    String? rejectionReason,
    String? assignedOfficerId,
    String? assignedOfficerName,
    String? photoData,
    Assignment? assignment,
    List<StatusHistoryEntry>? history,
    DateTime? updatedAt,
    String? locationText,
    double? latitude,
    double? longitude,
    String? description,
    String? category,
  }) => Report(
    id: id,
    displayId: displayId,
    reporterId: reporterId,
    reporterName: reporterName,
    locationText: locationText ?? this.locationText,
    latitude: latitude ?? this.latitude,
    longitude: longitude ?? this.longitude,
    category: category ?? this.category,
    description: description ?? this.description,
    status: status ?? this.status,
    rejectionReason: rejectionReason ?? this.rejectionReason,
    assignedOfficerId: assignedOfficerId ?? this.assignedOfficerId,
    assignedOfficerName: assignedOfficerName ?? this.assignedOfficerName,
    photoData: photoData ?? this.photoData,
    assignment: assignment ?? this.assignment,
    history: history ?? this.history,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'displayId': displayId,
    'reporterId': reporterId,
    'reporterName': reporterName,
    'locationText': locationText,
    'latitude': latitude,
    'longitude': longitude,
    'category': category,
    'description': description,
    'status': status.id,
    'rejectionReason': rejectionReason,
    'assignedOfficerId': assignedOfficerId,
    'assignedOfficerName': assignedOfficerName,
    'photoData': photoData,
    'assignment': assignment?.toJson(),
    'history': history.map((h) => h.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory Report.fromJson(Map<String, dynamic> json) => Report(
    id: json['id'] as String,
    displayId: json['displayId'] as String? ?? '',
    reporterId: json['reporterId'] as String? ?? '',
    reporterName: json['reporterName'] as String? ?? '',
    locationText: json['locationText'] as String? ?? '',
    latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
    longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
    category: json['category'] as String? ?? 'Sampah lainnya',
    description: json['description'] as String? ?? '',
    status: ReportStatus.fromId(json['status'] as String?),
    rejectionReason: json['rejectionReason'] as String?,
    assignedOfficerId: json['assignedOfficerId'] as String?,
    assignedOfficerName: json['assignedOfficerName'] as String?,
    photoData: json['photoData'] as String?,
    assignment: json['assignment'] == null
        ? null
        : Assignment.fromJson(json['assignment'] as Map<String, dynamic>),
    history: ((json['history'] as List?) ?? [])
        .map((e) => StatusHistoryEntry.fromJson(e as Map<String, dynamic>))
        .toList(),
    createdAt:
        DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    updatedAt:
        DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? DateTime.now(),
  );
}

/// Kategori laporan yang dipakai di form.
const reportCategories = <String>[
  'Sampah rumah tangga',
  'Sampah plastik',
  'Sampah konstruksi',
  'Sampah organik',
  'Sampah lainnya',
];

/// Input untuk [ReportService.createReport].
class CreateReportInput {
  const CreateReportInput({
    required this.reporterId,
    required this.reporterName,
    required this.location,
    required this.category,
    required this.description,
    this.photoData,
  });

  final String reporterId;
  final String reporterName;
  final LocationData location;
  final String category;
  final String description;
  final String? photoData;
}

/// Pesan error lokasi yang aman ditampilkan ke pengguna.
class LocationFailure implements Exception {
  const LocationFailure(this.message, {this.canOpenSettings = false});

  final String message;
  final bool canOpenSettings;

  @override
  String toString() => message;
}