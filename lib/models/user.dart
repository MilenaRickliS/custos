class UserModel {
  String uid;
  String nome;
  String razao;
  String email;
  String cnpj;
  String cep;
  String rua;
  String numero;
  String bairro;
  String complemento;
  String cidade;
  String estado;
  String telefone;
  String responsavel;
  String logo;

  UserModel({
    required this.uid,
    required this.nome,
    required this.razao,
    required this.email,
    required this.cnpj,
    required this.cep,
    required this.rua,
    required this.numero,
    required this.bairro,
    required this.complemento,
    required this.cidade,
    required this.estado,
    required this.telefone,
    required this.responsavel,
    required this.logo,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'],
      nome: map['nome'],
      razao: map['razao'],
      email: map['email'],
      cnpj: map['cnpj'],
      cep: map['cep'],
      rua: map['rua'],
      numero: map['numero'],
      bairro: map['bairro'],
      complemento: map['complemento'],
      cidade: map['cidade'],
      estado: map['estado'],
      telefone: map['telefone'],
      responsavel: map['responsavel'],
      logo: map['logo'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'nome': nome,
      'razao': razao,
      'email': email,
      'cnpj': cnpj,
      'cep': cep,
      'rua': rua,
      'numero': numero,
      'bairro': bairro,
      'complemento': complemento,
      'cidade': cidade,
      'estado': estado,
      'telefone': telefone,
      'responsavel': responsavel,
      'logo': logo,
    };
  }
}