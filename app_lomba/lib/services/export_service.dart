import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';

class ExportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Ekspor data peserta ke Excel
  Future<String> exportPesertaToExcel(String eventId) async {
    try {
      final pesertaSnapshot = await _firestore
          .collection('participants')
          .where('eventId', isEqualTo: eventId)
          .get();

      var excel = Excel.createExcel();
      Sheet sheet = excel['Peserta'];

      // Header kolom
      sheet.appendRow([
        'Nama Peserta',
        'Email',
        'Nama Burung',
        'Kategori',
        'Tanggal Daftar',
      ]);

      // Isi data peserta
      for (var doc in pesertaSnapshot.docs) {
        var data = doc.data();
        sheet.appendRow([
          data['namaPeserta'] ?? '',
          data['email'] ?? '',
          data['namaBurung'] ?? '',
          data['kategori'] ?? '',
          data['tanggalDaftar'] != null
              ? (data['tanggalDaftar'] as Timestamp).toDate().toString()
              : '',
        ]);
      }

      // Simpan file di storage lokal
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/data_peserta_event_$eventId.xlsx';
      final fileBytes = excel.encode();

      if (fileBytes == null) {
        throw Exception('Gagal membuat file Excel');
      }

      final file = File(filePath);
      await file.writeAsBytes(fileBytes);

      return filePath;
    } catch (e) {
      print('Error exporting peserta: $e');
      rethrow;
    }
  }

  // Ekspor hasil lomba ke Excel
  Future<String> exportHasilLombaToExcel(String eventId) async {
    try {
      final resultsSnapshot = await _firestore
          .collection('results')
          .where('eventId', isEqualTo: eventId)
          .get();

      var excel = Excel.createExcel();
      Sheet sheet = excel['Hasil Lomba'];

      // Header kolom
      sheet.appendRow([
        'Nama Peserta',
        'Nama Burung',
        'Kategori',
        'Nilai',
        'Peringkat',
      ]);

      for (var doc in resultsSnapshot.docs) {
        var data = doc.data();
        sheet.appendRow([
          data['namaPeserta'] ?? '',
          data['namaBurung'] ?? '',
          data['kategori'] ?? '',
          data['nilai']?.toString() ?? '',
          data['peringkat']?.toString() ?? '',
        ]);
      }

      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/hasil_lomba_event_$eventId.xlsx';
      final fileBytes = excel.encode();

      if (fileBytes == null) {
        throw Exception('Gagal membuat file Excel');
      }

      final file = File(filePath);
      await file.writeAsBytes(fileBytes);

      return filePath;
    } catch (e) {
      print('Error exporting hasil lomba: $e');
      rethrow;
    }
  }
}
