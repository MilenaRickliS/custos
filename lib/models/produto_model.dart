import 'package:cloud_firestore/cloud_firestore.dart';

class ProdutoItemModel {
  final String mpId;
  final String mpNome; 
  final String unidade; 
  final double quantidade; 

  ProdutoItemModel({
    required this.mpId,
    required this.mpNome,
    required this.unidade,
    required this.quantidade,
  });

  Map<String, dynamic> toMap() => {
        'mpId': mpId,
        'mpNome': mpNome,
        'unidade': unidade,
        'quantidade': quantidade,
      };

  factory ProdutoItemModel.fromMap(Map<String, dynamic> map) {
    return ProdutoItemModel(
      mpId: (map['mpId'] ?? '').toString(),
      mpNome: (map['mpNome'] ?? '').toString(),
      unidade: (map['unidade'] ?? '').toString(),
      quantidade: (map['quantidade'] is num) ? (map['quantidade'] as num).toDouble() : 0.0,
    );
  }
}

class ProdutoModel {
  final String id;
  final String nome;
  final List<ProdutoItemModel> items;
  final int createdAt;
  final int updatedAt;

  ProdutoModel({
    required this.id,
    required this.nome,
    required this.items,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
        'nome': nome,
        'items': items.map((e) => e.toMap()).toList(),
        'createdAt': createdAt,
        'updatedAt': updatedAt,
      };

  factory ProdutoModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final rawItems = (data['items'] as List?) ?? const [];
    return ProdutoModel(
      id: doc.id,
      nome: (data['nome'] ?? '').toString(),
      items: rawItems
          .whereType<Map>()
          .map((m) => ProdutoItemModel.fromMap(Map<String, dynamic>.from(m)))
          .toList(),
      createdAt: (data['createdAt'] is num) ? (data['createdAt'] as num).toInt() : 0,
      updatedAt: (data['updatedAt'] is num) ? (data['updatedAt'] as num).toInt() : 0,
    );
  }
}