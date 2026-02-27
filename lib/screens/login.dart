// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _senha = TextEditingController();

  bool _lembrar = true;
  bool _loading = false;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _loadRememberedEmail();
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _loadRememberedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString("remember_email");
    final remember = prefs.getBool("remember_enabled") ?? true;

    if (!mounted) return;

    setState(() {
      _lembrar = remember;
      if (remember && savedEmail != null && savedEmail.isNotEmpty) {
        _email.text = savedEmail;
      }
    });
  }

  Future<void> _saveRememberedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("remember_enabled", _lembrar);

    if (_lembrar) {
      await prefs.setString("remember_email", _email.text.trim());
    } else {
      await prefs.remove("remember_email");
    }
  }

  Future<void> _toggleRemember(bool? v) async {
    final next = v ?? true;

    setState(() => _lembrar = next);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("remember_enabled", next);

    if (!next) {
      _email.clear();
      await prefs.remove("remember_email");
    } else {
     
      await prefs.setString("remember_email", _email.text.trim());
    }
  }

  Future<void> _entrar() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      await context.read<AuthProvider>().signIn(
            _email.text.trim(),
            _senha.text,
          );

      await _saveRememberedEmail();

      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
    } catch (e) {
      _snack(e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resetSenha() async {
    final controller = TextEditingController(text: _email.text.trim());

    final email = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFFFDF7ED),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(
            color: Color(0xFFC29500),
            width: 1.2,
          ),
        ),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
        contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),

        title: Row(
          children: const [
            Icon(
              Icons.lock_reset,
              color: Color(0xFFC29500),
            ),
            SizedBox(width: 10),
            Text(
              "Recuperar senha",
              style: TextStyle(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),

        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Informe o e-mail cadastrado para receber o link de recuperação.",
              style: TextStyle(
                fontSize: 13,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: controller,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: "E-mail",
                prefixIcon: const Icon(Icons.email_outlined),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Colors.black.withOpacity(0.15),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF54A73B),
                    width: 1.6,
                  ),
                ),
              ),
            ),
          ],
        ),

        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: Colors.black87,
            ),
            child: const Text(
              "Cancelar",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC29500),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              side: const BorderSide(color: Colors.black, width: 1.2),
              elevation: 2,
            ),
            child: const Text(
              "Enviar link",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );


    if (email == null || email.isEmpty) return;

    try {
      await context.read<AuthProvider>().sendPasswordResetEmail(email);
      _snack("Enviamos um link de recuperação para seu e-mail.");
    } catch (e) {
      _snack(e.toString());
    }
  }

  InputDecoration _decoration({
    required String label,
    required Widget prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.black54),
      floatingLabelStyle: const TextStyle(
        color: Color(0xFF54A73B),
        fontWeight: FontWeight.w600,
      ),
      filled: true,
      fillColor: Colors.white, 
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
    );
  }

  @override
  void dispose() {
    _email.dispose();
    _senha.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF7ED),
      appBar: AppBar(
        title: const Text("Login", style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFFFDF7ED),
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.asset('assets/Logo2.png', height: 110),
                const SizedBox(height: 16),
                Card(
                  color: Colors.white,
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 6),
                          Text(
                            "Login",
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 18),

                          TextFormField(
                            controller: _email,
                            keyboardType: TextInputType.emailAddress,
                            decoration: _decoration(
                              label: "E-mail",
                              prefixIcon: const Icon(Icons.email_outlined),
                            ),
                            validator: (v) {
                              final s = (v ?? "").trim();
                              if (s.isEmpty) return "Informe o e-mail";
                              if (!s.contains("@")) return "E-mail inválido";
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),

                          TextFormField(
                            controller: _senha,
                            obscureText: _obscure,
                            decoration: _decoration(
                              label: "Senha",
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                onPressed: () => setState(() => _obscure = !_obscure),
                                icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                              ),
                            ),
                            validator: (v) {
                              if ((v ?? "").isEmpty) return "Informe a senha";
                              if ((v ?? "").length < 6) return "Senha deve ter no mínimo 6 caracteres";
                              return null;
                            },
                          ),

                          const SizedBox(height: 10),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Checkbox(
                                    value: _lembrar,
                                    activeColor: const Color(0xFF54A73B),
                                    checkColor: Colors.black,
                                    onChanged: _loading ? null : _toggleRemember,
                                  ),
                                  const Text(
                                    "Lembrar de mim",
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.black87,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              TextButton(
                                onPressed: _loading ? null : _resetSenha,
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: const Text(
                                  "Esqueci minha senha",
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black,
                                    fontStyle: FontStyle.italic,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 8),

                          ElevatedButton(
                            onPressed: _loading ? null : _entrar,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF54A73B),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            
                            ),
                            child: _loading
                                ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Text(
                                    "Entrar",
                                    style: TextStyle(fontWeight: FontWeight.w600),
                                  ),
                          ),

                          const SizedBox(height: 12),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              TextButton(
                                onPressed: _loading
                                    ? null
                                    : () => Navigator.pushNamed(context, '/cadastro'),
                                child: const Text(
                                  "Ainda não possui cadastro? Cadastre-se.",
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
      ),
    );
  }
}
