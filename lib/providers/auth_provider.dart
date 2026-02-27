import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/user.dart';

class AuthFailure implements Exception {
  final String message;
  AuthFailure(this.message);
  @override
  String toString() => message;
}

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  UserModel? _user;
  UserModel? get user => _user;

  Future<void> signIn(String email, String password) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = result.user?.uid;
      if (uid == null) {
        throw AuthFailure("Não foi possível autenticar. Tente novamente.");
      }

      final doc = await _firestore.collection('usuarios').doc(uid).get();

      if (!doc.exists || doc.data() == null) {
        
        await _auth.signOut();
        throw AuthFailure("Seu cadastro não foi encontrado. Contate o suporte.");
      }

      _user = UserModel.fromMap(doc.data()!);
      notifyListeners();
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_mapFirebaseAuthError(e));
    } on FirebaseException catch (_) {
      throw AuthFailure("Falha ao acessar o servidor. Verifique sua internet.");
    } catch (_) {
      throw AuthFailure("Ocorreu um erro inesperado. Tente novamente.");
    }
  }

  String _mapFirebaseAuthError(FirebaseAuthException e) {
    final code = e.code.toLowerCase();

    switch (code) {
      case 'invalid-email':
        return "E-mail inválido.";
      case 'user-disabled':
        return "Esta conta foi desativada.";
      case 'user-not-found':
        return "E-mail não cadastrado.";
      case 'wrong-password':
        return "Senha incorreta.";
      case 'invalid-credential':
       
        return "E-mail ou senha incorretos.";
      case 'too-many-requests':
        return "Muitas tentativas. Aguarde um pouco e tente novamente.";
      case 'network-request-failed':
        return "Sem conexão. Verifique sua internet.";
      default:
        return "Não foi possível entrar (${e.code}).";
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_mapFirebaseAuthError(e));
    } catch (_) {
      throw AuthFailure("Erro ao enviar e-mail de recuperação.");
    }
  }

  Future<void> register({
    required String nome,
    required String razao,
    required String email,
    required String senha,
    required String cnpj,
    required String cep,
    required String rua,
    required String numero,
    required String bairro,
    String? complemento,
    required String cidade,
    required String estado,
    required String telefone,
    required String responsavel,
    String? logo,
  }) async {
    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: senha,
      );

      final uid = result.user!.uid;

      await _firestore.collection('usuarios').doc(uid).set({
        'uid': uid,
        'nome': nome,
        'razao': razao,
        'email': email,
        'cnpj': cnpj,
        'cep': cep,
        'rua': rua,
        'numero': numero,
        'bairro': bairro,
        'complemento': complemento ?? '',
        'cidade': cidade,
        'estado': estado,
        'telefone': telefone,
        'responsavel': responsavel,
        'logo': logo ?? '',
        'criadoEm': DateTime.now(),
      });

      final doc = await _firestore.collection('usuarios').doc(uid).get();
      _user = UserModel.fromMap(doc.data()!);
      notifyListeners();
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_mapFirebaseAuthError(e));
    } catch (_) {
      throw AuthFailure("Erro ao registrar. Tente novamente.");
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    _user = null;
    notifyListeners();
  }

  Future<void> logout() async => signOut();

  Future<void> updateProfile({
    required String nome,
    required String razao,
    required String telefone,
    required String responsavel,
    required String cep,
    required String rua,
    required String numero,
    required String bairro,
    required String complemento,
    required String cidade,
    required String estado,
    String? logo,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw AuthFailure("Usuário não autenticado.");

    final data = <String, dynamic>{
      'nome': nome,
      'razao': razao,
      'telefone': telefone,
      'responsavel': responsavel,
      'cep': cep,
      'rua': rua,
      'numero': numero,
      'bairro': bairro,
      'complemento': complemento,
      'cidade': cidade,
      'estado': estado,
    };

    if (logo != null) data['logo'] = logo;

    await _firestore.collection('usuarios').doc(uid).update(data);

   
    _user = UserModel(
      uid: _user!.uid,
      nome: nome,
      razao: razao,
      email: _user!.email,
      cnpj: _user!.cnpj,
      cep: cep,
      rua: rua,
      numero: numero,
      bairro: bairro,
      complemento: complemento,
      cidade: cidade,
      estado: estado,
      telefone: telefone,
      responsavel: responsavel,
      logo: logo ?? _user!.logo,
    );

    notifyListeners();
  }
}
