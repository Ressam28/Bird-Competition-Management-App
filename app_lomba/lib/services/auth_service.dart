import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ---------------- LOGIN ----------------
  Future<String?> loginWithEmail(String email, String password) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = result.user!.uid;

      // role = panitia?
      if ((await _firestore.collection('admin').doc(uid).get()).exists) {
        return 'panitia';
      }

      // role = peserta?
      if ((await _firestore.collection('users').doc(uid).get()).exists) {
        return 'peserta';
      }

      // Auth ok, tetapi tidak ada di Firestore
      throw FirebaseAuthException(
        code: 'user-not-found-in-firestore',
        message: 'Akun ditemukan di Auth tetapi tidak terdaftar di Firestore.',
      );
    } on FirebaseAuthException catch (e) {
      // biar LoginScreen bisa switch–case pakai e.code
      rethrow;
    } catch (e) {
      // error lain (mis. koneksi putus) → bungkus sebagai FirebaseAuthException
      throw FirebaseAuthException(
        code: 'unknown',
        message: e.toString(),
      );
    }
  }

  // ---------------- GET ROLE LANGSUNG ----------------
  Future<String?> getUserRole(String uid) async {
    try {
      if ((await _firestore.collection('admin').doc(uid).get()).exists) {
        return 'panitia';
      }
      if ((await _firestore.collection('users').doc(uid).get()).exists) {
        return 'peserta';
      }
      return null;
    } catch (e) {
      throw Exception('Gagal mengambil role: $e');
    }
  }

  // ---------------- REGISTER ----------------
  Future<User?> registerWithEmail({
    required String name,
    required String email,
    required String password,
    required String role, // 'peserta' | 'panitia'
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = cred.user;

      if (user == null) {
        throw FirebaseAuthException(
          code: 'user-creation-failed',
          message: 'User tidak berhasil dibuat.',
        );
      }

      final data = {
        'uid': user.uid,
        'name': name,
        'email': email,
        'role': role,
        'createdAt': Timestamp.now(),
      };

      final col = role == 'panitia' ? 'admin' : 'users';
      await _firestore.collection(col).doc(user.uid).set(data);

      return user;
    } on FirebaseAuthException catch (e) {
      rethrow;
    } catch (e) {
      throw FirebaseAuthException(
        code: 'unknown-error',
        message: e.toString(),
      );
    }
  }

  // ---------------- LOGOUT ----------------
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
