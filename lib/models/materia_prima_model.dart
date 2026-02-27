class MateriaPrimaModel {
  final String id;
  final String nome;
  final String fornecedor;
  final double custo;
  final String unidade;
  final int? createdAt;
  final int? updatedAt;

  MateriaPrimaModel({
    required this.id,
    required this.nome,
    required this.fornecedor,
    required this.custo,
    required this.unidade,
    this.createdAt,
    this.updatedAt,
  });

  factory MateriaPrimaModel.fromMap(Map<String, dynamic> map, String id) {
    return MateriaPrimaModel(
      id: id,
      nome: (map['nome'] ?? '').toString(),
      fornecedor: (map['fornecedor'] ?? '').toString(),
      unidade: (map['unidade'] ?? 'kg').toString(),
      custo: (map['custo'] == null)
          ? 0.0
          : (map['custo'] is num ? (map['custo'] as num).toDouble() : double.tryParse(map['custo'].toString()) ?? 0.0),
      createdAt: map['createdAt'] != null ? (map['createdAt'] as num).toInt() : null,
      updatedAt: map['updatedAt'] != null ? (map['updatedAt'] as num).toInt() : null,
    );
  }

  Map<String, dynamic> toMapForCreate() {
    final ts = DateTime.now().toUtc().millisecondsSinceEpoch;
    return {
      'nome': nome,
      'fornecedor': fornecedor,
      'custo': custo,
      'unidade': unidade,      
      'createdAt': ts,
      'updatedAt': ts,
    };
  }

  Map<String, dynamic> toMapForUpdate() {
    final ts = DateTime.now().toUtc().millisecondsSinceEpoch;
    return {
      'nome': nome,
      'fornecedor': fornecedor,
      'custo': custo,
      'unidade': unidade,
      'updatedAt': ts,
    };
  }
}