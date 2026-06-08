import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../routes.dart';

class DashboardPeserta extends StatefulWidget {
  const DashboardPeserta({super.key});

  @override
  State<DashboardPeserta> createState() => _DashboardPesertaState();
}

class _DashboardPesertaState extends State<DashboardPeserta> {
  int _currentIndex = 2;
  String? _namaUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final data = doc.data();
      if (data != null && mounted) {
        setState(() {
          _namaUser = data['name'] ?? 'Peserta';
          _isLoading = false;
        });
      }
    }
  }

  void _onItemTapped(int index) {
    setState(() => _currentIndex = index);
    switch (index) {
      case 0:
        Navigator.pushNamed(context, Routes.pesertaEvents);
        break;
      case 1:
        Navigator.pushNamed(context, Routes.pesertaRiwayatPendaftaran);
        break;
      case 2:
        break;
      case 3:
        Navigator.pushNamed(context, Routes.pesertaJadwal, arguments: 'Umum');
        break;
      case 4:
        Navigator.pushNamed(context, Routes.pesertaProfil);
        break;
    }
  }

  Widget _buildEventList({
    required BuildContext context,
    required String title,
    required bool isBerlangsung,
  }) {
    final theme = Theme.of(context);

    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

    final query = FirebaseFirestore.instance
        .collection('events')
        .orderBy('tanggal', descending: isBerlangsung ? false : true)
        .limit(5);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, Routes.pesertaEvents),
              child: Text("Lihat Semua", style: TextStyle(color: theme.colorScheme.primary)),
            ),
          ],
        ),
        StreamBuilder<QuerySnapshot>(
          stream: query.snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Text('Tidak ada event yang tersedia.');
            }

            final events = snapshot.data!.docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final tanggalStr = data['tanggal'];
              if (tanggalStr == null) return false;

              final eventDate = DateTime.tryParse(tanggalStr);
              if (eventDate == null) return false;

              return isBerlangsung
                  ? !eventDate.isBefore(today)
                  : eventDate.isBefore(today);
            }).toList();

            if (events.isEmpty) {
              return const Text('Tidak ada event yang cocok.');
            }

            return Column(
              children: events.map((doc) {
                final data = doc.data() as Map<String, dynamic>;

                return Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: InkWell(
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        Routes.pesertaEventDetail,
                        arguments: doc.id,
                      );
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (data['imageUrl'] != null)
                          ClipRRect(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(12),
                              topRight: Radius.circular(12),
                            ),
                            child: Image.network(
                              data['imageUrl'],
                              height: 160,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      data['judul'] ?? '-',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(data['lokasiNama'] ?? '-'),
                                    if (data['tanggal'] != null)
                                      Text(
                                        DateFormat('dd MMMM yyyy').format(DateTime.parse(data['tanggal'])),
                                        style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox.shrink(), // Map icon dihapus
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final greeting = _isLoading ? "Memuat..." : "Halo ${_namaUser ?? 'Peserta'}";

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushNamedAndRemoveUntil(context, Routes.login, (route) => false);
          },
        ),
        title: const Text(''),
        backgroundColor: const Color.fromARGB(0, 95, 200, 104),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
                    radius: 32,
                    child: Icon(Icons.account_circle, size: 40, color: theme.colorScheme.primary),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Rundown Gantangan Burung",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                  ),
                  Text(greeting),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildEventList(context: context, title: "Event Berlangsung", isBerlangsung: true),
            _buildEventList(context: context, title: "Event Berakhir", isBerlangsung: false),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: theme.colorScheme.primary,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Event List'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Riwayat'),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.schedule), label: 'Jadwal'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
}
