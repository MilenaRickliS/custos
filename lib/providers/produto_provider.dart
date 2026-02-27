import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/produto_model.dart';

class ProdutoProvider {
  final FirebaseFirestore firestore;
  ProdutoProvider({FirebaseFirestore? firestore})
      : firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _col(String uid) {
    return firestore.collection('usuarios').doc(uid).collection('produtos');
  }

  Stream<List<ProdutoModel>> streamAll(String uid) {
    return _col(uid).orderBy('nome').snapshots().map((snap) {
      return snap.docs.map((d) => ProdutoModel.fromDoc(d)).toList();
    });
  }

  Future<void> create(String uid, {required String nome, required List<ProdutoItemModel> items}) async {
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    await _col(uid).add({
      'nome': nome.trim(),
      'items': items.map((e) => e.toMap()).toList(),
      'createdAt': now,
      'updatedAt': now,
    });
  }

  Future<void> update(String uid, ProdutoModel p) async {
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    await _col(uid).doc(p.id).update({
      'nome': p.nome.trim(),
      'items': p.items.map((e) => e.toMap()).toList(),
      'updatedAt': now,
    });
  }

  Future<void> delete(String uid, String id) async {
    await _col(uid).doc(id).delete();
  }
}