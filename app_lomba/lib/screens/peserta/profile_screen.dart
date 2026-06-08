import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:app_lomba/routes.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final user = FirebaseAuth.instance.currentUser;
  Map<String, dynamic>? userData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();

      if (doc.exists) {
        setState(() {
          userData = doc.data();
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
          userData = null;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        userData = null;
      });
    }
  }

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, Routes.login);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profil"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : userData == null
              ? const Center(child: Text('Data pengguna tidak ditemukan.'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Center(
                        child: Icon(Icons.person, size: 100, color: Colors.grey),
                      ),
                      const SizedBox(height: 24),
                      Text("Nama", style: labelStyle),
                      Text(userData!['name'] ?? '-', style: valueStyle),
                      const SizedBox(height: 16),
                      Text("Email", style: labelStyle),
                      Text(user?.email ?? '-', style: valueStyle),
                      const SizedBox(height: 16),
                      Text("Role", style: labelStyle),
                      Text(userData!['role'] ?? '-', style: valueStyle),
                    ],
                  ),
                ),
    );
  }

  TextStyle get labelStyle => const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Colors.grey,
      );

  TextStyle get valueStyle => const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
      );
}
