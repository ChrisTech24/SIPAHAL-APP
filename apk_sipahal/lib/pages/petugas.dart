import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../core/theme.dart';
import '../data/app_store.dart';
import '../models/models.dart';
import '../services/services.dart';
import '../widgets/common.dart';
import 'report_detail.dart';
import 'shared.dart';

class PetugasShell extends StatefulWidget {
  const PetugasShell({super.key});

  @override
  State<PetugasShell> createState() => _PetugasShellState();
}

class _PetugasShellState extends State<PetugasShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      const TaskListPage(),
      const TaskHistoryPage(),
      const NotificationsPage(),
      const ProfilePage(),
    ];
    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment_rounded),
            label: 'Tugas',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_rounded),
            selectedIcon: Icon(Icons.history_rounded),
            label: 'Riwayat',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_none_rounded),
            selectedIcon: Icon(Icons.notifications_rounded),
            label: 'Notifikasi',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}

class TaskListPage extends StatelessWidget {
  const TaskListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AppStore.instance;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final user = store.currentUser;
        if (user == null) return const SizedBox.shrink();
        final all = store.reportsFor(user);
        final active = all.where((r) => r.status.isActive || r.status == ReportStatus.dikerjakan).toList();
        final todo = all.where((r) => r.status == ReportStatus.ditugaskan).length;
        final working =
            all.where((r) => r.status == ReportStatus.dikerjakan).length;
        return Column(
          children: [
            AppHeader(
              title: 'Daftar Tugas',
              subtitle: '${user.name} · Petugas DLH',
              actions: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.pale,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${active.length} aktif',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.navy,
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Row(
                children: [
                  Expanded(
                    child: StatCard(
                      label: 'Belum dimulai',
                      value: todo,
                      icon: Icons.pending_actions_rounded,
                      tint: const Color(0xFFE4E9FF),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: StatCard(
                      label: 'Sedang dikerjakan',
                      value: working,
                      icon: Icons.engineering_rounded,
                      tint: const Color(0xFFD6F5EC),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: active.isEmpty
                  ? const EmptyState(
                      icon: Icons.assignment_turned_in_outlined,
                      title: 'Tidak ada tugas aktif',
                      message:
                          'Tugas baru dari admin akan muncul di sini. Cek menu Riwayat untuk tugas yang sudah selesai.',
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
                      children: [
                        for (final report in active)
                          ReportCard(
                            report: report,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    TaskDetailPage(reportId: report.id),
                              ),
                            ),
                            actions: [
                              if (report.status == ReportStatus.ditugaskan)
                                PrimaryButton(
                                  label: 'Mulai',
                                  icon: Icons.play_arrow_rounded,
                                  onPressed: () =>
                                      startTask(context, report),
                                ),
                              if (report.status == ReportStatus.dikerjakan)
                                PrimaryButton(
                                  label: 'Selesaikan',
                                  icon: Icons.check_rounded,
                                  onPressed: () =>
                                      completeTask(context, report),
                                ),
                            ],
                          ),
                      ],
                    ),
            ),
          ],
        );
      },
    );
  }
}

class TaskHistoryPage extends StatelessWidget {
  const TaskHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AppStore.instance;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final user = store.currentUser;
        if (user == null) return const SizedBox.shrink();
        final done = store
            .reportsFor(user)
            .where((r) => r.status == ReportStatus.selesai)
            .toList();
        return Column(
          children: [
            AppHeader(
              title: 'Riwayat Tugas',
              subtitle: '${done.length} tugas selesai',
            ),
            Expanded(
              child: done.isEmpty
                  ? const EmptyState(
                      icon: Icons.history_rounded,
                      title: 'Belum ada riwayat',
                      message:
                          'Tugas yang sudah diselesaikan akan tersimpan di sini.',
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
                      children: [
                        for (final report in done)
                          ReportCard(
                            report: report,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ReportDetailPage(
                                  report: report,
                                  showReporter: true,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
            ),
          ],
        );
      },
    );
  }
}

class TaskDetailPage extends StatelessWidget {
  const TaskDetailPage({super.key, required this.reportId});

  final String reportId;

