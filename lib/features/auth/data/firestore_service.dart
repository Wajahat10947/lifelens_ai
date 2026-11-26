import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:typed_data';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> ensureUserProfile(User user) async {
    final ref = _db.collection('users').doc(user.uid);

    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);

      if (!snapshot.exists) {
        transaction.set(ref, {
          'uid': user.uid,
          'email': user.email,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    final snapshot = await _db.collection('users').doc(uid).get();

    return snapshot.data();
  }

  Future<void> updateUserProfile(
    String uid,
    String name, {
    Uint8List? photo,
  }) async {
    await _db.collection('users').doc(uid).update({
      'name': name.trim(),
      if (photo != null) 'photo': Blob(photo),
    });
  }
}
