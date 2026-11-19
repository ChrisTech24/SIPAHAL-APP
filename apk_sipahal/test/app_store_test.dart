import 'package:apk_sipahal/data/app_store.dart';
import 'package:apk_sipahal/models/models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('alur status laporan berjalan sesuai PRD', () async {
    SharedPreferences.setMockInitialValues({});
    final store = AppStore.instance;
    await store.init();

    final warga = await store.signIn('warga@sipahal.com', 'warga123');
    expect(warga.role, Role.warga);

    final reportId = (await store.createReport(
      CreateReportInput(
        reporterId: warga.uid,
        reporterName: warga.name,
        location: const LocationData(
          address: 'Jalan Merdeka, dekat Tugu Sirih',
          latitude: 0.9189,
          longitude: 104.4468,
        ),
        category: 'Sampah rumah tangga',
        description: 'Sampah menumpuk di pinggir jalan dan mulai berbau.',
      ),
    ))
        .id;

    Report byId() => store.reports.firstWhere((r) => r.id == reportId);
    expect(byId().status, ReportStatus.menunggu);

    final admin = await store.signIn('admin@sipahal.com', 'admin123');
    expect(admin.role, Role.admin);

    await store.verifyReport(reportId, admin.uid);
    expect(byId().status, ReportStatus.diverifikasi);

    final petugas = await store.signIn('petugas@sipahal.com', 'petugas123');
    await store.assignReport(reportId, petugas.uid, admin.uid);
    expect(byId().status, ReportStatus.ditugaskan);
    expect(byId().assignedOfficerId, petugas.uid);

    await store.startAssignment(reportId, petugas.uid);
    expect(byId().status, ReportStatus.dikerjakan);

    await store.completeAssignment(
      reportId,
      petugas.uid,
      'Sampah sudah diangkut ke TPS dan area dibersihkan.',
    );
    expect(byId().status, ReportStatus.selesai);
    expect(byId().history.length, 5);

    expect(
      store.reportsFor(petugas).any((r) => r.id == reportId),
      isTrue,
    );
    expect(
      store.reportsFor(warga).any((r) => r.id == reportId),
      isTrue,
    );
  });

  test('penolakan wajib memiliki alasan', () async {
    SharedPreferences.setMockInitialValues({});
    final store = AppStore.instance;
    final report = store.reports.firstWhere(
      (r) => r.status == ReportStatus.menunggu,
    );
    expect(
      () => store.rejectReport(report.id, 'u-admin', '   '),
      throwsA(isA<Exception>()),
    );
  });
}
