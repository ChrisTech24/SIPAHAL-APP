import 'package:flutter/material.dart';

import '../data/app_store.dart';
import '../models/models.dart';
import 'admin.dart';
import 'opening.dart';
import 'petugas.dart';
import 'warga.dart';

Widget homeForUser(AppUser user) => switch (user.role) {
      Role.warga => const WargaShell(),
      Role.petugas => const PetugasShell(),
      Role.admin => const AdminShell(),
    };

void goHome(BuildContext context) {
  final user = AppStore.instance.currentUser;
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(
      builder: (_) => user == null ? const OpeningPage() : homeForUser(user),
    ),
    (_) => false,
  );
}

void goOpening(BuildContext context) {
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const OpeningPage()),
    (_) => false,
  );
}
