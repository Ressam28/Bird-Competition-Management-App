import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class RegistrationFormScreen extends StatefulWidget {
  final String eventId;
  final String userId;
  final String kategori;

  const RegistrationFormScreen({
    super.key,
    required this.eventId,
    required this.userId,
    required this.kategori,
  });

  @override
  State<RegistrationFormScreen> createState() => _RegistrationFormScreenState();
}

class _RegistrationFormScreenState extends State<RegistrationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _namaBurungController = TextEditingController();
  final TextEditingController _namaPesertaController = TextEditingController();
  File? _dokumenFile;
  bool _isLoading = false;

  Future<void> _pickDocument() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _dokumenFile = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadDokumen(File file) async {
    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('dokumen/${widget.userId}_${DateTime.now().millisecondsSinceEpoch}');
      final snapshot = await ref.putFile(file);
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      debugPrint('Upload dokumen error: $e');
      return null;
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi'),
        content: const Text('Yakin ingin mendaftar untuk event ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Ya')),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    String? dokumenUrl;
    if (_dokumenFile != null) {
      dokumenUrl = await _uploadDokumen(_dokumenFile!);
    }

    final registrationData = {
      'eventId': widget.eventId,
      'userId': widget.userId,
      'namaPeserta': _namaPesertaController.text.trim(),
      'namaBurung': _namaBurungController.text.trim(),
      'kategori': widget.kategori,
      'dokumenUrl': dokumenUrl ?? '',
      'timestamp': FieldValue.serverTimestamp(),
      'checkinStatus': false,
    };

    try {
      await FirebaseFirestore.instance.collection('registrations').add(registrationData);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pendaftaran berhasil')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mendaftar: $e')),
      );
    }

    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _namaBurungController.dispose();
    _namaPesertaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Formulir Pendaftaran'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: ListView(
                  children: [
                    TextFormField(
                      controller: _namaPesertaController,
                      decoration: const InputDecoration(
                        labelText: 'Nama Peserta',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Wajib diisi';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _namaBurungController,
                      decoration: const InputDecoration(
                        labelText: 'Nama Burung',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Wajib diisi';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      enabled: false,
                      initialValue: widget.kategori,
                      decoration: const InputDecoration(
                        labelText: 'Kategori',
                        disabledBorder: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _pickDocument,
                      icon: const Icon(Icons.upload_file),
                      label: Text(_dokumenFile == null
                          ? 'Upload Dokumen (opsional)'
                          : 'Dokumen: ${_dokumenFile!.path.split('/').last}'),
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.deepPurple,
                      ),
                      child: const Text('Daftar'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
