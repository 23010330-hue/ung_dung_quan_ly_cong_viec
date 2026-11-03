import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:todoapp/models/user_profile.dart';


class UserRepository {
  final FirebaseFirestore db;

  UserRepository(this.db);

  static String nameKey(String username) {
    return username.trim().toLowerCase();
  }


  Future<UserProfile?> getProfile(String uid) async {
    final snapshot = await db.collection('users').doc(uid).get();
    final data = snapshot.data();
    if (data == null) {
      return null;
    }
    final profile = UserProfile.fromMap(data);
    if (!profile.hasUsername) {
      return null;
    }
    return profile;
  }

  
  Future<UsernameEntry?> getUsername(String username) async {
    final snapshot = await db.collection('usernames').doc(nameKey(username)).get();
    final data = snapshot.data();
    if (data == null) {
      return null;
    }
    return UsernameEntry.fromMap(data);
  }

  Future<bool> usernameExists(String username) async {
    final snapshot = await db.collection('usernames').doc(nameKey(username)).get();
    return snapshot.exists;
  }

  
  Future<bool> claimUsername({
    required String uid,
    required String username,
    required String email,
    required bool viaSocial,
  }) {
    final nameRef = db.collection('usernames').doc(nameKey(username));
    final userRef = db.collection('users').doc(uid);
    final entry = UsernameEntry(uid: uid, email: email, viaSocial: viaSocial);
    final profile = UserProfile(
      username: username,
      email: email,
      viaSocial: viaSocial,
    );

    return db.runTransaction((transaction) async {
      final snapshot = await transaction.get(nameRef);
      if (snapshot.exists) {
        return false;
      }

      transaction.set(nameRef, entry.toMap());

      final profileData = profile.toMap();
      profileData['createdAt'] = FieldValue.serverTimestamp();
      transaction.set(userRef, profileData);

      return true;
    });
  }
}
