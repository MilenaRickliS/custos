// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/materia_prima_provider.dart';
import '../models/materia_prima_model.dart';
import '../widgets/app_side_menu.dart';
import '../providers/fornecedor_provider.dart';

class CadastroMPScreen extends StatefulWidget {
  const CadastroMPScreen({super.key});

  @override
  State<CadastroMPScreen> createState() => _CadastroMPScreenState();
}

class _CadastroMPScreenState extends State<CadastroMPScreen> {
  bool _drawerExpanded = true;
  String _unidadeSel = 'kg';
  String? _fornecedorSel;

  final _formKey = GlobalKey<FormState>();
  final _nomeCtrl = TextEditingController();
  final _fornecedorCtrl = TextEditingController();
  final _custoCtrl = TextEditingController();

  String? _editingId;
  bool _saving = false;

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _fornecedorCtrl.dispose();
    _custoCtrl.dispose();
    super.dispose();
  }

  void _startEdit(MateriaPrimaModel mp) {
    setState(() {
      _editingId = mp.id;
      _nomeCtrl.text = mp.nome;
      _unidadeSel = mp.unidade;
      _fornecedorSel = mp.fornecedor;
      _custoCtrl.text = mp.custo.toStringAsFixed(2);
    });
    
  }

  void _clearForm() {
    setState(() {
      _editingId = null;
      _unidadeSel = 'kg';
      _fornecedorSel = null;
    });
    _formKey.currentState?.reset();
    _nomeCtrl.clear();
    _fornecedorCtrl.clear();
    _custoCtrl.clear();
  }

  Future<void> _addFornecedorDialog(String uid) async {
    final ctrl = TextEditingController();
    final nome = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Novo fornecedor'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(labelText: 'Nome do fornecedor'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, ctrl.text), child: const Text('Salvar')),
        ],
      ),
    );

    final clean = (nome ?? '').trim();
    if (clean.isEmpty) return;

    await context.read<FornecedorProvider>().addFornecedor(uid, clean);

    setState(() => _fornecedorSel = clean);
  }

  Future<void> _save(String uid) async {
    if (!_formKey.currentState!.validate()) return;
    if (_fornecedorSel == null || _fornecedorSel!.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecione um fornecedor')));
      return;
    }

    setState(() => _saving = true);

    final provider = context.read<MateriaPrimaProvider>();
    final nome = _nomeCtrl.text.trim();
    final custo = double.tryParse(_custoCtrl.text.replaceAll(',', '.')) ?? 0.0;
    final fornecedor = _fornecedorSel!.trim();
    final unidade = _unidadeSel;

    try {
      if (_editingId == null) {
        final mp = MateriaPrimaModel(
          id: '',
          nome: nome,
          fornecedor: fornecedor,
          custo: custo,
          unidade: unidade,
        );
        await provider.create(uid, mp);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Matéria-prima adicionada')));
      } else {
        final mp = MateriaPrimaModel(
          id: _editingId!,
          nome: nome,
          fornecedor: fornecedor,
          custo: custo,
          unidade: unidade,
        );
        await provider.update(uid, mp);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Matéria-prima atualizada')));
      }
      _clearForm();
    } finally {
      setState(() => _saving = false);
    }
  }

  Future<void> _confirmDelete(String uid, String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar exclusão'),
        content: const Text('Deseja excluir esta matéria-prima? Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Excluir')),
        ],
      ),
    );

    if (ok == true) {
      try {
        await context.read<MateriaPrimaProvider>().delete(uid, id);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Excluído')));
        if (_editingId == id) _clearForm();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao excluir: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final mpProvider = context.read<MateriaPrimaProvider>();

    if (user == null) {
      Future.microtask(() {
        if (!context.mounted) return;
        Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
      });
      return const SizedBox();
    }

    final uid = user.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFFDF7ED),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFDF7ED),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF2B2B2B)),
        title: Image.asset(
          'assets/Logo2.png',
          height: 40,
          fit: BoxFit.contain,
        ),
      ),
      drawer: AppSideMenu(
        expanded: _drawerExpanded,
        onToggle: () => setState(() => _drawerExpanded = !_drawerExpanded),
        selectedRoute: ModalRoute.of(context)?.settings.name,
        onNavigate: (route) {
          Navigator.pop(context);
          if (route == (ModalRoute.of(context)?.settings.name)) return;
          Navigator.pushReplacementNamed(context, route);
        },
      ),

      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
           
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _nomeCtrl,
                              decoration: const InputDecoration(labelText: 'Nome da matéria-prima'),
                              validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe o nome' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 160,
                            child: TextFormField(
                              controller: _custoCtrl,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(labelText: 'Custo (R\$)'),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return 'Informe o custo';
                                final parsed = double.tryParse(v.replaceAll(',', '.'));
                                if (parsed == null) return 'Valor inválido';
                                if (parsed < 0) return 'Custo não pode ser negativo';
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                          width: 160,
                          child: DropdownButtonFormField<String>(
                            value: _unidadeSel,
                            decoration: const InputDecoration(labelText: 'Unidade'),
                            items: const [
                              DropdownMenuItem(value: 'unidade', child: Text('unidade')),
                              DropdownMenuItem(value: 'kg', child: Text('kg')),
                              DropdownMenuItem(value: 'litros', child: Text('litros')),
                              DropdownMenuItem(value: 'caixa', child: Text('caixa')),
                            ],
                            onChanged: (v) => setState(() => _unidadeSel = v ?? 'kg'),
                          ),
                        ),  
                      const SizedBox(height: 12),
                      StreamBuilder<List<String>>(
                        stream: context.read<FornecedorProvider>().streamNomes(uid),
                        builder: (context, snap) {
                          final fornecedores = snap.data ?? [];

                         
                          final currentValue = (_fornecedorSel != null && fornecedores.contains(_fornecedorSel))
                              ? _fornecedorSel
                              : null;

                          return DropdownButtonFormField<String>(
                            value: currentValue,
                            decoration: const InputDecoration(labelText: 'Fornecedor'),
                            items: [
                              ...fornecedores.map((f) => DropdownMenuItem(value: f, child: Text(f))),
                              const DropdownMenuItem<String>(
                                value: '__add__',
                                child: Text('+ Adicionar fornecedor...'),
                              ),
                            ],
                            onChanged: (v) async {
                              if (v == '__add__') {
                                await _addFornecedorDialog(uid);
                                return;
                              }
                              setState(() => _fornecedorSel = v);
                            },
                            validator: (v) {
                              
                              if (_fornecedorSel == null || _fornecedorSel!.trim().isEmpty) return 'Selecione um fornecedor';
                              return null;
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: _saving ? null : () => _save(uid),
                            icon: _saving ? const SizedBox.shrink() : const Icon(Icons.save),
                            label: Text(_editingId == null ? 'Adicionar' : 'Salvar alterações'),
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF428E2E)),
                          ),
                          const SizedBox(width: 8),
                          if (_editingId != null)
                            OutlinedButton(
                              onPressed: _saving ? null : _clearForm,
                              child: const Text('Cancelar'),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

           
            Row(
              children: const [
                Icon(Icons.list, color: Color(0xFF428E2E)),
                SizedBox(width: 8),
                Text('Matérias-primas', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ],
            ),

            const SizedBox(height: 8),

          
            Expanded(
              child: StreamBuilder<List<MateriaPrimaModel>>(
                stream: mpProvider.streamAll(uid),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snap.hasError) {
                    return Center(child: Text('Erro: ${snap.error}'));
                  }
                  final list = snap.data ?? [];
                  if (list.isEmpty) return const Center(child: Text('Nenhuma matéria-prima cadastrada'));

                  return ListView.separated(
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final mp = list[i];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF428E2E),
                          child: Text(mp.nome.isNotEmpty ? mp.nome[0].toUpperCase() : '?', style: const TextStyle(color: Colors.white)),
                        ),
                        title: Text(mp.nome),
                        subtitle: Text('${mp.fornecedor} • R\$ ${mp.custo.toStringAsFixed(2)} / ${mp.unidade}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'Editar',
                              icon: const Icon(Icons.edit, color: Colors.orange),
                              onPressed: () => _startEdit(mp),
                            ),
                            IconButton(
                              tooltip: 'Excluir',
                              icon: const Icon(Icons.delete_forever, color: Colors.red),
                              onPressed: () => _confirmDelete(uid, mp.id),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}