// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';


class CadastroScreen extends StatefulWidget {
  const CadastroScreen({super.key});

  @override
  State<CadastroScreen> createState() => _CadastroScreenState();
}

class _CadastroScreenState extends State<CadastroScreen> {

  final FocusNode _numeroFocus = FocusNode();

  
  final _cnpjMask = MaskTextInputFormatter(
    mask: '##.###.###/####-##',
    filter: {"#": RegExp(r'[0-9]')},
  );

  final _phoneMask = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {"#": RegExp(r'[0-9]')},
  );

  final _cepMask = MaskTextInputFormatter(
    mask: '##.###-###',
    filter: {"#": RegExp(r'[0-9]')},
  );

 
  final RegExp _lettersAccentsAndNumbers = RegExp(r"^[A-Za-zÀ-ÿ0-9çÇ ]+$");
  final RegExp _lettersAccentsOnly = RegExp(r"^[A-Za-zÀ-ÿçÇ ]+$");
  final RegExp _onlyDigits = RegExp(r"^[0-9]+$");
  final RegExp _emailRegex = RegExp(r"^[^\s@]+@[^\s@]+\.[^\s@]+$");
  final RegExp _urlRegex = RegExp(r"^https?:\/\/[^\s/$.?#].[^\s]*$", caseSensitive: false);


  final _formKey = GlobalKey<FormState>();

  final nome = TextEditingController();
  final razao = TextEditingController();
  final email = TextEditingController();
  final senha = TextEditingController();
  final cnpj = TextEditingController();
  final cep = TextEditingController();
  final rua = TextEditingController();
  final numero = TextEditingController();
  final bairro = TextEditingController();
  final complemento = TextEditingController();
  final cidade = TextEditingController();
  final estado = TextEditingController();
  final telefone = TextEditingController();
  final responsavel = TextEditingController();
  final logo = TextEditingController();

  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _numeroFocus.dispose();
    nome.dispose();
    razao.dispose();
    email.dispose();
    senha.dispose();
    cnpj.dispose();
    cep.dispose();
    rua.dispose();
    numero.dispose();
    bairro.dispose();
    complemento.dispose();
    cidade.dispose();
    estado.dispose();
    telefone.dispose();
    responsavel.dispose();
    logo.dispose();
    super.dispose();
  }

  String? _vNome(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return "Nome não pode ser vazio.";
    if (!_lettersAccentsAndNumbers.hasMatch(s)) {
      return "Nome só pode conter letras, acentos, ç e números.";
    }
    return null;
  }

  String? _vRazao(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return "Razão social não pode ser vazia.";
    if (!_lettersAccentsAndNumbers.hasMatch(s)) {
      return "Razão social só pode conter letras, acentos, ç e números.";
    }
    return null;
  }

  String? _vEmail(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return "E-mail não pode ser vazio.";
    if (!_emailRegex.hasMatch(s)) return "E-mail inválido. Ex: x@x.com";
    return null;
  }

  String? _vSenha(String? v) {
    final s = (v ?? '');
    if (s.isEmpty) return "Senha não pode ser vazia.";
    if (s.length < 6) return "Senha deve ter mais de 6 caracteres.";
    return null;
  }

  String? _vCnpj(String? v) {
    final digits = _cnpjMask.getUnmaskedText(); 
    if (digits.trim().isEmpty) return "CNPJ não pode ser vazio.";
    if (digits.length != 14) return "CNPJ inválido. Use: xx.xxx.xxx/xxxx-xx";
    if (!_onlyDigits.hasMatch(digits)) return "CNPJ deve conter apenas números.";
    return null;
  }

  String? _vTelefone(String? v) {
    final digits = _phoneMask.getUnmaskedText();
    if (digits.trim().isEmpty) return "Telefone não pode ser vazio.";
    if (digits.length != 11) return "Telefone inválido. Use: (xx) xxxxx-xxxx";
    if (!_onlyDigits.hasMatch(digits)) return "Telefone deve conter apenas números.";
    return null;
  }

  String? _vResponsavel(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return "Responsável não pode ser vazio.";
    if (!_lettersAccentsOnly.hasMatch(s)) {
      return "Responsável só pode conter letras, acentos e ç.";
    }
    return null;
  }

  String? _vCep(String? v) {
    final digits = _cepMask.getUnmaskedText();
    if (digits.trim().isEmpty) return "CEP não pode ser vazio.";
    if (digits.length != 8) return "CEP inválido. Use: xx.xxx-xxx";
    if (!_onlyDigits.hasMatch(digits)) return "CEP deve conter apenas números.";
    return null;
  }

  String? _vRua(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return "Rua não pode ser vazia.";
    if (!_lettersAccentsAndNumbers.hasMatch(s)) {
      return "Rua só pode conter letras, acentos, ç e números.";
    }
    return null;
  }

  String? _vNumero(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return "Número não pode ser vazio.";
    if (!_onlyDigits.hasMatch(s)) return "Número deve conter apenas números.";
    return null;
  }

  String? _vBairro(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return "Bairro não pode ser vazio.";
    return null;
  }

  String? _vCidade(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return "Cidade não pode ser vazia.";
    if (!_lettersAccentsOnly.hasMatch(s)) {
      return "Cidade só pode conter letras, acentos e ç.";
    }
    return null;
  }

  String? _vEstado(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return "Estado não pode ser vazio.";
    if (!_lettersAccentsOnly.hasMatch(s)) {
      return "Estado só pode conter letras, acentos e ç.";
    }
    return null;
  }

  String? _vLogo(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return null; 
    if (!_urlRegex.hasMatch(s)) return "Logo deve ser um link válido (http/https).";
    return null;
  }


  Future<void> _cadastrar() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      await context.read<AuthProvider>().register(
            nome: nome.text.trim(),
            razao: razao.text.trim(),
            email: email.text.trim(),
            senha: senha.text,
            cnpj: _cnpjMask.getUnmaskedText(),
            telefone: _phoneMask.getUnmaskedText(),
            cep: _cepMask.getUnmaskedText(),
          
            rua: rua.text.trim(),
            numero: numero.text.trim(),
            bairro: bairro.text.trim(),
            complemento: complemento.text.trim(),
            cidade: cidade.text.trim(),
            estado: estado.text.trim(),
            
            responsavel: responsavel.text.trim(),
            logo: logo.text.trim(),
          );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Cadastro realizado!")),
      );

      Navigator.pushNamedAndRemoveUntil(context, '/produtos', (_) => false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro ao cadastrar: $e")),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _field({
    FocusNode? focusNode,
    required TextEditingController c,
    required String label,
    TextInputType? type,
    String? Function(String?)? validator,
    bool obscure = false,
    Widget? prefixIcon,
    Widget? suffixIcon,
    List<TextInputFormatter>? inputFormatters,
    void Function(String)? onChanged,
    bool enabled = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: c,
        keyboardType: type,
        obscureText: obscure,
        enabled: enabled,
        inputFormatters: inputFormatters,
        focusNode: focusNode,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.black54),
          floatingLabelStyle: const TextStyle(
            color: Color(0xFF54A73B),
            fontWeight: FontWeight.w600,
          ),
          filled: true,
          fillColor: Colors.white.withOpacity(0.85),
          prefixIcon: prefixIcon,
          suffixIcon: suffixIcon,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.black.withOpacity(0.15)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF54A73B), width: 1.8),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 1.5),
          ),
        ),
        validator: validator,
      ),
    );
  }


  bool _cepLoading = false;
  String _lastCepFetched = "";

  Future<void> _buscarCep(String rawCepDigits) async {
  
    if (rawCepDigits.length != 8) return;
    if (rawCepDigits == _lastCepFetched) return;

    setState(() => _cepLoading = true);

    try {
      final url = Uri.parse("https://viacep.com.br/ws/$rawCepDigits/json/");
      final res = await http.get(url);

      if (res.statusCode != 200) {
        throw Exception("Falha ao consultar CEP.");
      }

      final data = json.decode(res.body) as Map<String, dynamic>;
      if (data['erro'] == true) {
        throw Exception("CEP não encontrado.");
      }

      rua.text = (data['logradouro'] ?? '').toString();
      bairro.text = (data['bairro'] ?? '').toString();
      cidade.text = (data['localidade'] ?? '').toString();
      estado.text = (data['uf'] ?? '').toString();

    
      
     

      _lastCepFetched = rawCepDigits;
      // ignore: use_build_context_synchronously
      FocusScope.of(context).requestFocus(_numeroFocus);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro no CEP: $e")),
      );
    } finally {
      if (mounted) setState(() => _cepLoading = false);
    }
    

  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF7ED),
      appBar: AppBar(
        title: const Text("Cadastro", style: TextStyle(fontWeight: FontWeight.w600),),
        backgroundColor: const Color(0xFFFDF7ED),
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child:
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/Logo2.png',
                  height: 110,
                ),

                const SizedBox(height: 16), 
              Card(
                color: Colors.white,
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _field(
                            c: nome,
                            label: "Nome (fantasia)",
                            validator: _vNome,
                            prefixIcon: const Icon(Icons.storefront_outlined),
                          ),
                        _field(
                          c: razao,
                          label: "Razão social",
                          validator: _vRazao,
                          prefixIcon: const Icon(Icons.business_outlined),
                        ),
                        _field(
                          c: email,
                          label: "E-mail",
                          type: TextInputType.emailAddress,
                          validator: _vEmail,
                          prefixIcon: const Icon(Icons.email_outlined),
                        ),
                        _field(
                          c: senha,
                          label: "Senha",
                          obscure: _obscure,
                          validator: _vSenha,
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            onPressed: () => setState(() => _obscure = !_obscure),
                            icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                          ),
                        ),

                        const Divider(height: 24),

                        _field(
                          c: cnpj,
                          label: "CNPJ",
                          type: TextInputType.number,
                          validator: _vCnpj,
                          inputFormatters: [_cnpjMask],
                          prefixIcon: const Icon(Icons.badge_outlined),
                        ),
                        _field(
                          c: telefone,
                          label: "Telefone",
                          type: TextInputType.phone,
                          validator: _vTelefone,
                          inputFormatters: [_phoneMask],
                          prefixIcon: const Icon(Icons.phone_outlined),
                        ),
                        _field(
                          c: responsavel,
                          label: "Responsável",
                          validator: _vResponsavel,
                          prefixIcon: const Icon(Icons.person_outline),
                        ),

                        const Divider(height: 24),

                        _field(
                          c: cep,
                          label: "CEP",
                          type: TextInputType.number,
                          validator: _vCep,
                          inputFormatters: [_cepMask],
                          prefixIcon: const Icon(Icons.location_on_outlined),
                          suffixIcon: _cepLoading
                              ? const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                                )
                              : IconButton(
                                  tooltip: "Buscar CEP",
                                  onPressed: () => _buscarCep(_cepMask.getUnmaskedText()),
                                  icon: const Icon(Icons.search),
                                ),
                          onChanged: (_) {
                            final digits = _cepMask.getUnmaskedText();
                            if (digits.length == 8) _buscarCep(digits);
                          },
                        ),
                        _field(
                          c: rua,
                          label: "Rua",
                          validator: _vRua,
                          prefixIcon: const Icon(Icons.signpost_outlined),
                        ),
                       _field(
                          c: numero,
                          label: "Número",
                          type: TextInputType.number,
                          validator: _vNumero,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          prefixIcon: const Icon(Icons.tag_outlined),
                          focusNode: _numeroFocus,
                        ),
                        _field(
                          c: bairro,
                          label: "Bairro",
                          validator: _vBairro,
                          prefixIcon: const Icon(Icons.map_outlined),
                        ),
                        _field(
                          c: complemento,
                          label: "Complemento (opcional)",
                          validator: (_) => null,
                          prefixIcon: const Icon(Icons.add_location_alt_outlined),
                        ),
                        _field(
                          c: cidade,
                          label: "Cidade",
                          validator: _vCidade,
                          prefixIcon: const Icon(Icons.location_city_outlined),
                        ),

                        _field(
                          c: estado,
                          label: "Estado (UF)",
                          validator: _vEstado,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r"[A-Za-zÀ-ÿçÇ]")),
                            LengthLimitingTextInputFormatter(2),
                          ],

                          prefixIcon: const Icon(Icons.flag_outlined),
                          onChanged: (v) {
                            
                            final up = v.toUpperCase();
                            if (up != v) {
                              estado.value = estado.value.copyWith(
                                text: up,
                                selection: TextSelection.collapsed(offset: up.length),
                              );
                            }
                          },
                        ),
                        _field(
                          c: logo,
                          label: "Logo (URL) (opcional)",
                          validator: _vLogo,
                          type: TextInputType.url,
                          prefixIcon: const Icon(Icons.image_outlined),
                        ),
                        const SizedBox(height: 8),

                        ElevatedButton(
                          onPressed: _loading ? null : _cadastrar,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:const Color(0xFF54A73B),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          
                          ),

                          child: _loading
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text("Cadastrar", style: TextStyle(
                                        fontWeight: FontWeight.w600),
                                  ),
                        ),

                        const SizedBox(height: 10),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TextButton(
                            onPressed: _loading
                                  ? null
                                  : () => Navigator.pushNamed(context, '/login'),
                              child: const Text(
                                "Já possui conta? Faça login.",
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.black,               
                                  decoration: TextDecoration.underline, 
                                  
                                ),
                              ),
                            ),
                          ],
                        ),

                      ],
                    ),
                  ),
                ),
              ),
              ],
          ),
        ),
      ),
    )
    );
  }
}
