
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ScanHistoryService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Current logged-in user's UID
  String get _uid {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw StateError('Please login first');
    }

    return user.uid;
  }

  // Each user's private scan collection
  CollectionReference<Map<String, dynamic>> get _scans {
    return _db
        .collection('users')
        .doc(_uid)
        .collection('scans');
  }

  // Save AI result
  Future<void> saveScan({
    required String analysis,
  }) async {
    final cleanText = analysis.trim();

    if (cleanText.isEmpty) {
      throw ArgumentError('Analysis cannot be empty');
    }

    await _scans.add({
      'analysis': cleanText,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Read scan history (latest first)
  Stream<QuerySnapshot<Map<String, dynamic>>> watchScans() {
    return _scans
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Delete an individual scan
  Future<void> deleteScan(String scanId) async {
    await _scans.doc(scanId).delete();
  }
}
