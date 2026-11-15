import 'package:flutter/material.dart';

void main() => runApp(const SipahalApp());

class C {
  static const navy = Color(0xFF062477);
  static const teal = Color(0xFF159B98);
  static const cyan = Color(0xFF52C5C5);
  static const pale = Color(0xFFDFFFAD);
  static const green = Color(0xFFA8E596);
  static const blue = Color(0xFF3FA4F2);
  static const gray = Color(0xFFD9D9D9);
}

enum Role { warga, petugas, admin }

class Report {
  String id, location, description, status;
  String? rejectionReason;
  Role? assignedTo;
  Report(this.id, this.location, this.description, this.status, {this.assignedTo, this.rejectionReason});
}

final reports = <Report>[
  Report('#0001', 'Jalan Diponegoro', 'Sampah menumpuk di pinggir jalan', 'Menunggu'),
  Report('#0002', 'Jalan Ahmad Yani', 'Tumpukan sampah dekat drainase', 'Diverifikasi', assignedTo: Role.petugas),
  Report('#0003', 'Kampung Bulang', 'Sampah liar di lahan kosong', 'Dikerjakan', assignedTo: Role.petugas),
];

class SipahalApp extends StatelessWidget {
  const SipahalApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'SIPAHAL',
        theme: ThemeData(useMaterial3: true, fontFamily: 'Arial', colorScheme: ColorScheme.fromSeed(seedColor: C.navy)),
        home: const OpeningPage(),
      );
}

class OpeningPage extends StatelessWidget {
  const OpeningPage({super.key});
  @override
  Widget build(BuildContext context) => GradientPage(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Spacer(), const Logo(size: 100), const SizedBox(height: 16),
        const Text('SIPAHAL', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
        const Text('Sistem Informasi Pelaporan\nSampah Liar', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70)),
        const Spacer(),
        Button('Mulai', () => push(context, const RolePage())),
        TextButton(onPressed: () => push(context, const LoginPage(role: Role.warga)), child: const Text('Sudah punya akun? Masuk di sini', style: TextStyle(color: Colors.white))),
        const SizedBox(height: 25),
      ]));
}

class RolePage extends StatelessWidget {
  const RolePage({super.key});
  @override
  Widget build(BuildContext context) => GradientPage(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Logo(size: 76), const SizedBox(height: 20), const Text('Pilih jenis akun', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)), const SizedBox(height: 25),
        Button('Warga / Pelapor', () => push(context, const LoginPage(role: Role.warga))),
        Button('Petugas DLH', () => push(context, const LoginPage(role: Role.petugas))),
        OutlinedButton(onPressed: () => push(context, const LoginPage(role: Role.admin)), child: const Text('Admin DLH', style: TextStyle(color: Colors.white))),
      ]));
}

class LoginPage extends StatefulWidget {
  final Role role;
  const LoginPage({super.key, required this.role});
  @override State<LoginPage> createState() => _LoginPageState();
}
class _LoginPageState extends State<LoginPage> {
  final email = TextEditingController(), password = TextEditingController();
  String message = '';
  String roleName(Role r) => r == Role.warga ? 'Warga / Pelapor' : r == Role.petugas ? 'Petugas DLH' : 'Admin DLH';
  void login() {
    final valid = (widget.role == Role.warga && email.text == 'warga@sipahal.com' && password.text == 'warga123') ||
        (widget.role == Role.petugas && email.text == 'petugas@sipahal.com' && password.text == 'petugas123') ||
        (widget.role == Role.admin && email.text == 'admin@sipahal.com' && password.text == 'admin123');
    if (!valid) { setState(() => message = 'Akun prototype tidak cocok.'); return; }
    final page = widget.role == Role.warga ? const WargaHome() : widget.role == Role.petugas ? const PetugasHome() : const AdminHome();
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => page));
  }
  @override
  Widget build(BuildContext context) => AuthPage(title: 'Masuk sebagai ${roleName(widget.role)}', fields: [
        Input(label: 'Email', controller: email), Input(label: 'Kata Sandi', controller: password, obscure: true)], button: 'Masuk', error: message,
        onSubmit: login, footer: widget.role == Role.admin ? const SizedBox.shrink() : TextButton(onPressed: () => push(context, RegisterPage(role: widget.role)), child: const Text('Belum punya akun? Daftar di sini')));
}

