import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class JadwalScreen extends StatefulWidget {
  const JadwalScreen({super.key});

  @override
  State<JadwalScreen> createState() => _JadwalScreenState();
}

class _JadwalScreenState extends State<JadwalScreen> {
  final String userId = FirebaseAuth.instance.currentUser!.uid;
  String? selectedEventId;

  Future<List<Map<String, dynamic>>> getValidEventsFromRegistrations() async {
    final registrationsSnapshot = await FirebaseFirestore.instance
        .collection('registrations')
        .where('userId', isEqualTo: userId)
        .where('acc', isEqualTo: true)
        .get();

    final eventIds = registrationsSnapshot.docs
        .map((doc) => doc['eventId'] as String)
        .toSet()
        .toList();

    final validEvents = <Map<String, dynamic>>[];

    for (final id in eventIds) {
      final eventDoc =
          await FirebaseFirestore.instance.collection('events').doc(id).get();
      if (eventDoc.exists) {
        validEvents.add({'id': id, 'judul': eventDoc['judul'] ?? 'Event'});
      }
    }

    return validEvents;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Jadwal Tampil Saya')),
      body: Column(
        children: [
          // Dropdown filter
          Padding(
            padding: const EdgeInsets.all(12),
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: getValidEventsFromRegistrations(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox();

                final events = snapshot.data!;

                return DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Filter Event',
                    border: OutlineInputBorder(),
                  ),
                  value: selectedEventId,
                  items: [
                    const DropdownMenuItem(
                        value: null, child: Text('Semua Event')),
                    ...events.map((e) => DropdownMenuItem(
                          value: e['id'],
                          child: Text(e['judul']),
                        )),
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedEventId = value;
                    });
                  },
                );
              },
            ),
          ),

          // Daftar jadwal
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('registrations')
                  .where('userId', isEqualTo: userId)
                  .where('acc', isEqualTo: true)
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Terjadi kesalahan.'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data?.docs ?? [];

                final filteredDocs = selectedEventId == null
                    ? docs
                    : docs
                        .where((d) => d['eventId'] == selectedEventId)
                        .toList();

                if (filteredDocs.isEmpty) {
                  return const Center(
                    child: Text('Belum ada jadwal tampil.'),
                  );
                }

                return ListView.builder(
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    final doc = filteredDocs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final eventId = data['eventId'];

                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('events')
                          .doc(eventId)
                          .get(),
                      builder: (context, eventSnapshot) {
                        if (!eventSnapshot.hasData ||
                            !eventSnapshot.data!.exists) return const SizedBox();

                        final eventData = eventSnapshot.data!;
                        final judulEvent =
                            eventData['judul'] ?? 'Event';

                        return Card(
                          margin: const EdgeInsets.all(12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  judulEvent,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blueAccent,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  data['namaBurung'] ?? '-',
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 6),
                                Text("Kategori: ${data['kategori'] ?? '-'}"),
                                const SizedBox(height: 6),
                                Text(
                                    "Jadwal Tampil: ${data['jadwalTampil'] ?? 'Belum ditentukan'}"),
                                const SizedBox(height: 12),
                                QrImageView(
                                  data: doc.id,
                                  version: QrVersions.auto,
                                  size: 120,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Tunjukkan QR ini saat tampil.',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
