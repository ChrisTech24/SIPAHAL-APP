import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../core/theme.dart';
import '../models/models.dart';
import '../services/services.dart';
import 'common.dart';

const _tileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
const _userAgent = 'com.example.apk_sipahal';

const _mapInteractiveFlags = InteractiveFlag.drag |
    InteractiveFlag.pinchZoom |
    InteractiveFlag.doubleTapZoom |
    InteractiveFlag.scrollWheelZoom;

/// Peta marker laporan. Hanya menampilkan data; tidak menulis database.
class ReportMap extends StatefulWidget {
  const ReportMap({
    super.key,
    required this.reports,
    this.onReportTap,
    this.initialCenter,
    this.initialZoom = 13.5,
    this.interactive = true,
    this.showAttribution = true,
    this.bottomInset = 12,
  });

  final List<Report> reports;
  final ValueChanged<Report>? onReportTap;
  final LatLng? initialCenter;
  final double initialZoom;
  final bool interactive;
  final bool showAttribution;
  final double bottomInset;

  @override
  State<ReportMap> createState() => _ReportMapState();
}

class _ReportMapState extends State<ReportMap> {
  final _controller = MapController();

  LatLng get _center {
    if (widget.initialCenter != null) return widget.initialCenter!;
    final valid = widget.reports.where((r) => r.hasValidCoordinates).toList();
    if (valid.isEmpty) return LocationService.fallbackCenter;
    return LatLng(valid.first.latitude, valid.first.longitude);
  }

  void _zoomBy(double delta) {
    final camera = _controller.camera;
    final nextZoom = (camera.zoom + delta).clamp(3.0, 19.0);
    _controller.move(camera.center, nextZoom);
  }

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: _controller,
      options: MapOptions(
        initialCenter: _center,
        initialZoom: widget.initialZoom,
        minZoom: 3,
        maxZoom: 19,
        backgroundColor: const Color(0xFFE8EFE2),
        interactionOptions: InteractionOptions(
          flags: widget.interactive
              ? _mapInteractiveFlags
              : InteractiveFlag.none,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: _tileUrl,
          userAgentPackageName: _userAgent,
          maxNativeZoom: 19,
        ),
        MarkerLayer(
          markers: [
            for (final report in widget.reports)
              if (report.hasValidCoordinates)
                Marker(
                  point: LatLng(report.latitude, report.longitude),
                  width: 46,
                  height: 60,
                  alignment: Alignment.topCenter,
                  child: _ReportPin(
                    report: report,
                    onTap: widget.onReportTap == null
                        ? null
                        : () => widget.onReportTap!(report),
                  ),
                ),
          ],
        ),
        if (widget.showAttribution)
          const RichAttributionWidget(
            alignment: AttributionAlignment.bottomLeft,
            showFlutterMapAttribution: false,
            attributions: [
              TextSourceAttribution('OpenStreetMap contributors'),
            ],
          ),
        if (widget.interactive)
          Positioned(
            right: 12,
            bottom: widget.bottomInset,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _MapButton(
                  icon: Icons.add_rounded,
                  onTap: () => _zoomBy(1),
                ),
                const SizedBox(height: 8),
                _MapButton(
                  icon: Icons.remove_rounded,
                  onTap: () => _zoomBy(-1),
                ),
                const SizedBox(height: 8),
                _MapButton(
                  icon: Icons.my_location_rounded,
                  onTap: () => _controller.move(_center, 15),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ReportPin extends StatelessWidget {
  const _ReportPin({required this.report, this.onTap});

  final Report report;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = report.status.textColor;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.22),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(report.status.icon, size: 19, color: Colors.white),
          ),
          Icon(Icons.arrow_drop_down_rounded, size: 18, color: color),
        ],
      ),
    );
  }
}

class _MapButton extends StatelessWidget {
  const _MapButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 2,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(9),
          child: Icon(icon, size: 20, color: AppColors.navy),
        ),
      ),
    );
  }
}

/// Halaman pemilihan titik manual di peta.
class MapPickerPage extends StatefulWidget {
  const MapPickerPage({super.key, this.initial, this.title = 'Pilih lokasi'});

  final LatLng? initial;
  final String title;

  @override
  State<MapPickerPage> createState() => _MapPickerPageState();
}

class _MapPickerPageState extends State<MapPickerPage> {
  final _controller = MapController();
  LatLng? _picked;
  bool _locating = false;

  @override
  void initState() {
    super.initState();
    _picked = widget.initial;
  }

  void _zoomBy(double delta) {
    final camera = _controller.camera;
    final nextZoom = (camera.zoom + delta).clamp(3.0, 19.0);
    _controller.move(camera.center, nextZoom);
  }

