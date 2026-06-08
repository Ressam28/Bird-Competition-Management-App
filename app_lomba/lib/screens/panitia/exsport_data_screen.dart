import 'dart:io';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ExportDataScreen extends StatefulWidget {
  const ExportDataScreen({super.key});

  @override
  State<ExportDataScreen> createState() => _ExportDataScreenState();
}

class _ExportDataScreenState extends State<ExportDataScreen> {
  String? selectedEventId;
  List<Map<String, dynamic>> pesertaData = [];
  List<Map<String, dynamic>> semuaEvent = [];

  @override
  void initState() {
    super.initState();
    fetchEvent();
  }

  Future<void> fetchEvent() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('events')
        .orderBy('tanggal', descending: true)
        .get();

    setState(() {
      semuaEvent = snapshot.docs
          .map((e) => {'id': e.id, ...e.data()})
          .where((event) => event['judul'] != null)
          .toList();
    });
  }

  Future<void> fetchPesertaByEvent(String eventId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('registrations')
        .where('eventId', isEqualTo: eventId)
        .where('acc', isEqualTo: true)
        .get();

    final data = snapshot.docs.map((doc) => doc.data()).toList();

    setState(() {
      pesertaData = data;
    });
  }

  Future<void> exportToExcel() async {
    try {
      final excel = Excel.createExcel();
      final sheet = excel['Peserta'];

      sheet.appendRow([
        'Nama Peserta',
        'Nama Burung',
        'Kategori',
        'No. HP',
        'Jadwal Tampil'
      ]);

      for (final peserta in pesertaData) {
        sheet.appendRow([
          peserta['namaPeserta'] ?? '',
          peserta['namaBurung'] ?? '',
          peserta['kategori'] ?? '',
          peserta['phone'] ?? '',
          peserta['jadwalTampil'] ?? '-',
        ]);
      }

      final tempDir = await getTemporaryDirectory();
      final fileName = 'peserta_${selectedEventId ?? 'data'}.xlsx';
      final filePath = '${tempDir.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(excel.encode()!);

      await Share.shareXFiles(
        [XFile(filePath)],
        text: 'Berikut adalah data peserta event.',
        subject: 'Export Data Peserta',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Gagal export: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Export Data Peserta'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: selectedEventId,
              hint: const Text("Pilih Event"),
              items: semuaEvent.map((event) {
                return DropdownMenuItem<String>(
                  value: event['id'],
                  child: Text(event['judul']),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => selectedEventId = value);
                fetchPesertaByEvent(value!);
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.download),
              label: const Text('Export & Kirim ke WhatsApp'),
              onPressed:
                  pesertaData.isEmpty ? null : () => exportToExcel(),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: pesertaData.isEmpty
                  ? const Center(
                      child: Text("Belum ada data peserta yang di-ACC."),
                    )
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columnSpacing: 16,
                        headingRowColor:
                            MaterialStateProperty.all(Colors.teal.shade100),
                        columns: const [
                          DataColumn(label: Text('Nama')),
                          DataColumn(label: Text('Burung')),
                          DataColumn(label: Text('Kategori')),
                          DataColumn(label: Text('No. HP')),
                          DataColumn(label: Text('Jadwal')),
                        ],
                        rows: pesertaData.map((peserta) {
                          return DataRow(
                            cells: [
                              DataCell(Text(peserta['namaPeserta'] ?? '')),
                              DataCell(Text(peserta['namaBurung'] ?? '')),
                              DataCell(Text(peserta['kategori'] ?? '')),
                              DataCell(Text(peserta['phone'] ?? '-')),
                              DataCell(Text(peserta['jadwalTampil'] ?? '-')),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