class RegisterPage extends StatelessWidget {
  final Role role;
  const RegisterPage({super.key, required this.role});
  @override
  Widget build(BuildContext context) => AuthPage(title: 'Daftar sebagai ${role == Role.warga ? 'Warga' : 'Petugas'}', fields: const [Input(label: 'Nama Lengkap'), Input(label: 'Email'), Input(label: 'Nomor HP'), Input(label: 'Kata Sandi', obscure: true)], button: 'Daftar', onSubmit: () => dialog(context, 'Pendaftaran berhasil', 'Prototype akun berhasil dibuat. Silakan masuk dengan akun contoh.'), footer: TextButton(onPressed: () => Navigator.pop(context), child: const Text('Sudah punya akun? Masuk')));
}

class WargaHome extends StatefulWidget { const WargaHome({super.key}); @override State<WargaHome> createState() => _WargaHomeState(); }
class _WargaHomeState extends State<WargaHome> {
  int tab = 0;
  @override Widget build(BuildContext context) { final pages = [const WargaMap(), const MyReports(), const Notifications(), const Profile(role: Role.warga)]; return Scaffold(body: pages[tab], bottomNavigationBar: Nav(tab, (i) => setState(() => tab = i), const ['Peta', 'Laporan', 'Notifikasi', 'Profil'])); }
}

class PetugasHome extends StatefulWidget { const PetugasHome({super.key}); @override State<PetugasHome> createState() => _PetugasHomeState(); }
class _PetugasHomeState extends State<PetugasHome> {
  int tab = 0;
  @override Widget build(BuildContext context) { final pages = [const TaskPage(), const TaskHistory(), const Notifications(), const Profile(role: Role.petugas)]; return Scaffold(body: pages[tab], bottomNavigationBar: Nav(tab, (i) => setState(() => tab = i), const ['Tugas', 'Riwayat', 'Notifikasi', 'Profil'])); }
}

class AdminHome extends StatefulWidget { const AdminHome({super.key}); @override State<AdminHome> createState() => _AdminHomeState(); }
class _AdminHomeState extends State<AdminHome> {
  int tab = 0;
  @override Widget build(BuildContext context) { final pages = [AdminDashboard(onChanged: () => setState(() {})), AdminVerification(onChanged: () => setState(() {})), AssignmentPage(onChanged: () => setState(() {})), const Profile(role: Role.admin)]; return Scaffold(body: pages[tab], bottomNavigationBar: Nav(tab, (i) => setState(() => tab = i), const ['Dashboard', 'Verifikasi', 'Penugasan', 'Profil'])); }
}

