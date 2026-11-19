import 'package:flutter/material.dart';

import '../models/models.dart';

const _monthNames = <String>[
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'Mei',
  'Jun',
  'Jul',
  'Agu',
  'Sep',
  'Okt',
  'Nov',
  'Des',
];

String formatDate(DateTime date) =>
    '${date.day} ${_monthNames[date.month - 1]} ${date.year}';

String formatDateTime(DateTime date) {
  final hh = date.hour.toString().padLeft(2, '0');
  final mm = date.minute.toString().padLeft(2, '0');
  return '${formatDate(date)} • $hh:$mm';
}

String timeAgo(DateTime date) {
  final diff = DateTime.now().difference(date);
  if (diff.inMinutes < 1) return 'baru saja';
  if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
  if (diff.inHours < 24) return '${diff.inHours} jam lalu';
  if (diff.inDays < 7) return '${diff.inDays} hari lalu';
  return formatDate(date);
}

IconData roleIcon(Role role) => switch (role) {
      Role.warga => Icons.person_rounded,
      Role.petugas => Icons.engineering_rounded,
      Role.admin => Icons.admin_panel_settings_rounded,
    };
