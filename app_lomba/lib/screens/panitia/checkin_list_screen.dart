import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CheckinListScreen extends StatefulWidget {
  const CheckinListScreen({super.key});

  @override
  State<CheckinListScreen> createState() => _CheckinListScreenState();
}

class _CheckinListScreenState extends State<CheckinListScreen> {
  String? selectedEventId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Daftar Check-in Peserta"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            FutureBuilder<QuerySnapshot>(
              future: FirebaseFirestore.instance.collection('events').get(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final eventDocs = snapshot.data!.docs;

                return DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Pilih Event',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  value: selectedEventId,
                  items: eventDocs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return DropdownMenuItem<String>(
                      value: doc.id,
                      child: Text(data['judul'] ?? 'Tanpa Judul'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedEventId = value;
                    });
                  },
                );
              },
            ),
            const SizedBox(height: 20),
            if (selectedEventId != null)
              Expanded(child: _buildCheckinList(selectedEventId!)),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckinList(String eventId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('registrations')
          .where('eventId', isEqualTo: eventId)
          .where('checkin', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final checkinDocs = snapshot.data?.docs ?? [];

        if (checkinDocs.isEmpty) {
          return const Center(
            child: Text(
              "Belum ada peserta check-in.",
              style: TextStyle(fontSize: 16),
            ),
          );
        }

        return ListView.separated(
          itemCount: checkinDocs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final data = checkinDocs[index].data() as Map<String, dynamic>;

            return Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['namaPeserta'] ?? 'Nama Peserta',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('Burung: ${data['namaBurung'] ?? '-'}'),
                    Text('Kategori: ${data['kategori'] ?? '-'}'),
                    Text('Jadwal Tampil: ${data['jadwalTampil'] ?? '-'}'),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
