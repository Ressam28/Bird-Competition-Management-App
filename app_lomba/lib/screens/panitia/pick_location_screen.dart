import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';

class PickLocationScreen extends StatefulWidget {
  const PickLocationScreen({super.key});

  @override
  State<PickLocationScreen> createState() => _PickLocationScreenState();
}

class _PickLocationScreenState extends State<PickLocationScreen> {
  LatLng _initialCenter = LatLng(-6.1754, 106.8272); // Monas
  LatLng? _selectedLocation;
  String _lokasiNama = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _setupLocation();
  }

  Future<void> _setupLocation() async {
    final status = await Permission.location.request();
    if (status.isGranted) {
      try {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        setState(() {
          _initialCenter = LatLng(position.latitude, position.longitude);
        });
      } catch (e) {
        debugPrint("Gagal mendapatkan lokasi device: $e");
      }
    } else {
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Izin Diperlukan'),
          content: const Text('Aplikasi memerlukan izin lokasi untuk memilih lokasi di peta.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }

    setState(() => _isLoading = false);
  }

  Future<void> _getPlaceName(LatLng latLng) async {
    try {
      final placemarks = await placemarkFromCoordinates(latLng.latitude, latLng.longitude);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        setState(() {
          _lokasiNama = '${place.name ?? ''}, ${place.locality ?? ''}, ${place.administrativeArea ?? ''}';
        });
      }
    } catch (_) {
      setState(() => _lokasiNama = 'Lokasi dipilih');
    }
  }

  void _onTapMap(LatLng latLng) {
    setState(() => _selectedLocation = latLng);
    _getPlaceName(latLng);
  }

  void _confirmLocation() {
    if (_selectedLocation != null) {
      Navigator.pop(context, {
        'latitude': _selectedLocation!.latitude,
        'longitude': _selectedLocation!.longitude,
        'lokasiNama': _lokasiNama,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pilih Lokasi')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                FlutterMap(
                  options: MapOptions(
                    center: _initialCenter,
                    zoom: 15.0,
                    onTap: (tapPosition, latlng) => _onTapMap(latlng),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                      subdomains: const ['a', 'b', 'c'],
                    ),
                    if (_selectedLocation != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            width: 80,
                            height: 80,
                            point: _selectedLocation!,
                            child: const Icon(
                              Icons.location_on,
                              color: Colors.red,
                              size: 40,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                if (_selectedLocation != null)
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: ElevatedButton(
                      onPressed: _confirmLocation,
                      child: const Text('Gunakan Lokasi Ini'),
                    ),
                  ),
              ],
            ),
    );
  }
}
