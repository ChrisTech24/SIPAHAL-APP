import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';

import '../core/theme.dart';
import '../data/app_store.dart';
import '../models/models.dart';
import '../services/services.dart';
import '../widgets/common.dart';
import '../widgets/map_widgets.dart';
import 'report_detail.dart';
import 'shared.dart';

class WargaShell extends StatefulWidget {
  const WargaShell({super.key});

  @override
  State<WargaShell> createState() => _WargaShellState();
}

class _WargaShellState extends State<WargaShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      const WargaMapPage(),
      const MyReportsPage(),
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
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map_rounded),
            label: 'Peta',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long_rounded),
            label: 'Laporan',
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

class WargaMapPage extends StatelessWidget {
  const WargaMapPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AppStore.instance;
    final user = store.currentUser;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final reports = store.reports;
        final mine = reports.where((r) => r.reporterId == user?.uid).length;
        final active = reports.where((r) => r.status.isActive).length;
        return Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: ReportMap(
                reports: reports,
                bottomInset: 84,
                onReportTap: (report) => _showReportSheet(context, report),
              ),
            ),
            SafeArea(
              child: Align(
                alignment: Alignment.topCenter,
                child: Padding(
                padding: const EdgeInsets.all(14),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(15, 14, 15, 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.10),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          const AppLogo(size: 38, light: false),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Peta titik sampah',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.navy,
                                  ),
                                ),
                                Text(
                                  '${reports.length} laporan · $active masih aktif',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: AppColors.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.pale,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '$mine milikmu',
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.navy,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            for (final status in ReportStatus.values) ...[
                              StatusBadge(status, compact: true),
                              const SizedBox(width: 6),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: PrimaryButton(
                label: 'Buat Laporan',
                icon: Icons.add_a_photo_rounded,
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateReportPage()),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showReportSheet(BuildContext context, Report report) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Laporan ${report.displayId}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy,
                  ),
                ),
                const Spacer(),
                StatusBadge(report.status, compact: true),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              report.locationText,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              report.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.muted,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              label: 'Lihat detail laporan',
              icon: Icons.arrow_forward_rounded,
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ReportDetailPage(report: report),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class MyReportsPage extends StatefulWidget {
  const MyReportsPage({super.key});

  @override
  State<MyReportsPage> createState() => _MyReportsPageState();
}

class _MyReportsPageState extends State<MyReportsPage> {
  ReportStatus? _filter;

  @override
  Widget build(BuildContext context) {
    final store = AppStore.instance;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final user = store.currentUser;
        if (user == null) return const SizedBox.shrink();
        final all = store.reportsFor(user);
        final data = _filter == null
            ? all
            : all.where((r) => r.status == _filter).toList();
        return Column(
          children: [
            AppHeader(
              title: 'Laporan Saya',
              subtitle: '${all.length} laporan tercatat',
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
                  ? EmptyState(
                      icon: Icons.receipt_long_outlined,
                      title: 'Belum ada laporan',
                      message: _filter == null
                          ? 'Laporkan titik sampah liar di sekitarmu lewat menu Peta.'
                          : 'Tidak ada laporan dengan status ${_filter!.label}.',
                      actionLabel: _filter == null ? 'Buat laporan' : null,
                      onAction: _filter == null
                          ? () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const CreateReportPage(),
                                ),
                              )
                          : null,
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
                      children: [
                        for (final report in data)
                          ReportCard(
                            report: report,
                            showReporter: false,
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

class CreateReportPage extends StatefulWidget {
  const CreateReportPage({super.key});

  @override
  State<CreateReportPage> createState() => _CreateReportPageState();
}

class _CreateReportPageState extends State<CreateReportPage> {
  final _description = TextEditingController();
  final _address = TextEditingController();
  final _reportService = ReportService();
  final _picker = ImagePicker();

  String _category = reportCategories.first;
  LocationData? _location;
  Uint8List? _photo;
  bool _locating = false;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _description.dispose();
    _address.dispose();
    super.dispose();
  }

  Future<void> _useGps() async {
    setState(() {
      _locating = true;
      _error = null;
    });
    try {
      final data = await LocationService().getCurrentLocation();
      if (!mounted) return;
      _setLocation(data);
    } on LocationFailure catch (failure) {
      if (!mounted) return;
      setState(() => _error = failure.message);
      if (failure.canOpenSettings) {
        final open = await confirmDialog(
          context,
          title: 'Aktifkan izin lokasi',
          message: 'Buka pengaturan aplikasi untuk mengizinkan akses lokasi?',
          confirmLabel: 'Buka pengaturan',
        );
        if (open) await Geolocator.openAppSettings();
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = 'Gagal mengambil GPS: $error');
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _pickOnMap() async {
    final result = await Navigator.push<LocationData>(
      context,
      MaterialPageRoute(
        builder: (_) => MapPickerPage(
          initial: _location == null
              ? null
              : LatLng(_location!.latitude, _location!.longitude),
        ),
      ),
    );
    if (result != null) _setLocation(result);
  }

  void _setLocation(LocationData data) {
    setState(() {
      _location = data;
      _error = null;
      if (_address.text.trim().isEmpty) {
        _address.text =
            'Titik peta ${data.latitude.toStringAsFixed(5)}, ${data.longitude.toStringAsFixed(5)}';
      }
    });
  }

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final file = await _picker.pickImage(
        source: source,
        maxWidth: 1280,
        imageQuality: 70,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() => _photo = bytes);
    } catch (error) {
      if (!mounted) return;
      showSnack(context, 'Gagal mengambil foto: $error', error: true);
    }
  }

  void _choosePhotoSource() {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 26),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Lampirkan foto',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.navy,
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.photo_camera_rounded),
              title: const Text('Ambil dari kamera'),
              onTap: () {
                Navigator.pop(context);
                _pickPhoto(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('Pilih dari galeri'),
              onTap: () {
                Navigator.pop(context);
                _pickPhoto(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final user = AppStore.instance.currentUser;
    final description = _description.text.trim();
    final address = _address.text.trim();

    if (_location == null) {
      setState(() => _error =
          'Lokasi wajib diisi. Ambil GPS atau pilih titik di peta.');
      return;
    }
    if (address.isEmpty) {
      setState(() => _error = 'Alamat/patokan lokasi wajib diisi.');
      return;
    }
    if (description.length < 10) {
      setState(() => _error = 'Deskripsi minimal 10 karakter.');
      return;
    }
    if (user == null) return;

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      String? photoData;
      if (_photo != null) {
        photoData = await _reportService.uploadReportPhoto(
          'new',
          _photo!,
          'report',
        );
      }
      await _reportService.createReport(
        CreateReportInput(
          reporterId: user.uid,
          reporterName: user.name,
          location: LocationData(
            address: address,
            latitude: _location!.latitude,
            longitude: _location!.longitude,
          ),
          category: _category,
          description: description,
          photoData: photoData,
        ),
      );
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      showSnackWith(messenger, 'Laporan terkirim. Status awal: menunggu.');
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
    return Scaffold(
      appBar: AppBar(title: const Text('Buat Laporan')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
        children: [
          const SectionTitle('Foto kondisi (opsional)'),
          InkWell(
            onTap: _choosePhotoSource,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              height: 168,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.line),
              ),
              clipBehavior: Clip.antiAlias,
              child: _photo == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: const BoxDecoration(
                            color: AppColors.bg,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.add_a_photo_rounded,
                            color: AppColors.navy,
                            size: 26,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Ketuk untuk menambah foto',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.navy,
                          ),
                        ),
                        const Text(
                          'Kamera atau galeri',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    )
                  : Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.memory(_photo!, fit: BoxFit.cover),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Material(
                            color: Colors.black.withValues(alpha: 0.5),
                            shape: const CircleBorder(),
                            child: IconButton(
                              onPressed: () => setState(() => _photo = null),
                              icon: const Icon(
                                Icons.close_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          const SectionTitle('Kategori sampah'),
          DropdownButtonFormField<String>(
            initialValue: _category,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.category_outlined, size: 19),
            ),
            items: [
              for (final category in reportCategories)
                DropdownMenuItem(value: category, child: Text(category)),
            ],
            onChanged: (value) =>
                setState(() => _category = value ?? _category),
          ),
          const SectionTitle('Deskripsi'),
          TextField(
            controller: _description,
            minLines: 3,
            maxLines: 5,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText:
                  'Contoh: sampah menumpuk di pinggir jalan sejak 3 hari lalu dan mulai berbau.',
            ),
          ),
          const SectionTitle('Lokasi'),
          CardBox(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_location != null) ...[
                  LocationPreview(location: _location!),
                  const SizedBox(height: 12),
                ] else
                  Container(
                    padding: const EdgeInsets.all(14),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: AppColors.bg,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.gps_not_fixed_rounded,
                          color: AppColors.teal,
                          size: 20,
                        ),
                        SizedBox(width: 9),
                        Expanded(
                          child: Text(
                            'Belum ada titik. Ambil lokasi GPS atau pilih manual di peta.',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: AppColors.muted,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                Row(
                  children: [
                    Expanded(
                      child: PrimaryButton(
                        label: 'Ambil GPS',
                        icon: Icons.gps_fixed_rounded,
                        outlined: true,
                        loading: _locating,
                        onPressed: _useGps,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: PrimaryButton(
                        label: 'Pilih di peta',
                        icon: Icons.map_rounded,
                        outlined: true,
                        onPressed: _pickOnMap,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _address,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Alamat / patokan lokasi',
                    hintText: 'Contoh: Jalan Merdeka, dekat Tugu Sirih',
                    prefixIcon: Icon(Icons.place_outlined, size: 19),
                  ),
                ),
              ],
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.red.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _error!,
                style: const TextStyle(
                  color: AppColors.red,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),
          PrimaryButton(
            label: 'Kirim Laporan',
            icon: Icons.send_rounded,
            loading: _saving,
            onPressed: _submit,
          ),
          const SizedBox(height: 8),
          const Text(
            'Laporan akan masuk ke admin DLH dengan status "menunggu".',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}
