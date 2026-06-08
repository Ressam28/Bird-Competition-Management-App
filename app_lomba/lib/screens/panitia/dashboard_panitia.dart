import 'package:flutter/material.dart';
import 'package:app_lomba/routes.dart';

class DashboardPanitia extends StatelessWidget {
  const DashboardPanitia({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF26A69A); // Tosca (Teal 400)

    return Scaffold(
      backgroundColor: const Color(0xFFF1FDFD), // Background lembut
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: const Text(
          'Dashboard Panitia',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () {
              Navigator.pushReplacementNamed(context, Routes.login);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 20,
          mainAxisSpacing: 20,
          children: [
            _DashboardButton(
              title: 'Buat Event',
              icon: Icons.event,
              onTap: () => Navigator.pushNamed(context, Routes.panitiaCreateEvent),
              color: primaryColor,
            ),
            _DashboardButton(
              title: 'Kelola Peserta',
              icon: Icons.people,
              onTap: () => Navigator.pushNamed(context, Routes.panitiaKelolaPeserta),
              color: primaryColor,
            ),
            _DashboardButton(
              title: 'Peserta Check-in',
              icon: Icons.qr_code,
              onTap: () => Navigator.pushNamed(context, Routes.panitiaCheckinList),
              color: primaryColor,
            ),
            _DashboardButton(
              title: 'Export Data',
              icon: Icons.download,
              onTap: () => Navigator.pushNamed(context, Routes.panitiaExportData),
              color: primaryColor,
            ),
            _DashboardButton(
              title: 'Scan QR',
              icon: Icons.qr_code_scanner,
              onTap: () => Navigator.pushNamed(context, Routes.panitiaScan),
              color: primaryColor,
            ),
            _DashboardButton(
            title: 'Tambah Panitia',
            icon: Icons.person_add,
            onTap: () => Navigator.pushNamed(context, Routes.panitiaTambahPanitia),
            color: primaryColor,
          ),
          ],
        ),
      ),
    );
  }
}

class _DashboardButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  const _DashboardButton({
    required this.title,
    required this.icon,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.1), // Warna soft dari tosca
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 6,
              offset: const Offset(3, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
