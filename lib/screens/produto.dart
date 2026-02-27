// ignore_for_file: deprecated_member_use, use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/materia_prima_provider.dart';
import '../providers/produto_provider.dart';
import '../models/materia_prima_model.dart';
import '../models/produto_model.dart';
import '../widgets/app_side_menu.dart';

class ProdutosScreen extends StatefulWidget {
  const ProdutosScreen({super.key});

  @override
  State<ProdutosScreen> createState() => _ProdutosScreenState();
}

class _ProdutosScreenState extends State<ProdutosScreen> {
  static const _bg = Color(0xFFFDF7ED);
  static const _green = Color(0xFF428E2E);
  static const _text = Color(0xFF2B2B2B);

  bool _drawerExpanded = true;

  final _formKey = GlobalKey<FormState>();
  final _nomeCtrl = TextEditingController();

  String? _editingId;
  bool _saving = false;

 
  final List<_ItemDraft> _draftItems = [];

 
  final _searchCtrl = TextEditingController();
  String _q = '';

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() => setState(() => _q = _searchCtrl.text.trim()));
    _draftItems.add(_ItemDraft()); 
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _clearForm() {
    setState(() {
      _editingId = null;
      _saving = false;
      _draftItems
        ..clear()
        ..add(_ItemDraft());
    });
    _formKey.currentState?.reset();
    _nomeCtrl.clear();
  }

  void _startEdit(ProdutoModel p) {
    setState(() {
      _editingId = p.id;
      _nomeCtrl.text = p.nome;

      _draftItems.clear();
      for (final it in p.items) {
        _draftItems.add(_ItemDraft(
          mpId: it.mpId,
          quantidade: it.quantidade.toString(),
        ));
      }
      if (_draftItems.isEmpty) _draftItems.add(_ItemDraft());
    });
  }

  Future<void> _confirmDelete(String uid, ProdutoModel p) async {
    const danger = Color(0xFFE53935);

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: danger.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.delete_forever, color: danger),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Excluir “${p.nome}”?',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
        content: const Text('Essa ação não pode ser desfeita.'),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              side: BorderSide(color: Colors.black.withOpacity(0.16)),
            ),
            child: const Text('Cancelar', style: TextStyle(color: _text)),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.delete_outline, color: Colors.white),
            label: const Text('Excluir'),
            style: ElevatedButton.styleFrom(
              backgroundColor: danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ],
      ),
    );

    if (ok != true) return;

    await context.read<ProdutoProvider>().delete(uid, p.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Produto excluído'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: _green,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );

    if (_editingId == p.id) _clearForm();
  }

  double _parseDouble(String s) {
    final t = s.trim().replaceAll(',', '.');
    return double.tryParse(t) ?? 0.0;
  }

  Future<void> _save(String uid, List<MateriaPrimaModel> mps) async {
    if (!_formKey.currentState!.validate()) return;

  
    final items = <ProdutoItemModel>[];
    for (final d in _draftItems) {
      final mpId = (d.mpId ?? '').trim();
      final qtd = _parseDouble(d.quantidade ?? '');
      if (mpId.isEmpty) continue; 
      if (qtd <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Quantidade deve ser maior que zero'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFFE53935),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        );
        return;
      }

      final mp = mps.firstWhere((x) => x.id == mpId, orElse: () => MateriaPrimaModel(
        id: mpId, nome: 'Matéria-prima', fornecedor: '', custo: 0, unidade: '',
      ));

      items.add(
        ProdutoItemModel(
          mpId: mp.id,
          mpNome: mp.nome,
          unidade: mp.unidade,
          quantidade: qtd,
        ),
      );
    }

    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Adicione pelo menos 1 matéria-prima ao produto'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFFE53935),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
      return;
    }

    setState(() => _saving = true);

    final nome = _nomeCtrl.text.trim();

    try {
      if (_editingId == null) {
        await context.read<ProdutoProvider>().create(uid, nome: nome, items: items);
      } else {
        final p = ProdutoModel(
          id: _editingId!,
          nome: nome,
          items: items,
          createdAt: 0,
          updatedAt: 0,
        );
        await context.read<ProdutoProvider>().update(uid, p);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_editingId == null ? 'Produto adicionado' : 'Produto atualizado'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: _green,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
      _clearForm();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _form(String uid) {
    return StreamBuilder<List<MateriaPrimaModel>>(
      stream: context.read<MateriaPrimaProvider>().streamAll(uid),
      builder: (context, snap) {
        final mps = snap.data ?? [];

        InputDecoration deco(String label, {IconData? icon, String? hint}) {
          return InputDecoration(
            labelText: label,
            hintText: hint,
            prefixIcon: icon == null ? null : Icon(icon),
            filled: true,
            fillColor: const Color(0xFFFAF7F1),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.black.withOpacity(0.06)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _green, width: 1.6),
            ),
          );
        }

        return Card(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.black.withOpacity(0.06)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _green.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.shopping_bag_outlined, color: _green),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text('Cadastro de Produto', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                      ),
                      if (_editingId != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: Colors.orange.withOpacity(0.25)),
                          ),
                          child: const Text('Editando',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.orange)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  TextFormField(
                    controller: _nomeCtrl,
                    decoration: deco('Nome do produto', icon: Icons.label_outline, hint: 'Ex.: Pão francês'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe o nome do produto' : null,
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: const [
                      Icon(Icons.layers_outlined, color: _green),
                      SizedBox(width: 8),
                      Text('Matérias-primas do produto', style: TextStyle(fontWeight: FontWeight.w800)),
                    ],
                  ),
                  const SizedBox(height: 10),

                  if (snap.connectionState == ConnectionState.waiting)
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (mps.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAF7F1),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.black.withOpacity(0.06)),
                      ),
                      child: const Text('Cadastre matérias-primas primeiro (menu Matérias-primas).'),
                    )
                  else
                    Column(
                      children: [
                        ...List.generate(_draftItems.length, (i) {
                          final d = _draftItems[i];

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    value: (d.mpId != null && mps.any((x) => x.id == d.mpId)) ? d.mpId : null,
                                    decoration: deco('Matéria-prima', icon: Icons.inventory_2_outlined),
                                    items: mps
                                        .map((mp) => DropdownMenuItem(
                                              value: mp.id,
                                              child: Text(mp.nome, overflow: TextOverflow.ellipsis),
                                            ))
                                        .toList(),
                                    onChanged: (v) => setState(() => d.mpId = v),
                                    validator: (_) {
                                    
                                      final hasSomething = (d.mpId ?? '').trim().isNotEmpty || (d.quantidade ?? '').trim().isNotEmpty;
                                      if (!hasSomething) return null;
                                      if ((d.mpId ?? '').trim().isEmpty) return 'Selecione a MP';
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 10),
                                SizedBox(
                                  width: 140,
                                  child: TextFormField(
                                    initialValue: d.quantidade,
                                    onChanged: (v) => d.quantidade = v,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    decoration: deco('Qtd', icon: Icons.exposure_plus_1, hint: 'Ex.: 2,5'),
                                    validator: (v) {
                                      final hasSomething = (d.mpId ?? '').trim().isNotEmpty || (v ?? '').trim().isNotEmpty;
                                      if (!hasSomething) return null;
                                      final qtd = _parseDouble(v ?? '');
                                      if (qtd <= 0) return 'Qtd > 0';
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 6),
                                IconButton(
                                  tooltip: 'Remover linha',
                                  onPressed: () {
                                    setState(() {
                                      if (_draftItems.length > 1) _draftItems.removeAt(i);
                                    });
                                  },
                                  icon: const Icon(Icons.close_rounded, color: Color(0xFFE53935)),
                                ),
                              ],
                            ),
                          );
                        }),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: OutlinedButton.icon(
                            onPressed: () => setState(() => _draftItems.add(_ItemDraft())),
                            icon: const Icon(Icons.add),
                            label: const Text('Adicionar matéria-prima'),
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              side: BorderSide(color: Colors.black.withOpacity(0.12)),
                              foregroundColor: _text,
                            ),
                          ),
                        ),
                      ],
                    ),

                  const SizedBox(height: 14),

                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: (_saving || mps.isEmpty) ? null : () => _save(uid, mps),
                          icon: _saving
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.save, color: Colors.white),
                          label: Text(_editingId == null ? 'Adicionar produto' : 'Salvar alterações'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      if (_editingId != null)
                        OutlinedButton(
                          onPressed: _saving ? null : _clearForm,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            side: BorderSide(color: Colors.black.withOpacity(0.14)),
                            foregroundColor: _text,
                          ),
                          child: const Text('Cancelar'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _list(String uid) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.black.withOpacity(0.06)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.list, color: _green),
                SizedBox(width: 8),
                Text('Produtos', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Pesquisar por nome',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: const Color(0xFFFAF7F1),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.black.withOpacity(0.06)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: _green, width: 1.6),
                ),
              ),
            ),
            const SizedBox(height: 10),

            Expanded(
              child: StreamBuilder<List<ProdutoModel>>(
                stream: context.read<ProdutoProvider>().streamAll(uid),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snap.hasError) return Center(child: Text('Erro: ${snap.error}'));

                  final all = snap.data ?? [];
                  final q = _q.toLowerCase();
                  final list = all.where((p) => q.isEmpty || p.nome.toLowerCase().contains(q)).toList();

                  if (all.isEmpty) {
                    return const Center(child: Text('Nenhum produto cadastrado'));
                  }
                  if (list.isEmpty) {
                    return const Center(child: Text('Nenhum resultado'));
                  }

                  return ListView.separated(
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final p = list[i];

                      return InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => Navigator.pushNamed(context, '/produto-detalhe', arguments: p),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFAF7F1),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.black.withOpacity(0.06)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: _green,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Center(
                                  child: Text(
                                    p.nome.isNotEmpty ? p.nome[0].toUpperCase() : '?',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(p.nome, style: const TextStyle(fontWeight: FontWeight.w900)),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${p.items.length} matéria(s)-prima(s)',
                                      style: TextStyle(color: Colors.black.withOpacity(0.55), fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                tooltip: 'Editar',
                                icon: const Icon(Icons.edit, color: Colors.orange),
                                onPressed: () => _startEdit(p),
                              ),
                              IconButton(
                                tooltip: 'Excluir',
                                icon: const Icon(Icons.delete_forever, color: Colors.red),
                                onPressed: () => _confirmDelete(uid, p),
                              ),
                              const Icon(Icons.chevron_right, color: Colors.black38),
                            ],
                          ),
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

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    if (user == null) {
      Future.microtask(() {
        if (!context.mounted) return;
        Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
      });
      return const SizedBox();
    }

    final uid = user.uid;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: _text),
        title: Image.asset('assets/Logo2.png', height: 40, fit: BoxFit.contain),
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
      body: LayoutBuilder(
        builder: (context, c) {
          final isWide = c.maxWidth >= 980;
          final content = isWide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: 460, child: _form(uid)),
                    const SizedBox(width: 16),
                    Expanded(child: _list(uid)),
                  ],
                )
              : Column(
                  children: [
                    _form(uid),
                    const SizedBox(height: 16),
                    Expanded(child: _list(uid)),
                  ],
                );

          return Padding(padding: const EdgeInsets.all(16), child: content);
        },
      ),
    );
  }
}

class _ItemDraft {
  String? mpId;
  String? quantidade; 
  _ItemDraft({this.mpId, this.quantidade});
}