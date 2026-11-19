import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../core/utils.dart';
import '../data/app_store.dart';
import '../models/models.dart';
import '../services/services.dart';
import '../widgets/common.dart';
import 'home_router.dart';
import 'report_detail.dart';

class _NotificationItem {
  const _NotificationItem({required this.report, required this.entry});

  final Report report;
  final StatusHistoryEntry entry;
}

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AppStore.instance;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final user = store.currentUser;
        if (user == null) return const SizedBox.shrink();
        final items = <_NotificationItem>[];
        for (final report in store.reportsFor(user)) {
          for (final entry in report.history) {
            if (entry.changedBy != user.uid) {
              items.add(_NotificationItem(report: report, entry: entry));
            }
          }
        }
        items.sort((a, b) => b.entry.createdAt.compareTo(a.entry.createdAt));

        return Column(
          children: [
            AppHeader(
              title: 'Notifikasi',
              subtitle: '${items.length} pembaruan status',
            ),
            Expanded(
              child: items.isEmpty
                  ? const EmptyState(
                      icon: Icons.notifications_none_rounded,
                      title: 'Belum ada notifikasi',
                      message: 'Setiap perubahan status laporan akan muncul di sini.',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return Material(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ReportDetailPage(
                                  report: item.report,
                                  showReporter: user.role != Role.warga,
                                ),
                              ),
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(13),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.line),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: item.entry.toStatus.color,
                                      borderRadius: BorderRadius.circular(11),
                                    ),
                                    child: Icon(
                                      item.entry.toStatus.icon,
                                      size: 19,
                                      color: item.entry.toStatus.textColor,
                                    ),
                                  ),
                                  const SizedBox(width: 11),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                'Laporan ${item.report.displayId} · ${item.entry.toStatus.label}',
                                                style: const TextStyle(
                                                  fontSize: 12.5,
                                                  fontWeight: FontWeight.w800,
                                                  color: AppColors.navy,
                                                ),
                                              ),
                                            ),
                                            Text(
                                              timeAgo(item.entry.createdAt),
                                              style: const TextStyle(
                                                fontSize: 10,
                                                color: AppColors.muted,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          item.entry.note?.isNotEmpty == true
                                              ? item.entry.note!
                                              : 'Status diperbarui oleh ${item.entry.changedByName}.',
                                          style: const TextStyle(
                                            fontSize: 11.5,
                                            color: AppColors.muted,
                                            height: 1.4,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          item.report.locationText,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 10.5,
                                            color: AppColors.teal,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AppStore.instance;
    final user = store.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Belum masuk')));
    }
    final myReports = store.reportsFor(user);
    final finished = myReports
        .where((r) => r.status == ReportStatus.selesai)
        .length;

    return Material(
      color: AppColors.bg,
      child: Column(
        children: [
          AppHeader(
            title: 'Profil',
            subtitle: 'Akun ${user.role.label}',
            showBack: Navigator.of(context).canPop(),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 4, 18, 28),
              children: [
                CardBox(
                  child: Column(
                    children: [
                      Container(
                        width: 76,
                        height: 76,
                        decoration: const BoxDecoration(
                          color: AppColors.pale,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          user.name.isEmpty ? '?' : user.name[0].toUpperCase(),
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            color: AppColors.navy,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        user.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.navy,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.bg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.line),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              roleIcon(user.role),
                              size: 13,
                              color: AppColors.teal,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              user.role.label,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.navy,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _MiniStat(
                              label: user.role == Role.petugas
                                  ? 'Total tugas'
                                  : 'Total laporan',
                              value: '${myReports.length}',
                            ),
                          ),
                          Expanded(
                            child: _MiniStat(
                              label: 'Selesai',
                              value: '$finished',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SectionTitle('Informasi akun'),
                CardBox(
                  child: Column(
                    children: [
                      InfoRow(
                        label: 'Email',
                        value: user.email,
                        icon: Icons.mail_outline_rounded,
                      ),
                      InfoRow(
                        label: 'Nomor HP',
                        value: user.phone.isEmpty ? '-' : user.phone,
                        icon: Icons.phone_outlined,
                      ),
                      InfoRow(
                        label: 'Bergabung',
                        value: formatDate(user.createdAt),
                        icon: Icons.calendar_today_rounded,
                      ),
                      InfoRow(
                        label: 'Status akun',
                        value: user.isActive ? 'Aktif' : 'Nonaktif',
                        icon: Icons.verified_user_outlined,
                        valueColor: user.isActive
                            ? AppColors.teal
                            : AppColors.red,
                      ),
                      InfoRow(
                        label: 'Penyimpanan data',
                        value: store.usingFirebase
                            ? 'Firebase (cloud)'
                            : 'Lokal (demo)',
                        icon: Icons.cloud_outlined,
                        valueColor: store.usingFirebase
                            ? AppColors.teal
                            : AppColors.muted,
                      ),
                    ],
                  ),
                ),
                const SectionTitle('Aplikasi'),
                CardBox(
                  child: Column(
                    children: [
                      _MenuTile(
                        icon: Icons.info_outline_rounded,
                        title: 'Tentang SIPAHAL',
                        subtitle: 'Versi demo 1.0 · Flutter',
                        onTap: () => showDialog<void>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('SIPAHAL'),
                            content: Text(
                              'Sistem Informasi Pelaporan & Pemetaan Titik Pembuangan Sampah Liar.\n\n'
                              '${store.usingFirebase ? 'Data tersimpan di Firebase: Authentication, Cloud Firestore, dan Storage.' : 'Prototipe ini memakai data lokal (mock service) dengan kontrak yang sama seperti Firebase. Pasang google-services.json untuk mengaktifkan Firebase.'}\n\n'
                              'Peta memakai OpenStreetMap.',
                              style: const TextStyle(
                                fontSize: 12.5,
                                height: 1.5,
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Tutup'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (user.role == Role.admin)
                        _MenuTile(
                          icon: Icons.backup_outlined,
                          title: 'Backup data',
                          subtitle: 'Segera hadir (placeholder PRD)',
                          onTap: () => showSnack(
                            context,
                            'Fitur backup akan tersedia setelah Firebase aktif.',
                          ),
                        ),
                      if (!store.usingFirebase)
                        _MenuTile(
                          icon: Icons.restart_alt_rounded,
                          title: 'Reset data demo',
                          subtitle: 'Kembalikan laporan & akun contoh',
                          onTap: () async {
                            final ok = await confirmDialog(
                              context,
                              title: 'Reset data demo?',
                              message: 'Semua laporan baru akan dihapus dan data contoh dimuat ulang.',
                              confirmLabel: 'Reset',
                              danger: true,
                            );
                            if (!ok || !context.mounted) return;
                            await store.resetDemoData();
                            if (!context.mounted) return;
                            goOpening(context);
                          },
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                PrimaryButton(
                  label: 'Keluar',
                  icon: Icons.logout_rounded,
                  outlined: true,
                  onPressed: () async {
                    final ok = await confirmDialog(
                      context,
                      title: 'Keluar dari akun?',
                      message: 'Kamu perlu masuk lagi untuk mengakses laporan.',
                      confirmLabel: 'Keluar',
                    );
                    if (!ok || !context.mounted) return;
                    await AuthService().signOut();
                    if (!context.mounted) return;
                    goOpening(context);
                  },
                ),
                const SizedBox(height: 14),
                const Text(
                  'SIPAHAL · Pemrograman Perangkat Bergerak\nUniversitas Maritim Raja Ali Haji',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10.5,
                    color: AppColors.muted,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.navy,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.muted),
        ),
      ],
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.bg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: AppColors.navy),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: AppColors.muted,
            ),
          ],
        ),
      ),
    );
  }
}