class WargaMap extends StatelessWidget { const WargaMap({super.key}); @override Widget build(BuildContext context) => AppPage(title: 'Peta titik sampah', child: Column(children: [const Expanded(child: MapPlaceholder()), Button('Buat Laporan', () => push(context, const CreateReport()))])); }
class CreateReport extends StatefulWidget { const CreateReport({super.key}); @override State<CreateReport> createState() => _CreateReportState(); }
class _CreateReportState extends State<CreateReport> { final location = TextEditingController(), desc = TextEditingController(); String category = 'Sampah rumah tangga'; String error = ''; @override Widget build(BuildContext context) => Scaffold(body: AppPage(title: 'Buat Laporan', child: SingleChildScrollView(child: Column(children: [Input(label: 'Lokasi', controller: location, hint: 'Contoh: Jalan Diponegoro'), DropdownButtonFormField<String>(initialValue: category, decoration: const InputDecoration(labelText: 'Kategori', filled: true, fillColor: Colors.white, border: OutlineInputBorder()), items: const ['Sampah rumah tangga', 'Sampah plastik', 'Sampah lainnya'].map((x) => DropdownMenuItem(value: x, child: Text(x))).toList(), onChanged: (x) => setState(() => category = x ?? category)), const SizedBox(height: 10), Input(label: 'Deskripsi', controller: desc, hint: 'Jelaskan kondisi sampah'), const SizedBox(height: 10), const Card(child: SizedBox(height: 130, child: Center(child: Icon(Icons.add_a_photo, size: 40, color: C.navy)))), if (error.isNotEmpty) Padding(padding: const EdgeInsets.all(8), child: Text(error, style: const TextStyle(color: Colors.red))), const SizedBox(height: 18), Button('Kirim Laporan', () { if (location.text.trim().isEmpty || desc.text.trim().isEmpty) { setState(() => error = 'Lokasi dan deskripsi wajib diisi.'); return; } reports.add(Report('#${reports.length + 1}'.padLeft(5, '0'), location.text.trim(), '[$category] ${desc.text.trim()}', 'Menunggu')); Navigator.pop(context); })])))); }
class MyReports extends StatelessWidget { const MyReports({super.key}); @override Widget build(BuildContext context) => AppPage(title: 'Laporan Saya', child: ListView(children: reports.map((r) => ReportTile(r, onTap: () => push(context, ReportDetail(report: r)))).toList())); }
class ReportDetail extends StatelessWidget { final Report report; const ReportDetail({super.key, required this.report}); @override Widget build(BuildContext context) => AppPage(title: 'Detail ${report.id}', child: ListView(padding: const EdgeInsets.only(bottom: 20), children: [ReportTile(report), const SizedBox(height: 16), const Text('Riwayat Status', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: C.navy)), const SizedBox(height: 10), StatusTimeline(current: report.status), if (report.rejectionReason != null) Card(color: Colors.red.shade50, child: Padding(padding: const EdgeInsets.all(12), child: Text('Alasan penolakan: ${report.rejectionReason}', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold))))])); }
class StatusTimeline extends StatelessWidget {
  final String current;

  const StatusTimeline({
    super.key,
    required this.current,
  });