  Future<void> _useGps() async {
    setState(() => _locating = true);
    try {
      final data = await LocationService().getCurrentLocation();
      if (!mounted) return;
      final point = LatLng(data.latitude, data.longitude);
      setState(() => _picked = point);
      _controller.move(point, 16.5);
    } on LocationFailure catch (failure) {
      if (!mounted) return;
      showSnack(context, failure.message, error: true);
    } catch (error) {
      if (!mounted) return;
      showSnack(context, 'Gagal mengambil lokasi: $error', error: true);
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          FlutterMap(
            mapController: _controller,
            options: MapOptions(
              initialCenter: _picked ?? LocationService.fallbackCenter,
              initialZoom: _picked == null ? 13.5 : 16.5,
              minZoom: 3,
              maxZoom: 19,
              backgroundColor: const Color(0xFFE8EFE2),
              interactionOptions: const InteractionOptions(
                flags: _mapInteractiveFlags,
              ),
              onTap: (_, point) => setState(() => _picked = point),
            ),
            children: [
              TileLayer(
                urlTemplate: _tileUrl,
                userAgentPackageName: _userAgent,
                maxNativeZoom: 19,
              ),
              if (_picked != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _picked!,
                      width: 46,
                      height: 60,
                      alignment: Alignment.topCenter,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.navy,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                            ),
                            child: const Icon(
                              Icons.place_rounded,
                              color: Colors.white,
                              size: 21,
                            ),
                          ),
                          const Icon(
                            Icons.arrow_drop_down_rounded,
                            size: 18,
                            color: AppColors.navy,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              const RichAttributionWidget(
                alignment: AttributionAlignment.bottomLeft,
                showFlutterMapAttribution: false,
                attributions: [
                  TextSourceAttribution('OpenStreetMap contributors'),
                ],
              ),
            ],
          ),
          Positioned(
            right: 12,
            bottom: 168,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _MapButton(
                  icon: Icons.add_rounded,
                  onTap: () => _zoomBy(1),
                ),
                const SizedBox(height: 8),
                _MapButton(
                  icon: Icons.remove_rounded,
                  onTap: () => _zoomBy(-1),
                ),
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Material(
                    color: Colors.white,
                    shape: const CircleBorder(),
                    elevation: 2,
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_rounded, size: 20),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Text(
                        widget.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.navy,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _picked == null
                          ? 'Ketuk peta untuk menandai titik sampah'
                          : 'Titik dipilih',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.navy,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _picked == null
                          ? 'Atau pakai lokasi GPS kamu sekarang.'
                          : '${_picked!.latitude.toStringAsFixed(6)}, ${_picked!.longitude.toStringAsFixed(6)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.muted,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: PrimaryButton(
                            label: 'Lokasi GPS',
                            icon: Icons.gps_fixed_rounded,
                            outlined: true,
                            loading: _locating,
                            onPressed: _useGps,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: PrimaryButton(
                            label: 'Pakai titik',
                            icon: Icons.check_rounded,
                            onPressed: _picked == null
                                ? null
                                : () => Navigator.pop(
                                      context,
                                      LocationData(
                                        address: '',
                                        latitude: _picked!.latitude,
                                        longitude: _picked!.longitude,
                                      ),
                                    ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Kartu ringkas lokasi: alamat, koordinat, dan peta mini.
class LocationPreview extends StatelessWidget {
  const LocationPreview({
    super.key,
    required this.location,
    this.height = 150,
    this.trailing,
    this.onOpenMap,
  });

  final LocationData location;
  final double height;
  final Widget? trailing;
  final VoidCallback? onOpenMap;

  @override
  Widget build(BuildContext context) {
    final hasCoords = location.latitude != 0 || location.longitude != 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: height,
            child: hasCoords
                ? FlutterMap(
                    options: MapOptions(
                      initialCenter: LatLng(
                        location.latitude,
                        location.longitude,
                      ),
                      initialZoom: 16,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.none,
                      ),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: _tileUrl,
                        userAgentPackageName: _userAgent,
                        maxNativeZoom: 19,
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: LatLng(
                              location.latitude,
                              location.longitude,
                            ),
                            width: 40,
                            height: 54,
                            alignment: Alignment.topCenter,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    color: AppColors.navy,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2.5,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.place_rounded,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                                const Icon(
                                  Icons.arrow_drop_down_rounded,
                                  size: 16,
                                  color: AppColors.navy,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  )
                : Container(
                    color: const Color(0xFFE8EFE2),
                    alignment: Alignment.center,
                    child: const Text(
                      'Koordinat belum tersedia',
                      style: TextStyle(color: AppColors.muted, fontSize: 12),
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.place_rounded,
              size: 17,
              color: AppColors.teal,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    location.address.isEmpty
                        ? 'Titik peta'
                        : location.address,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    location.coordinates,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            ?trailing,
            if (onOpenMap != null)
              IconButton(
                onPressed: onOpenMap,
                tooltip: 'Buka peta',
                icon: const Icon(Icons.open_in_new_rounded, size: 19),
              ),
          ],
        ),
      ],
    );
  }
}