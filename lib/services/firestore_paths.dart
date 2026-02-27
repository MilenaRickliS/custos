import 'package:cloud_firestore/cloud_firestore.dart';

class FirestorePaths {
  final FirebaseFirestore _db;
  FirestorePaths(this._db);

  CollectionReference<Map<String, dynamic>> produtos(String uid) =>
      _db.collection("usuarios").doc(uid).collection("produtos");

  CollectionReference<Map<String, dynamic>> mp(String uid) =>
      _db.collection("usuarios").doc(uid).collection("mp");
}