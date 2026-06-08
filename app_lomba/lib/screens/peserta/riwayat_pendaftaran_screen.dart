import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class RiwayatPendaftaranScreen extends StatefulWidget {
  const RiwayatPendaftaranScreen({super.key});

  @override
  State<RiwayatPendaftaranScreen> createState() => _RiwayatPendaftaranScreenState();
}

class _RiwayatPendaftaranScreenState extends State<RiwayatPendaftaranScreen> {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  String? selectedEventId;
  Map<String, String> eventIdToTitle = {};

  @override
  void initState() {
    super.initState();
    fetchUserEvents();
  }

  Future<void> fetchUserEvents() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('registrations')
        .where('userId', isEqualTo: userId)
        .get();

    final eventIds = snapshot.docs.map((doc) => doc['eventId'] as String).toSet();

    Map<String, String> mapping = {};
    for (var id in eventIds) {
      final eventDoc = await FirebaseFirestore.instance.collection('events').doc(id).get();
      if (eventDoc.exists) {
        mapping[id] = eventDoc['judul'] ?? 'Event';
      }
    }

    setState(() {
      eventIdToTitle = mapping;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      appBar: AppBar(
        title: const Text('Riwayat Pendaftaran', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          if (eventIdToTitle.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: DropdownButtonFormField<String>(
                value: selectedEventId,
                decoration: const InputDecoration(
                  labelText: 'Filter Event',
                  border: OutlineInputBorder(),
                ),
                items: eventIdToTitle.entries.map((entry) {
                  return DropdownMenuItem<String>(
                    value: entry.key,
                    child: Text(entry.value),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedEventId = value;
                  });
                },
              ),
            ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('registrations')
                  .where('userId', isEqualTo: userId)
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final registrations = snapshot.data?.docs ?? [];

                final filtered = selectedEventId == null
                    ? registrations
                    : registrations.where((doc) => doc['eventId'] == selectedEventId).toList();

                if (filtered.isEmpty) {
                  return const Center(child: Text('Tidak ada data untuk event ini.'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final data = filtered[index];
                    final eventId = data['eventId'];
                    final namaPeserta = data['namaPeserta'];
                    final namaBurung = data['namaBurung'];
                    final kategori = data['kategori'];
                    final timestamp = (data['timestamp'] as Timestamp).toDate();

                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance.collection('events').doc(eventId).get(),
                      builder: (context, eventSnapshot) {
                        if (!eventSnapshot.hasData || !eventSnapshot.data!.exists) {
                          return const SizedBox();
                        }

                        final event = eventSnapshot.data!;
                        final judulEvent = event['judul'] ?? 'Event';
                        final tanggalString = event['tanggal'] ?? '';
                        final imageUrl = event['imageUrl'];
                        final formattedTanggal = tanggalString.isNotEmpty
                            ? DateFormat('dd MMM yyyy').format(DateTime.parse(tanggalString))
                            : '-';

                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 6,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: imageUrl != null
                                    ? Image.network(
                                        imageUrl,
                                        width: 80,
                                        height: 80,
                                        fit: BoxFit.cover,
                                      )
                                    : Container(
                                        width: 80,
                                        height: 80,
                                        color: Colors.grey[300],
                                        child: const Icon(Icons.image, size: 40, color: Colors.white70),
                                      ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      judulEvent,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text('Peserta: $namaPeserta'),
                                    Text('Burung: $namaBurung ($kategori)'),
                                    Text('Tanggal: $formattedTanggal'),
                                  ],
                                ),
                              ),
                            ],
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
