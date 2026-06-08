import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:app_lomba/screens/panitia/pick_location_screen.dart';

class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({super.key});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _judulController = TextEditingController();
  final _tanggalController = TextEditingController();
  final _lokasiController = TextEditingController();
  final _penyelenggaraController = TextEditingController();
  final _teleponController = TextEditingController();
  final _kategoriController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  Map<String, dynamic>? _lokasiDipilih;
  final List<String> _kategoriList = [];
  File? _imageFile;

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _imageFile = File(picked.path);
      });
    }
  }

  Future<String?> _uploadImage(File file) async {
    try {
      final url = Uri.parse('https://api.cloudinary.com/v1_1/dafaxg4m1/image/upload');
      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = 'unsigned_preset'
        ..files.add(await http.MultipartFile.fromPath('file', file.path));

      final response = await request.send();
      final responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = json.decode(responseData);
        return data['secure_url'];
      } else {
        debugPrint('Upload gagal: ${response.statusCode} $responseData');
        return null;
      }
    } catch (e) {
      debugPrint('Upload error: $e');
      return null;
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_kategoriList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Minimal satu kategori harus ditambahkan')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final DateTime tanggalEvent = DateFormat('yyyy-MM-dd').parse(_tanggalController.text.trim());
      final bool isBerlangsung = tanggalEvent.isAfter(DateTime.now().subtract(const Duration(days: 1)));

      String? imageUrl;
      if (_imageFile != null) {
        imageUrl = await _uploadImage(_imageFile!);
        if (imageUrl == null) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal mengunggah gambar. Coba lagi.')),
          );
          return;
        }
      }

      final eventId = const Uuid().v4();
      final eventData = {
        'id': eventId,
        'judul': _judulController.text.trim(),
        'tanggal': _tanggalController.text.trim(),
        'lokasi': _lokasiController.text.trim(),
        'penyelenggara': _penyelenggaraController.text.trim(),
        'telepon': _teleponController.text.trim(),
        'isBerlangsung': isBerlangsung,
        'createdAt': Timestamp.now(),
        'latitude': _lokasiDipilih?['latitude'],
        'longitude': _lokasiDipilih?['longitude'],
        'lokasiNama': _lokasiDipilih?['lokasiNama'] ?? _lokasiController.text.trim(),
        'kategori': _kategoriList,
        'imageUrl': imageUrl,
      };

      await FirebaseFirestore.instance.collection('events').doc(eventId).set(eventData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Event berhasil dibuat')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal membuat event: $e')),
      );
    }

    setState(() => _isLoading = false);
  }

  Future<void> _pilihLokasi() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PickLocationScreen()),
    );
    if (result != null && mounted) {
      setState(() {
        _lokasiDipilih = result;
        _lokasiController.text = result['lokasiNama'];
      });
    }
  }

  @override
  void dispose() {
    _judulController.dispose();
    _tanggalController.dispose();
    _lokasiController.dispose();
    _penyelenggaraController.dispose();
    _teleponController.dispose();
    _kategoriController.dispose();
    super.dispose();
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    String? hint,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
      ),
      keyboardType: keyboardType,
      validator: validator ?? (value) => value!.isEmpty ? 'Wajib diisi' : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buat Event Baru'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildTextField(_judulController, 'Judul Event'),
                      const SizedBox(height: 12),
                      TextFormField(
                          controller: _tanggalController,
                          readOnly: true,
                          decoration: const InputDecoration(
                            labelText: 'Tanggal Event (yyyy-MM-dd)',
                            hintText: 'Contoh: 2025-06-10',
                            border: OutlineInputBorder(),
                            suffixIcon: Icon(Icons.calendar_today),
                          ),
                          onTap: () async {
                            final pickedDate = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2100),
                            );
                            if (pickedDate != null) {
                              _tanggalController.text = DateFormat('yyyy-MM-dd').format(pickedDate);
                            }
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Wajib diisi';
                            try {
                              DateFormat('yyyy-MM-dd').parse(value);
                            } catch (_) {
                              return 'Format tanggal salah';
                            }
                            return null;
                          },
                        ),
                      const SizedBox(height: 12),
                      _buildTextField(_penyelenggaraController, 'Nama Penyelenggara'),
                      const SizedBox(height: 12),
                      _buildTextField(
                        _teleponController,
                        'Nomor Telepon',
                        keyboardType: TextInputType.phone,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Lokasi Event', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _lokasiController,
                        decoration: const InputDecoration(
                          labelText: 'Nama Lokasi',
                          border: OutlineInputBorder(),
                        ),
                        readOnly: true,
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.map),
                          label: const Text('Pilih Lokasi di Peta'),
                          onPressed: _pilihLokasi,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text('Foto Event', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 12),
                      if (_imageFile != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(_imageFile!, height: 180, fit: BoxFit.cover),
                        )
                      else
                        const Text('Belum ada gambar dipilih'),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.image),
                        label: const Text('Upload Gambar'),
                        onPressed: _pickImage,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Kategori Lomba', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _kategoriController,
                        decoration: InputDecoration(
                          labelText: 'Tambah Kategori',
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: () {
                              final text = _kategoriController.text.trim();
                              if (text.isNotEmpty && !_kategoriList.contains(text)) {
                                setState(() {
                                  _kategoriList.add(text);
                                  _kategoriController.clear();
                                });
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        children: _kategoriList
                            .map((kategori) => Chip(
                                  label: Text(kategori),
                                  onDeleted: () => setState(() => _kategoriList.remove(kategori)),
                                ))
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _submit,
                        icon: const Icon(Icons.check),
                        label: const Text('Simpan Event'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
