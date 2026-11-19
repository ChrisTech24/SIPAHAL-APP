import 'dart:convert';

import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../core/utils.dart';
import '../models/models.dart';
import '../services/services.dart';
import '../widgets/common.dart';
import '../widgets/map_widgets.dart';

class ReportDetailPage extends StatelessWidget {
  const ReportDetailPage({
    super.key,
    required this.report,
    this.showReporter = true,
    this.footer,
  });

  final Report report;
  final bool showReporter;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Laporan ${report.displayId}')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
        children: [
          CardBox(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    StatusBadge(report.status),
                    const Spacer(),
                    Text(
                      timeAgo(report.updatedAt),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  report.description,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _Chip(
                      icon: Icons.category_outlined,
                      label: report.category,
                    ),
                    _Chip(
                      icon: Icons.place_outlined,
                      label: report.locationText,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SectionTitle('Lokasi kejadian'),
          CardBox(
            child: LocationPreview(
              location: report.location,
              height: 160,
              onOpenMap: () => _navigate(context),
            ),
          ),
          if (report.photoData != null) ...[
            const SectionTitle('Foto laporan'),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: ReportPhoto(data: report.photoData!, height: 210),
            ),
          ],
          if (report.status == ReportStatus.ditolak &&
              report.rejectionReason != null) ...[
            const SectionTitle('Alasan penolakan'),
            CardBox(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: AppColors.red,
                    size: 19,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      report.rejectionReason!,
                      style: const TextStyle(
                        fontSize: 12.5,
                        height: 1.45,
                        color: AppColors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (report.assignment?.workNote != null) ...[
            const SectionTitle('Catatan petugas'),
            CardBox(
              child: Text(
                report.assignment!.workNote!,
                style: const TextStyle(fontSize: 12.5, height: 1.45),
              ),
            ),
          ],
          const SectionTitle('Informasi laporan'),
          CardBox(
            child: Column(
              children: [
                if (showReporter)
                  InfoRow(
                    label: 'Pelapor',
                    value: report.reporterName,
                    icon: Icons.person_outline_rounded,
                  ),
                InfoRow(
                  label: 'Petugas',
                  value: report.assignedOfficerName ?? 'Belum ditugaskan',
                  icon: Icons.engineering_outlined,
                ),
                InfoRow(
                  label: 'Dibuat',
                  value: formatDateTime(report.createdAt),
                  icon: Icons.schedule_rounded,
                ),
                InfoRow(
                  label: 'Diperbarui',
                  value: formatDateTime(report.updatedAt),
                  icon: Icons.update_rounded,
                ),
                InfoRow(
                  label: 'Koordinat',
                  value: report.location.coordinates,
                  icon: Icons.gps_fixed_rounded,
                ),
              ],
            ),
          ),
          const SectionTitle('Riwayat status'),
          StatusTimeline(report: report),
          if (footer != null) ...[const SizedBox(height: 18), footer!],
        ],
      ),
    );
  }

  Future<void> _navigate(BuildContext context) async {
    try {
      await LocationService().openNavigation(
        latitude: report.latitude,
        longitude: report.longitude,
        label: report.locationText,
      );
    } catch (error) {
      if (!context.mounted) return;
      showSnack(
        context,
        'Tidak bisa membuka aplikasi peta: $error',
        error: true,
      );
    }
  }
}

class ReportPhoto extends StatelessWidget {
  const ReportPhoto({
    super.key,
    required this.data,
    this.height = 180,
    this.width,
  });

  final String data;
  final double height;
  final double? width;

  @override
  Widget build(BuildContext context) {
    // Foto dari Firebase Storage berupa URL https; foto demo berupa base64.
    if (data.startsWith('http://') || data.startsWith('https://')) {
      return Image.network(
        data,
        height: height,
        width: width,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
            height: height,
            width: width,
            color: const Color(0xFFE8EFE2),
            alignment: Alignment.center,
            child: const CircularProgressIndicator(strokeWidth: 2.4),
          );
        },
        errorBuilder: (_, _, _) => _placeholder(),
      );
    }
    try {
      final bytes = base64Decode(data);
      return Image.memory(
        bytes,
        height: height,
        width: width,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _placeholder(),
      );
    } catch (_) {
      return _placeholder();
    }
  }

  Widget _placeholder() => Container(
    height: height,
    width: width,
    color: const Color(0xFFE8EFE2),
    alignment: Alignment.center,
    child: const Icon(
      Icons.broken_image_outlined,
      color: AppColors.muted,
      size: 34,
    ),
  );
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 240),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.teal),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.text,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
