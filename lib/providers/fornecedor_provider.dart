import 'package:cloud_firestore/cloud_firestore.dart';

class FornecedorProvider {
  final FirebaseFirestore firestore;
  FornecedorProvider({FirebaseFirestore? firestore})
      : firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _col(String uid) {
    return firestore.collection('usuarios').doc(uid).collection('fornecedores');
  }

  CollectionReference<Map<String, dynamic>> _mpCol(String uid) {
    return firestore.collection('usuarios').doc(uid).collection('materias_primas');
  }

  Stream<List<String>> streamNomes(String uid) {
    return _col(uid).orderBy('nome').snapshots().map((snap) {
      return snap.docs
          .map((d) => (d.data()['nome'] ?? '').toString())
          .where((n) => n.trim().isNotEmpty)
          .toList();
    });
  }

  Future<void> addFornecedor(String uid, String nome) async {
    final clean = nome.trim();
    if (clean.isEmpty) return;

    final existing =
        await _col(uid).where('nome', isEqualTo: clean).limit(1).get();
    if (existing.docs.isNotEmpty) return;

    await _col(uid).add({
      'nome': clean,
      'createdAt': DateTime.now().toUtc().millisecondsSinceEpoch,
    });
  }

 
  Future<void> renameFornecedor(
    String uid, {
    required String oldName,
    required String newName,
    bool updateMateriasPrimas = true,
  }) async {
    final oldClean = oldName.trim();
    final newClean = newName.trim();
    if (oldClean.isEmpty || newClean.isEmpty) return;
    if (oldClean == newClean) return;

  
    final dup = await _col(uid).where('nome', isEqualTo: newClean).limit(1).get();
    if (dup.docs.isNotEmpty) {
      throw Exception('Já existe um fornecedor com este nome.');
    }

 
    final q = await _col(uid).where('nome', isEqualTo: oldClean).limit(1).get();
    if (q.docs.isEmpty) {
      throw Exception('Fornecedor não encontrado.');
    }

    final fornecedorDoc = q.docs.first.reference;

    final batch = firestore.batch();
    batch.update(fornecedorDoc, {
      'nome': newClean,
      'updatedAt': DateTime.now().toUtc().millisecondsSinceEpoch,
    });

   
    if (updateMateriasPrimas) {
      final mps = await _mpCol(uid)
          .where('fornecedor', isEqualTo: oldClean)
          .get();

      for (final doc in mps.docs) {
        batch.update(doc.reference, {'fornecedor': newClean});
      }
    }

    await batch.commit();
  }

 
  Future<void> deleteFornecedor(
    String uid, {
    required String name,
    bool removeFromMateriasPrimas = true,
  }) async {
    final clean = name.trim();
    if (clean.isEmpty) return;

    final q = await _col(uid).where('nome', isEqualTo: clean).limit(1).get();
    if (q.docs.isEmpty) return;

    final fornecedorDoc = q.docs.first.reference;

    final batch = firestore.batch();
    batch.delete(fornecedorDoc);

    if (removeFromMateriasPrimas) {
      final mps = await _mpCol(uid).where('fornecedor', isEqualTo: clean).get();
      for (final doc in mps.docs) {
        batch.update(doc.reference, {'fornecedor': ''});
      }
    }

    await batch.commit();
  }
}