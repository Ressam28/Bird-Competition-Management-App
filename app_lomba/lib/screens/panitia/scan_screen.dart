import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  bool _isScanning = true;
  Map<String, dynamic>? _registrationData;
  String? _registrationId;

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  void _onQRViewCreated(QRViewController ctrl) {
    controller = ctrl;
    controller!.scannedDataStream.listen((scanData) async {
      if (_isScanning) {
        setState(() => _isScanning = false);
        final id = scanData.code;
        final doc = await FirebaseFirestore.instance.collection('registrations').doc(id).get();

        if (doc.exists) {
          setState(() {
            _registrationId = id;
            _registrationData = doc.data();
          });

          // Simpan status check-in
          await FirebaseFirestore.instance.collection('registrations').doc(id).update({
            'checkin': true,
            'checkinAt': Timestamp.now(),
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Data tidak ditemukan.')),
          );
          setState(() => _isScanning = true);
        }
      }
    });
  }

  void _resetScanner() {
    setState(() {
      _registrationData = null;
      _registrationId = null;
      _isScanning = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan QR Peserta')),
      body: _registrationData == null
          ? Column(
              children: [
                Expanded(
                  flex: 4,
                  child: QRView(key: qrKey, onQRViewCreated: _onQRViewCreated),
                ),
                const SizedBox(height: 16),
                const Text('Arahkan kamera ke QR peserta'),
              ],
            )
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Nama Peserta: ${_registrationData!['namaPeserta']}',
                      style: const TextStyle(fontSize: 18)),
                  const SizedBox(height: 8),
                  Text('Nama Burung: ${_registrationData!['namaBurung']}'),
                  const SizedBox(height: 8),
                  Text('Kategori: ${_registrationData!['kategori']}'),
                  const SizedBox(height: 8),
                  Text('Jadwal: ${_registrationData!['jadwalTampil']}'),
                  const SizedBox(height: 8),
                  Text('Sudah dicatat sebagai check-in.'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _resetScanner,
                    child: const Text('Scan Ulang'),
                  ),
                ],
              ),
            ),
    );
  }
}
