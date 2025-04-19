import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Create or update user profile data
  Future<void> saveUserProfile(UserProfile profile) async {
    if (currentUserId == null) {
      throw Exception('No authenticated user found');
    }

    await _firestore
        .collection('users')
        .doc(currentUserId)
        .set(profile.toMap(), SetOptions(merge: true));
  }

  // Get user profile data
  Future<Map<String, dynamic>?> getUserProfile() async {
    if (currentUserId == null) {
      return null;
    }

    final docSnapshot =
        await _firestore.collection('users').doc(currentUserId).get();
    return docSnapshot.data();
  }
}
