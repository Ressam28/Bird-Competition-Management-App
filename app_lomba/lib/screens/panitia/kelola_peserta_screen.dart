import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class KelolaPesertaScreen extends StatefulWidget {
  const KelolaPesertaScreen({super.key});

  @override
  State<KelolaPesertaScreen> createState() => _KelolaPesertaScreenState();
}

class _KelolaPesertaScreenState extends State<KelolaPesertaScreen> {
  String? selectedEventId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Peserta'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            FutureBuilder<QuerySnapshot>(
              future: FirebaseFirestore.instance.collection('events').get(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const CircularProgressIndicator();

                final eventDocs = snapshot.data!.docs;

                return DropdownButton<String>(
                  value: selectedEventId,
                  isExpanded: true,
                  hint: const Text('Pilih Event'),
                  items: eventDocs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return DropdownMenuItem(
                      value: doc.id,
                      child: Text(data['judul'] ?? '[Tanpa Judul]'),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => selectedEventId = value),
                );
              },
            ),
            const SizedBox(height: 12),
            Expanded(child: _buildList()),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('registrations')
          .orderBy('eventId')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final registrations = snapshot.data!.docs.where((doc) {
          return selectedEventId == null || doc['eventId'] == selectedEventId;
        }).toList();

        final grouped = <String, List<QueryDocumentSnapshot>>{};
        for (var doc in registrations) {
          final eventId = doc['eventId'];
          grouped.putIfAbsent(eventId, () => []).add(doc);
        }

        if (grouped.isEmpty) {
          return const Center(child: Text('Tidak ada data peserta.'));
        }

        return ListView(
          children: grouped.entries.map((entry) {
            final eventId = entry.key;
            final pesertaList = entry.value;

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('events').doc(eventId).get(),
              builder: (context, eventSnapshot) {
                if (!eventSnapshot.hasData || !eventSnapshot.data!.exists) return const SizedBox();
                final eventData = eventSnapshot.data!.data() as Map<String, dynamic>?;
                if (eventData == null || eventData['judul'] == null) return const SizedBox();

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 3,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ExpansionTile(
                    title: Text(eventData['judul']),
                    subtitle: Text(eventData['tanggal'] ?? ''),
                    children: pesertaList.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final isAcc = data['acc'] == true;
                      final jadwal = data['jadwalTampil'] ?? '-';

                      return FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('users')
                            .doc(data['userId'])
                            .get(),
                        builder: (context, userSnapshot) {
                          String namaPeserta = 'Peserta';
                          if (userSnapshot.hasData && userSnapshot.data!.exists) {
                            final userData = userSnapshot.data!.data() as Map<String, dynamic>;
                            namaPeserta = userData['displayName'] ?? namaPeserta;
                          }

                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            title: Text(data['namaBurung'] ?? 'Burung'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Kategori: ${data['kategori'] ?? '-'}'),
                                Text('Jadwal: $jadwal'),
                                Text('Peserta: $namaPeserta'),
                              ],
                            ),
                            trailing: isAcc
                                ? PopupMenuButton<String>(
                                    onSelected: (value) => _handleAction(context, value, doc),
                                    itemBuilder: (_) => [
                                      const PopupMenuItem(value: 'edit', child: Text('Edit Jadwal')),
                                      const PopupMenuItem(value: 'batal', child: Text('Batalkan ACC')),
                                    ],
                                    icon: const Icon(Icons.more_vert),
                                  )
                                : ElevatedButton(
                                    onPressed: () => _showAccDialog(context, doc),
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8)),
                                    ),
                                    child: const Text('ACC + Jadwal'),
                                  ),
                          );
                        },
                      );
                    }).toList(),
                  ),
                );
              },
            );
          }).toList(),
        );
      },
    );
  }

  void _showAccDialog(BuildContext context, QueryDocumentSnapshot doc) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('ACC + Jadwal'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Jadwal tampil'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              await doc.reference.update({
                'acc': true,
                'jadwalTampil': controller.text.trim(),
              });
              Navigator.pop(context);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _handleAction(BuildContext context, String action, QueryDocumentSnapshot doc) {
    if (action == 'edit') {
      _showAccDialog(context, doc);
    } else if (action == 'batal') {
      doc.reference.update({
        'acc': false,
        'jadwalTampil': FieldValue.delete(),
      });
    }
  }
}
