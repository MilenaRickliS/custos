import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/materia_prima_model.dart';

class MateriaPrimaProvider extends ChangeNotifier {
  final FirebaseFirestore firestore;

  MateriaPrimaProvider({FirebaseFirestore? firestore})
      : firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _col(String uid) {
    return firestore.collection('usuarios').doc(uid).collection('materias_primas');
  }

  Stream<List<MateriaPrimaModel>> streamAll(String uid) {
    return _col(uid).orderBy('nome').snapshots().map((snap) {
      return snap.docs.map((d) => MateriaPrimaModel.fromMap(d.data(), d.id)).toList();
    });
  }

  Future<void> create(String uid, MateriaPrimaModel mp) async {
    final col = _col(uid);
    final docRef = col.doc(); 
    await docRef.set(mp.toMapForCreate());
  }

  Future<void> update(String uid, MateriaPrimaModel mp) async {
    final ref = _col(uid).doc(mp.id);
    await ref.update(mp.toMapForUpdate());
  }

  Future<void> delete(String uid, String id) async {
    await _col(uid).doc(id).delete();
  }
}