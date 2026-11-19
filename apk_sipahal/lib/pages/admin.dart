import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../data/app_store.dart';
import '../models/models.dart';
import '../services/services.dart';
import '../widgets/common.dart';
import '../widgets/map_widgets.dart';
import 'report_detail.dart';
import 'shared.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _index = 0;

  static const _labels = <String>[
    'Dashboard',
    'Verifikasi',
    'Penugasan',
    'Monitoring',
  ];

  static const _icons = <IconData>[
    Icons.dashboard_outlined,
    Icons.fact_check_outlined,
    Icons.assignment_ind_outlined,
    Icons.monitor_heart_outlined,
  ];

  static const _selectedIcons = <IconData>[
    Icons.dashboard_rounded,
    Icons.fact_check_rounded,
    Icons.assignment_ind_rounded,
    Icons.monitor_heart_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      const AdminDashboardPage(),
      const VerificationPage(),
      const AssignmentPage(),
      const MonitoringPage(),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;

        if (wide) {
          // Admin dipakai di web/desktop: pakai navigation rail dan batasi lebar
          // konten agar tetap nyaman dibaca di layar lebar.
          return Scaffold(
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: _index,
                  onDestinationSelected: (i) => setState(() => _index = i),
                  labelType: NavigationRailLabelType.all,
                  backgroundColor: Colors.white,
                  indicatorColor: AppColors.pale,
                  selectedIconTheme: const IconThemeData(color: AppColors.navy),
                  unselectedIconTheme: const IconThemeData(
                    color: AppColors.muted,
                  ),
                  selectedLabelTextStyle: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.navy,
                  ),
                  unselectedLabelTextStyle: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.muted,
                  ),
                  leading: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: AppLogo(size: 40, light: false),
                  ),
                  destinations: [
                    for (var i = 0; i < _labels.length; i++)
                      NavigationRailDestination(
                        icon: Icon(_icons[i]),
                        selectedIcon: Icon(_selectedIcons[i]),
                        label: Text(_labels[i]),
                      ),
                  ],
                ),
                const VerticalDivider(width: 1, color: AppColors.line),
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 900),
                      child: IndexedStack(index: _index, children: pages),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return Scaffold(
          body: IndexedStack(index: _index, children: pages),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard_rounded),
                label: 'Dashboard',
              ),
              NavigationDestination(
                icon: Icon(Icons.fact_check_outlined),
                selectedIcon: Icon(Icons.fact_check_rounded),
                label: 'Verifikasi',
              ),
              NavigationDestination(
                icon: Icon(Icons.assignment_ind_outlined),
                selectedIcon: Icon(Icons.assignment_ind_rounded),
                label: 'Penugasan',
              ),
              NavigationDestination(
                icon: Icon(Icons.monitor_heart_outlined),
                selectedIcon: Icon(Icons.monitor_heart_rounded),
                label: 'Monitoring',
              ),
            ],
          ),
        );
      },
    );
  }
}

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AppStore.instance;
    final user = store.currentUser;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final reports = store.reports;
        int count(ReportStatus s) => reports.where((r) => r.status == s).length;
        final recent = reports.take(4).toList();
        return Column(
          children: [
            AppHeader(
              title: 'Dashboard Admin',
              subtitle: 'Halo, ${user?.name ?? 'Admin'} · DLH',
              actions: [
                IconButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfilePage()),
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: AppColors.line),
                  ),
                  icon: const Icon(Icons.person_outline_rounded, size: 20),
                ),
              ],
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: StatCard(
                          label: 'Menunggu',
                          value: count(ReportStatus.menunggu),
                          icon: Icons.schedule_rounded,
                          tint: const Color(0xFFFFF1CF),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: StatCard(
                          label: 'Diverifikasi',
                          value: count(ReportStatus.diverifikasi),
                          icon: Icons.verified_rounded,
                          tint: const Color(0xFFD9F0FF),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: StatCard(
                          label: 'Dikerjakan',
                          value: count(ReportStatus.dikerjakan),
                          icon: Icons.engineering_rounded,
                          tint: const Color(0xFFD6F5EC),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: StatCard(
                          label: 'Selesai',
                          value: count(ReportStatus.selesai),
                          icon: Icons.check_circle_rounded,
                          tint: const Color(0xFFDDF3C9),
                        ),
                      ),
                    ],
                  ),
                  const SectionTitle(
                    'Sebaran titik laporan',
                    trailing: Icon(
                      Icons.layers_rounded,
                      size: 18,
                      color: AppColors.teal,
                    ),
                  ),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: SizedBox(
                      height: 210,
                      child: ReportMap(
                        reports: reports,
                        initialZoom: 12.8,
                        interactive: false,
                        onReportTap: (report) => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ReportDetailPage(report: report),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SectionTitle(
                    'Laporan terbaru',
                    trailing: TextButton(
                      onPressed: () {},
                      child: Text(
                        '${reports.length} total',
                        style: const TextStyle(fontSize: 11.5),
                      ),
                    ),
                  ),
                  if (recent.isEmpty)
                    const CardBox(
                      child: Text(
                        'Belum ada laporan masuk.',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: AppColors.muted,
                        ),
                      ),
                    )
                  else
                    for (final report in recent)
                      ReportCard(
                        report: report,
                        showReporter: true,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ReportDetailPage(report: report),
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

class VerificationPage extends StatelessWidget {
  const VerificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AppStore.instance;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final pending = store.reports
            .where((r) => r.status == ReportStatus.menunggu)
            .toList();
        return Column(
          children: [
            AppHeader(
              title: 'Verifikasi Laporan',
              subtitle: '${pending.length} laporan menunggu',
            ),
            Expanded(
              child: pending.isEmpty
                  ? const EmptyState(
                      icon: Icons.fact_check_outlined,
                      title: 'Semua sudah diverifikasi',
                      message: 'Laporan baru dari warga akan muncul di sini untuk diperiksa.',
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
                      children: [
                        for (final report in pending)
                          ReportCard(
                            report: report,
                            showReporter: true,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    ReportDetailPage(report: report),
                              ),
                            ),
                            actions: [
                              PrimaryButton(
                                label: 'Verifikasi',
                                icon: Icons.check_rounded,
                                onPressed: () =>
                                    verify(context, report, store.currentUser!),
                              ),
                              PrimaryButton(
                                label: 'Tolak',
                                outlined: true,
                                onPressed: () =>
                                    reject(context, report, store.currentUser!),
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

  Future<void> verify(
    BuildContext context,
    Report report,
    AppUser admin,
  ) async {
    final ok = await confirmDialog(
      context,
      title: 'Verifikasi laporan?',
      message:
          'Laporan ${report.displayId} akan berstatus "diverifikasi" dan siap ditugaskan ke petugas.',
      confirmLabel: 'Verifikasi',
    );
    if (!ok || !context.mounted) return;
    try {
      await ReportService().verifyReport(report.id, admin.uid);
      if (!context.mounted) return;
      showSnack(context, 'Laporan ${report.displayId} diverifikasi.');
    } catch (error) {
      if (!context.mounted) return;
      showSnack(context, '$error', error: true);
    }
  }

  Future<void> reject(
    BuildContext context,
    Report report,
    AppUser admin,
  ) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tolak laporan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Alasan penolakan wajib diisi dan akan terlihat oleh warga.',
              style: TextStyle(fontSize: 12.5, color: AppColors.muted),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              minLines: 3,
              maxLines: 4,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Contoh: bukan titik sampah liar / duplikat laporan.',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.red,
              minimumSize: const Size(0, 44),
              padding: const EdgeInsets.symmetric(horizontal: 18),
            ),
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Tolak laporan'),
          ),
        ],
      ),
    );
    if (reason == null || reason.isEmpty) {
      if (context.mounted) {
        showSnack(context, 'Alasan penolakan wajib diisi.', error: true);
      }
      return;
    }
    if (!context.mounted) return;
    try {
      await ReportService().rejectReport(report.id, admin.uid, reason);
      if (!context.mounted) return;
      showSnack(context, 'Laporan ${report.displayId} ditolak.');
    } catch (error) {
      if (!context.mounted) return;
      showSnack(context, '$error', error: true);
    }
  }
}

class AssignmentPage extends StatelessWidget {
  const AssignmentPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AppStore.instance;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final verified = store.reports
            .where((r) => r.status == ReportStatus.diverifikasi)
            .toList();
        return Column(
          children: [
            AppHeader(
              title: 'Penugasan Petugas',
              subtitle: '${verified.length} laporan siap ditugaskan',
            ),
            Expanded(
              child: verified.isEmpty
                  ? const EmptyState(
                      icon: Icons.assignment_ind_outlined,
                      title: 'Belum ada yang perlu ditugaskan',
                      message: 'Verifikasi laporan terlebih dahulu, lalu tugaskan ke petugas DLH.',
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
                      children: [
                        for (final report in verified)
                          ReportCard(
                            report: report,
                            showReporter: true,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    ReportDetailPage(report: report),
                              ),
                            ),
                            actions: [
                              PrimaryButton(
                                label: 'Tugaskan',
                                icon: Icons.person_add_alt_1_rounded,
                                onPressed: () => showAssignSheet(
                                  context,
                                  report,
                                  store.currentUser!,
                                ),
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

Future<void> showAssignSheet(
  BuildContext context,
  Report report,
  AppUser admin,
) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _AssignSheet(report: report, admin: admin),
  );
}

class _AssignSheet extends StatefulWidget {
  const _AssignSheet({required this.report, required this.admin});

  final Report report;
  final AppUser admin;

  @override
  State<_AssignSheet> createState() => _AssignSheetState();
}

class _AssignSheetState extends State<_AssignSheet> {
  String? _officerId;
  bool _saving = false;
  String? _error;

  void _submit(AppStore store) async {
    if (_officerId == null) {
      setState(() => _error = 'Pilih petugas terlebih dahulu.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ReportService().assignReport(
        widget.report.id,
        _officerId!,
        widget.admin.uid,
      );
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      showSnackWith(messenger, 'Laporan ditugaskan ke petugas.');
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
    final store = AppStore.instance;
    final officers = store.officers;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) => Padding(
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
              const Text(
                'Pilih petugas',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navy,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${widget.report.displayId} · ${widget.report.locationText}',
                style: const TextStyle(fontSize: 12, color: AppColors.muted),
              ),
              const SizedBox(height: 14),
              if (officers.isEmpty)
                const Text(
                  'Belum ada akun petugas aktif.',
                  style: TextStyle(fontSize: 12.5, color: AppColors.red),
                )
              else
                for (final officer in officers)
                  _OfficerTile(
                    officer: officer,
                    activeTasks: store.reports
                        .where(
                          (r) =>
                              r.assignedOfficerId == officer.uid &&
                              r.status.isActive,
                        )
                        .length,
                    selected: _officerId == officer.uid,
                    onTap: () => setState(() {
                      _officerId = officer.uid;
                      _error = null;
                    }),
                  ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(
                  _error!,
                  style: const TextStyle(color: AppColors.red, fontSize: 12),
                ),
              ],
              const SizedBox(height: 16),
              PrimaryButton(
                label: 'Tugaskan sekarang',
                icon: Icons.assignment_turned_in_rounded,
                loading: _saving,
                onPressed: () => _submit(store),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OfficerTile extends StatelessWidget {
  const _OfficerTile({
    required this.officer,
    required this.activeTasks,
    required this.selected,
    required this.onTap,
  });

  final AppUser officer;
  final int activeTasks;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: selected ? AppColors.bg : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? AppColors.teal : AppColors.line,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 19,
                backgroundColor: AppColors.pale,
                child: Text(
                  officer.name.isEmpty ? '?' : officer.name[0].toUpperCase(),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy,
                  ),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      officer.name,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '$activeTasks tugas aktif · ${officer.phone}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                color: selected ? AppColors.teal : AppColors.line,
                size: 21,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MonitoringPage extends StatefulWidget {
  const MonitoringPage({super.key});

  @override
  State<MonitoringPage> createState() => _MonitoringPageState();
}

class _MonitoringPageState extends State<MonitoringPage> {
  ReportStatus? _filter;

  @override
  Widget build(BuildContext context) {
    final store = AppStore.instance;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final all = store.reports;
        final data = _filter == null
            ? all
            : all.where((r) => r.status == _filter).toList();
        return Column(
          children: [
            AppHeader(
              title: 'Monitoring Laporan',
              subtitle: '${all.length} laporan · ${data.length} ditampilkan',
            ),
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                children: [
                  _FilterChip(
                    label: 'Semua',
                    selected: _filter == null,
                    onTap: () => setState(() => _filter = null),
                  ),
                  for (final status in ReportStatus.values)
                    _FilterChip(
                      label: status.label,
                      selected: _filter == status,
                      onTap: () => setState(() => _filter = status),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: data.isEmpty
                  ? const EmptyState(
                      icon: Icons.filter_alt_off_rounded,
                      title: 'Tidak ada data',
                      message: 'Belum ada laporan dengan status ini.',
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
                      children: [
                        for (final report in data)
                          ReportCard(
                            report: report,
                            showReporter: true,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    ReportDetailPage(report: report),
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

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: selected ? AppColors.navy : Colors.white,
        borderRadius: BorderRadius.circular(30),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(30),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: selected ? AppColors.navy : AppColors.line,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : AppColors.muted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
