import 'package:flutter/material.dart';
import 'package:path/path.dart';

// Auth
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';

// Peserta
import 'screens/peserta/dashboard_peserta.dart';
import 'screens/peserta/event_list_screen.dart';
import 'screens/peserta/event_detail_screen.dart';
import 'screens/peserta/registration_form_screen.dart';
import 'screens/peserta/jadwal_screen.dart';
import 'screens/peserta/riwayat_pendaftaran_screen.dart' as riwayat;
import 'screens/peserta/profile_screen.dart';

// Panitia
import 'screens/panitia/dashboard_panitia.dart';
import 'screens/panitia/create_event_screen.dart';
import 'screens/panitia/kelola_peserta_screen.dart';
import 'screens/panitia/checkin_list_screen.dart';
import 'screens/panitia/exsport_data_screen.dart';
import 'screens/panitia/pick_location_screen.dart';
import 'screens/panitia/scan_screen.dart';
import 'screens/panitia/tambah_panitia_screen.dart';

class Routes {
  // Auth
  static const login = '/login';
  static const register = '/register';

  // Peserta
  static const pesertaDashboard = '/peserta/dashboard';
  static const pesertaEvents = '/peserta/events';
  static const pesertaEventDetail = '/peserta/event_detail';
  static const pesertaRegistrationForm = '/peserta/registration_form';
  static const pesertaQrCode = '/peserta/qr_code';
  static const pesertaJadwal = '/peserta/jadwal';
  static const pesertaMapsLocation = '/peserta/maps_location';
  static const pesertaECertificate = '/peserta/e_certificate';
  static const pesertaRiwayatPendaftaran = '/peserta/riwayat_pendaftaran';
  static const pesertaProfil = '/peserta/profil';

  // Panitia
  static const panitiaDashboard = '/panitia/dashboard';
  static const panitiaCreateEvent = '/panitia/create_event';
  static const panitiaKelolaPeserta = '/panitia/kelola_peserta';
  static const panitiaGenerateJadwal = '/panitia/generate_jadwal';
  static const panitiaCheckinList = '/panitia/checkin_list';
  static const panitiaInputHasil = '/panitia/input_hasil';
  static const panitiaExportData = '/panitia/export_data';
  static const panitiaPilihLokasi = '/panitia/pilih_lokasi';
  static const panitiaScan = '/panitia/scan'; 
  static const String panitiaTambahPanitia = '/panitia/tambah-panitia';
}

// Route tanpa parameter
final Map<String, WidgetBuilder> appRoutes = {
  // Auth
  Routes.login: (context) => const LoginScreen(),
  Routes.register: (context) => const RegisterScreen(),

  // Peserta
  Routes.pesertaDashboard: (context) => const DashboardPeserta(),
  Routes.pesertaEvents: (context) => const EventListScreen(),
  Routes.pesertaRiwayatPendaftaran: (context) => const riwayat.RiwayatPendaftaranScreen(),
  Routes.pesertaProfil: (context) => const ProfileScreen(),
  Routes.pesertaJadwal: (context) => const JadwalScreen(),

  // Panitia
  Routes.panitiaDashboard: (context) => const DashboardPanitia(),
  Routes.panitiaCreateEvent: (context) => const CreateEventScreen(),
  Routes.panitiaKelolaPeserta: (context) => const KelolaPesertaScreen(),
  Routes.panitiaCheckinList: (context) => const CheckinListScreen(),
  Routes.panitiaExportData: (context) => const ExportDataScreen(),
  Routes.panitiaPilihLokasi: (context) => const PickLocationScreen(),
  Routes.panitiaScan: (context) => const ScanScreen(), // ✅ Scan QR Panitia
  Routes.panitiaTambahPanitia: (context) => const TambahPanitiaScreen(),
};

// Route dengan parameter
Route<dynamic>? onGenerateRoute(RouteSettings settings) {
  switch (settings.name) {
    case Routes.pesertaEventDetail:
      final eventId = settings.arguments as String;
      return MaterialPageRoute(
        builder: (context) => EventDetailScreen(eventId: eventId),
      );

        case Routes.pesertaRegistrationForm:
      final args = settings.arguments as Map<String, dynamic>;
      return MaterialPageRoute(
        builder: (_) => RegistrationFormScreen(
          eventId: args['eventId'],
          userId: args['userId'],
          kategori: args['kategori'], // ✅ pastikan ini disediakan
        ),
      );

    default:
      final builder = appRoutes[settings.name];
      if (builder != null) {
        return MaterialPageRoute(builder: builder);
      }
      return null;
  }
}