  @override
  Widget build(BuildContext context) {
    const steps = [
      'Menunggu',
      'Diverifikasi',
      'Ditugaskan',
      'Dikerjakan',
      'Selesai',
    ];

    final currentIndex = steps.indexOf(current);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            for (var i = 0; i < steps.length; i++)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    i <= currentIndex
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: i <= currentIndex ? C.teal : C.gray,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(
                        top: 2,
                        bottom: 14,
                      ),
                      child: Text(
                        steps[i],
                        style: TextStyle(
                          color: i <= currentIndex
                              ? C.navy
                              : Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
class TaskPage extends StatefulWidget { const TaskPage({super.key}); @override State<TaskPage> createState() => _TaskPageState(); }
class _TaskPageState extends State<TaskPage> { @override Widget build(BuildContext context) => AppPage(title: 'Daftar Tugas', child: ListView(children: reports.where((r) => r.assignedTo == Role.petugas && r.status != 'Selesai').map((r) => ReportTile(r, action: r.status == 'Ditugaskan' ? 'Mulai' : 'Selesaikan', onAction: () { setState(() { r.status = r.status == 'Ditugaskan' ? 'Dikerjakan' : 'Selesai'; }); })).toList())); }
class TaskHistory extends StatelessWidget { const TaskHistory({super.key}); @override Widget build(BuildContext context) => AppPage(title: 'Riwayat Tugas', child: ListView(children: reports.where((r) => r.assignedTo == Role.petugas && r.status == 'Selesai').map((r) => ReportTile(r)).toList())); }

class AdminDashboard extends StatelessWidget { final VoidCallback onChanged; const AdminDashboard({super.key, required this.onChanged}); @override Widget build(BuildContext context) => AppPage(title: 'Dashboard Admin', child: ListView(children: [Row(children: [Stat('Baru', reports.where((r) => r.status == 'Menunggu').length), Stat('Dikerjakan', reports.where((r) => r.status == 'Dikerjakan').length), Stat('Selesai', reports.where((r) => r.status == 'Selesai').length)]), const SizedBox(height: 18), const MapPlaceholder(height: 230), const SizedBox(height: 18), ...reports.map((r) => ReportTile(r))])); }
class AdminVerification extends StatelessWidget { final VoidCallback onChanged; const AdminVerification({super.key, required this.onChanged}); @override Widget build(BuildContext context) => AppPage(title: 'Verifikasi Laporan', child: ListView(children: reports.where((r) => r.status == 'Menunggu').map((r) => ReportTile(r, action: 'Verifikasi', onAction: () { r.status = 'Diverifikasi'; onChanged(); }, secondaryAction: 'Tolak', onSecondary: () => rejectDialog(context, r, onChanged))).toList())); }
class AssignmentPage extends StatelessWidget { final VoidCallback onChanged; const AssignmentPage({super.key, required this.onChanged}); @override Widget build(BuildContext context) => AppPage(title: 'Penugasan Petugas', child: ListView(children: reports.where((r) => r.status == 'Diverifikasi').map((r) => ReportTile(r, action: 'Tugaskan', onAction: () { r.assignedTo = Role.petugas; r.status = 'Ditugaskan'; onChanged(); })).toList())); }
void rejectDialog(BuildContext context, Report report, VoidCallback refresh) { final controller = TextEditingController(); showDialog(context: context, builder: (_) => AlertDialog(title: const Text('Tolak laporan'), content: TextField(controller: controller, decoration: const InputDecoration(labelText: 'Alasan penolakan')), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')), FilledButton(onPressed: () { if (controller.text.trim().isNotEmpty) { report.rejectionReason = controller.text.trim(); report.status = 'Ditolak'; refresh(); Navigator.pop(context); } }, child: const Text('Tolak'))])); }

class Notifications extends StatelessWidget { const Notifications({super.key}); @override Widget build(BuildContext context) => AppPage(title: 'Notifikasi', child: ListView(children: reports.map((r) => Card(child: ListTile(leading: const Icon(Icons.notifications, color: C.navy), title: Text('Laporan ${r.id}'), subtitle: Text('Status: ${r.status}')))).toList())); }
class Profile extends StatelessWidget { final Role role; const Profile({super.key, required this.role}); @override Widget build(BuildContext context) => AppPage(title: 'Profil', child: Column(children: [const CircleAvatar(radius: 42, backgroundColor: C.pale, child: Icon(Icons.person, size: 48, color: C.navy)), const SizedBox(height: 12), Text(role == Role.admin ? 'Admin DLH' : role == Role.petugas ? 'Petugas DLH' : 'Warga Pelapor', style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold, color: C.navy)), const SizedBox(height: 25), OutlinedButton(onPressed: () => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const OpeningPage()), (_) => false), child: const Text('Keluar'))])); }

class ReportTile extends StatelessWidget { final Report report; final String? action, secondaryAction; final VoidCallback? onAction, onSecondary, onTap; const ReportTile(this.report, {super.key, this.action, this.onAction, this.secondaryAction, this.onSecondary, this.onTap}); @override Widget build(BuildContext context) => Card(child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(12), child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Laporan ${report.id}', style: const TextStyle(fontWeight: FontWeight.bold, color: C.navy, fontSize: 16)), Text(report.location), Text(report.description), if (report.rejectionReason != null) Text('Alasan: ${report.rejectionReason}', style: const TextStyle(color: Colors.red)), const SizedBox(height: 8), Wrap(spacing: 8, alignment: WrapAlignment.spaceBetween, children: [Status(report.status), if (action != null) ButtonSmall(action!, onAction!), if (secondaryAction != null) OutlinedButton(onPressed: onSecondary, child: Text(secondaryAction!))])])))); }
class Status extends StatelessWidget { final String text; const Status(this.text, {super.key}); @override Widget build(BuildContext context) { final color = text == 'Selesai' ? C.navy : text == 'Dikerjakan' ? C.teal : text == 'Ditolak' ? C.gray : C.pale; return Chip(label: Text(text, style: TextStyle(color: text == 'Selesai' ? Colors.white : C.navy, fontWeight: FontWeight.bold)), backgroundColor: color); } }
class Stat extends StatelessWidget { final String title; final int value; const Stat(this.title, this.value, {super.key}); @override Widget build(BuildContext context) => Expanded(child: Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(children: [Text(title), Text('$value', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: C.navy))])))); }
class MapPlaceholder extends StatelessWidget { final double? height; const MapPlaceholder({super.key, this.height}); @override Widget build(BuildContext context) => Container(height: height, decoration: BoxDecoration(color: const Color(0xFFE4E0D5), borderRadius: BorderRadius.circular(18)), child: const Center(child: Icon(Icons.map, size: 90, color: C.teal))); }

class AppPage extends StatelessWidget { final String title; final Widget child; const AppPage({super.key, required this.title, required this.child}); @override Widget build(BuildContext context) => Scaffold(backgroundColor: C.pale, body: SafeArea(child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [const Logo(size: 42), const SizedBox(width: 10), Expanded(child: Text(title, style: const TextStyle(fontSize: 23, fontWeight: FontWeight.bold, color: C.navy)))]), const SizedBox(height: 18), Expanded(child: child)])))); }
class GradientPage extends StatelessWidget { final Widget child; const GradientPage({super.key, required this.child}); @override Widget build(BuildContext context) => Scaffold(body: Container(decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [C.navy, C.teal])), child: SafeArea(child: Padding(padding: const EdgeInsets.all(24), child: child)))); }
class AuthPage extends StatelessWidget { final String title, button, error; final List<Widget> fields; final VoidCallback onSubmit; final Widget footer; const AuthPage({super.key, required this.title, required this.fields, required this.button, required this.onSubmit, required this.footer, this.error = ''}); @override Widget build(BuildContext context) => GradientPage(child: Center(child: SingleChildScrollView(child: Card(color: C.pale, child: Padding(padding: const EdgeInsets.all(22), child: Column(children: [const Logo(size: 60), const SizedBox(height: 10), Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold, color: C.navy)), const SizedBox(height: 18), ...fields, if (error.isNotEmpty) Text(error, style: const TextStyle(color: Colors.red)), const SizedBox(height: 10), Button(button, onSubmit), footer])))))); }
class Input extends StatelessWidget { final String label; final TextEditingController? controller; final String hint; final bool obscure; const Input({super.key, required this.label, this.controller, this.hint = '', this.obscure = false}); @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 10), child: TextField(controller: controller, obscureText: obscure, decoration: InputDecoration(labelText: label, hintText: hint, filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)))); }
class Logo extends StatelessWidget { final double size; const Logo({super.key, required this.size}); @override Widget build(BuildContext context) => Container(width: size, height: size, decoration: const BoxDecoration(shape: BoxShape.circle, color: C.pale), child: Icon(Icons.location_on, size: size * .5, color: C.navy)); }
class Button extends StatelessWidget { final String text; final VoidCallback onTap; const Button(this.text, this.onTap, {super.key}); @override Widget build(BuildContext context) => SizedBox(width: double.infinity, child: FilledButton(onPressed: onTap, style: FilledButton.styleFrom(backgroundColor: C.navy, foregroundColor: Colors.white), child: Text(text))); }
class ButtonSmall extends StatelessWidget { final String text; final VoidCallback onTap; const ButtonSmall(this.text, this.onTap, {super.key}); @override Widget build(BuildContext context) => FilledButton(onPressed: onTap, style: FilledButton.styleFrom(backgroundColor: C.navy), child: Text(text)); }
class Nav extends StatelessWidget { final int index; final ValueChanged<int> onTap; final List<String> labels; const Nav(this.index, this.onTap, this.labels, {super.key}); @override Widget build(BuildContext context) => NavigationBar(selectedIndex: index, onDestinationSelected: onTap, destinations: labels.map((x) => NavigationDestination(icon: Icon(x == 'Peta' ? Icons.map_outlined : x == 'Profil' ? Icons.person_outline : x == 'Dashboard' ? Icons.dashboard_outlined : x == 'Verifikasi' ? Icons.fact_check_outlined : x == 'Penugasan' ? Icons.assignment_outlined : Icons.notifications_none), label: x)).toList()); }
void push(BuildContext c, Widget page) => Navigator.push(c, MaterialPageRoute(builder: (_) => page));
void dialog(BuildContext c, String title, String text) => showDialog(context: c, builder: (_) => AlertDialog(title: Text(title), content: Text(text), actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('OK'))]));