  @override
  Widget build(BuildContext context) {
    final store = AppStore.instance;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        Report? report;
        for (final r in store.reports) {
          if (r.id == reportId) report = r;
        }
        if (report == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Detail Tugas')),
            body: const EmptyState(
              icon: Icons.search_off_rounded,
              title: 'Tugas tidak ditemukan',
              message: 'Data tugas mungkin sudah dihapus.',
            ),
          );
        }
        return ReportDetailPage(
          report: report,
          footer: Column(
            children: [
              if (report.status == ReportStatus.ditugaskan)
                PrimaryButton(
                  label: 'Mulai Tugas',
                  icon: Icons.play_arrow_rounded,
                  onPressed: () => startTask(context, report!),
                ),
              if (report.status == ReportStatus.dikerjakan)
                PrimaryButton(
                  label: 'Selesaikan Tugas',
                  icon: Icons.check_circle_rounded,
                  onPressed: () => completeTask(context, report!),
                ),
              if (report.status.isActive &&
                  report.status != ReportStatus.ditugaskan &&
                  report.status != ReportStatus.dikerjakan)
                const CardBox(
                  child: Text(
                    'Tugas ini belum bisa dikerjakan. Tunggu penugasan dari admin DLH.',
                    style: TextStyle(fontSize: 12.5, color: AppColors.muted),
                  ),
                ),
              if (report.status == ReportStatus.selesai)
                const CardBox(
                  child: Row(
                    children: [
                      Icon(
                        Icons.verified_rounded,
                        color: AppColors.teal,
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Tugas sudah selesai. Terima kasih!',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

Future<void> startTask(BuildContext context, Report report) async {
  final user = AppStore.instance.currentUser;
  if (user == null) return;
  final ok = await confirmDialog(
    context,
    title: 'Mulai tugas?',
    message:
        'Status laporan ${report.displayId} akan berubah menjadi "dikerjakan".',
    confirmLabel: 'Mulai sekarang',
  );
  if (!ok || !context.mounted) return;
  try {
    await ReportService().startAssignment(report.id, user.uid);
    if (!context.mounted) return;
    showSnack(context, 'Tugas dimulai. Status: dikerjakan.');
  } catch (error) {
    if (!context.mounted) return;
    showSnack(
      context,
      error.toString().replaceFirst('Exception: ', ''),
      error: true,
    );
  }
}

Future<void> completeTask(BuildContext context, Report report) async {
  final user = AppStore.instance.currentUser;
  if (user == null) return;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _CompleteSheet(report: report, officerId: user.uid),
  );
}

class _CompleteSheet extends StatefulWidget {
  const _CompleteSheet({required this.report, required this.officerId});

  final Report report;
  final String officerId;

  @override
  State<_CompleteSheet> createState() => _CompleteSheetState();
}

class _CompleteSheetState extends State<_CompleteSheet> {
  final _note = TextEditingController();
  final _picker = ImagePicker();
  Uint8List? _proof;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickProof() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1280,
      imageQuality: 70,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    setState(() => _proof = bytes);
  }

  Future<void> _submit() async {
    final note = _note.text.trim();
    if (note.length < 5) {
      setState(() => _error = 'Catatan pekerjaan minimal 5 karakter.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      String? proof;
      if (_proof != null) {
        proof = await ReportService().uploadReportPhoto(
          widget.report.id,
          _proof!,
          'proof',
        );
      }
      await ReportService().completeAssignment(
        widget.report.id,
        widget.officerId,
        note,
        proofPath: proof,
      );
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      showSnackWith(messenger, 'Tugas selesai. Laporan sudah diperbarui.');
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString().replaceFirst('Exception: ', '');
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        4,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Selesaikan ${widget.report.displayId}',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.navy,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.report.locationText,
              style: const TextStyle(fontSize: 12, color: AppColors.muted),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _note,
              minLines: 3,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Catatan pekerjaan',
                hintText:
                    'Contoh: sampah sudah diangkut ke TPS, area dibersihkan.',
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _pickProof,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.bg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.line),
                ),
                clipBehavior: Clip.antiAlias,
                child: _proof == null
                    ? const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_photo_alternate_outlined,
                            color: AppColors.teal,
                            size: 26,
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Lampirkan bukti foto (opsional)',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      )
                    : Image.memory(_proof!, fit: BoxFit.cover),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(
                _error!,
                style: const TextStyle(color: AppColors.red, fontSize: 12),
              ),
            ],
            const SizedBox(height: 16),
            PrimaryButton(
              label: 'Tandai Selesai',
              icon: Icons.check_circle_rounded,
              loading: _saving,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
