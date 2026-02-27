// ignore_for_file: deprecated_member_use, use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/materia_prima_provider.dart';
import '../providers/fornecedor_provider.dart';
import '../models/materia_prima_model.dart';
import '../widgets/app_side_menu.dart';

class CadastroMPScreen extends StatefulWidget {
  const CadastroMPScreen({super.key});

  @override
  State<CadastroMPScreen> createState() => _CadastroMPScreenState();
}

enum _MpSort { nomeAsc, nomeDesc, custoAsc, custoDesc }

class _CadastroMPScreenState extends State<CadastroMPScreen> {

  bool _drawerExpanded = true;

  String _unidadeSel = 'kg';
  String? _fornecedorSel;

  final _formKey = GlobalKey<FormState>();
  final _nomeCtrl = TextEditingController();
  final _custoCtrl = TextEditingController();

  String? _editingId;
  bool _saving = false;

  final _searchCtrl = TextEditingController();
  String _q = '';
  _MpSort _sort = _MpSort.nomeAsc;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() => setState(() => _q = _searchCtrl.text.trim()));
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _custoCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }


  double _parseBRL(String text) {
  
    var t = text.trim();
    t = t.replaceAll('R\$', '').trim();
    if (t.isEmpty) return 0.0;
    t = t.replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(t) ?? 0.0;
  }

  String _formatBRL(double value) {
    final cents = (value * 100).round();
    final absCents = cents.abs();
    final reais = absCents ~/ 100;
    final cent = absCents % 100;

    final reaisStr = reais.toString();
    final sb = StringBuffer();
    for (int i = 0; i < reaisStr.length; i++) {
      final idxFromEnd = reaisStr.length - i;
      sb.write(reaisStr[i]);
      if (idxFromEnd > 1 && idxFromEnd % 3 == 1) sb.write('.');
    }

    final sign = cents < 0 ? '-' : '';
    return '${sign}R\$ ${sb.toString()},${cent.toString().padLeft(2, '0')}';
  }


  void _startEdit(MateriaPrimaModel mp) {
    setState(() {
      _editingId = mp.id;
      _nomeCtrl.text = mp.nome;
      _unidadeSel = mp.unidade;
      _fornecedorSel = mp.fornecedor;
      _custoCtrl.text = _formatBRL(mp.custo);
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
    _custoCtrl.clear();
  }

  Future<void> _save(String uid) async {
    if (!_formKey.currentState!.validate()) return;

    if (_fornecedorSel == null || _fornecedorSel!.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione um fornecedor')),
      );
      return;
    }

    setState(() => _saving = true);

    final provider = context.read<MateriaPrimaProvider>();
    final nome = _nomeCtrl.text.trim();
    final custo = _parseBRL(_custoCtrl.text);
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
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Matéria-prima adicionada')),
        );
      } else {
        final mp = MateriaPrimaModel(
          id: _editingId!,
          nome: nome,
          fornecedor: fornecedor,
          custo: custo,
          unidade: unidade,
        );
        await provider.update(uid, mp);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Matéria-prima atualizada')),
        );
      }

      _clearForm();
    } finally {
      if (mounted) setState(() => _saving = false);
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
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Excluído')));
        if (_editingId == id) _clearForm();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao excluir: $e')));
      }
    }
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
    if (!mounted) return;

    setState(() => _fornecedorSel = clean);
  }

  Future<void> _openManageFornecedores(String uid) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFFDF7ED),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 12),
                const Row(
                  children: [
                    Icon(Icons.store, color: Color(0xFF428E2E)),
                    SizedBox(width: 8),
                    Text('Fornecedores', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: StreamBuilder<List<String>>(
                    stream: context.read<FornecedorProvider>().streamNomes(uid),
                    builder: (context, snap) {
                      final list = snap.data ?? [];
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (list.isEmpty) {
                        return const Center(child: Text('Nenhum fornecedor cadastrado'));
                      }

                      return ListView.separated(
                        itemCount: list.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, i) {
                          final nome = list[i];
                          return ListTile(
                            title: Text(nome),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: 'Editar',
                                  icon: const Icon(Icons.edit, color: Colors.orange),
                                  onPressed: () async => _editFornecedorDialog(uid, nome),
                                ),
                                IconButton(
                                  tooltip: 'Excluir',
                                  icon: const Icon(Icons.delete_forever, color: Colors.red),
                                  onPressed: () async => _confirmDeleteFornecedor(uid, nome),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF428E2E)),
                    onPressed: () async => _addFornecedorDialog(uid),
                    icon: const Icon(Icons.add),
                    label: const Text('Adicionar fornecedor'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _editFornecedorDialog(String uid, String oldName) async {
    final ctrl = TextEditingController(text: oldName);
    bool updateMPs = true;

    final result = await showDialog<_EditFornecedorResult>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Editar fornecedor'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: ctrl,
                decoration: const InputDecoration(labelText: 'Nome'),
                autofocus: true,
              ),
              const SizedBox(height: 8),
              CheckboxListTile(
                value: updateMPs,
                onChanged: (v) => setLocal(() => updateMPs = v ?? true),
                title: const Text('Atualizar matérias-primas com o novo nome'),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () => Navigator.pop(
                ctx,
                _EditFornecedorResult(newName: ctrl.text, updateMPs: updateMPs),
              ),
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );

    if (result == null) return;

    final newName = result.newName.trim();
    if (newName.isEmpty || newName == oldName.trim()) return;

    try {
      await context.read<FornecedorProvider>().renameFornecedor(
            uid,
            oldName: oldName,
            newName: newName,
            updateMateriasPrimas: result.updateMPs,
          );

      if (_fornecedorSel == oldName) setState(() => _fornecedorSel = newName);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fornecedor atualizado')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
    }
  }

  Future<void> _confirmDeleteFornecedor(String uid, String name) async {
    bool removeFromMPs = true;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Excluir fornecedor'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Deseja excluir "$name"?'),
              const SizedBox(height: 10),
              CheckboxListTile(
                value: removeFromMPs,
                onChanged: (v) => setLocal(() => removeFromMPs = v ?? true),
                title: const Text('Remover este fornecedor das matérias-primas'),
                subtitle: const Text('As MPs ficarão com fornecedor vazio.'),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Excluir')),
          ],
        ),
      ),
    );

    if (ok != true) return;

    try {
      await context.read<FornecedorProvider>().deleteFornecedor(
            uid,
            name: name,
            removeFromMateriasPrimas: removeFromMPs,
          );

      if (_fornecedorSel == name) setState(() => _fornecedorSel = null);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fornecedor excluído')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
    }
  }


  Widget _pill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.black.withOpacity(0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF428E2E)),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildFormCard(String uid) {
    const green = Color(0xFF428E2E);

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
          borderSide: const BorderSide(color: green, width: 1.6),
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
                      color: green.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.inventory_2, color: green),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Cadastro de Matéria-Prima',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                  ),
                  if (_editingId != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: Colors.orange.withOpacity(0.25)),
                      ),
                      child: const Text(
                        'Editando',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.orange),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _nomeCtrl,
                decoration: deco('Nome da matéria-prima', icon: Icons.badge_outlined, hint: 'Ex.: Farinha de trigo'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe o nome' : null,
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _custoCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: const [_BrMoneyInputFormatter()],
                      decoration: deco('Custo', icon: Icons.paid, hint: 'R\$ 0,00'),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Informe o custo';
                        final parsed = _parseBRL(v);
                        if (parsed < 0) return 'Custo não pode ser negativo';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 160,
                    child: DropdownButtonFormField<String>(
                      value: _unidadeSel,
                      decoration: deco('Unidade', icon: Icons.straighten),
                      items: const [
                        DropdownMenuItem(value: 'unidade', child: Text('unidade')),
                        DropdownMenuItem(value: 'kg', child: Text('kg')),
                        DropdownMenuItem(value: 'litros', child: Text('litros')),
                        DropdownMenuItem(value: 'caixa', child: Text('caixa')),
                      ],
                      onChanged: (v) => setState(() => _unidadeSel = v ?? 'kg'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              StreamBuilder<List<String>>(
                stream: context.read<FornecedorProvider>().streamNomes(uid),
                builder: (context, snap) {
                  final fornecedores = snap.data ?? [];

                  if (_fornecedorSel != null && !fornecedores.contains(_fornecedorSel)) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) setState(() => _fornecedorSel = null);
                    });
                  }

                  final currentValue =
                      (_fornecedorSel != null && fornecedores.contains(_fornecedorSel))
                          ? _fornecedorSel
                          : null;

                  return DropdownButtonFormField<String>(
                    value: currentValue,
                    decoration: deco('Fornecedor', icon: Icons.store_outlined),
                    items: [
                      ...fornecedores.map((f) => DropdownMenuItem(value: f, child: Text(f))),
                      const DropdownMenuItem<String>(
                        value: '__add__',
                        child: Text('+ Adicionar fornecedor...'),
                      ),
                      const DropdownMenuItem<String>(
                        value: '__manage__',
                        child: Text('⚙ Gerenciar fornecedores...'),
                      ),
                    ],
                    onChanged: (v) async {
                      if (v == '__add__') {
                        await _addFornecedorDialog(uid);
                        return;
                      }
                      if (v == '__manage__') {
                        await _openManageFornecedores(uid);
                        return;
                      }
                      setState(() => _fornecedorSel = v);
                    },
                    validator: (_) {
                      if (_fornecedorSel == null || _fornecedorSel!.trim().isEmpty) {
                        return 'Selecione um fornecedor';
                      }
                      return null;
                    },
                  );
                },
              ),

              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _saving ? null : () => _save(uid),
                      icon: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save),
                      label: Text(_editingId == null ? 'Adicionar' : 'Salvar alterações'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: green,
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
  }

  Widget _buildListCard(String uid, MateriaPrimaProvider mpProvider) {
    const green = Color(0xFF428E2E);

    InputDecoration deco(String label, {IconData? icon}) {
      return InputDecoration(
        hintText: label,
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
          borderSide: const BorderSide(color: green, width: 1.6),
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
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
         
            Row(
              children: [
                const Icon(Icons.list, color: green),
                const SizedBox(width: 8),
                const Text('Matérias-primas', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                const Spacer(),
                DropdownButton<_MpSort>(
                  value: _sort,
                  underline: const SizedBox.shrink(),
                  onChanged: (v) => setState(() => _sort = v ?? _MpSort.nomeAsc),
                  items: const [
                    DropdownMenuItem(value: _MpSort.nomeAsc, child: Text('Nome A–Z')),
                    DropdownMenuItem(value: _MpSort.nomeDesc, child: Text('Nome Z–A')),
                    DropdownMenuItem(value: _MpSort.custoAsc, child: Text('Custo ↑')),
                    DropdownMenuItem(value: _MpSort.custoDesc, child: Text('Custo ↓')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),

           
            TextField(
              controller: _searchCtrl,
              decoration: deco('Pesquisar por nome ou fornecedor', icon: Icons.search),
            ),
            const SizedBox(height: 10),

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

                  final all = snap.data ?? [];
                  final total = all.length;

                 
                  final q = _q.toLowerCase();
                  var list = all.where((mp) {
                    if (q.isEmpty) return true;
                    final a = mp.nome.toLowerCase();
                    final b = mp.fornecedor.toLowerCase();
                    return a.contains(q) || b.contains(q);
                  }).toList();

                 
                  int cmpNome(MateriaPrimaModel a, MateriaPrimaModel b) =>
                      a.nome.toLowerCase().compareTo(b.nome.toLowerCase());
                  int cmpCusto(MateriaPrimaModel a, MateriaPrimaModel b) => a.custo.compareTo(b.custo);

                  switch (_sort) {
                    case _MpSort.nomeAsc:
                      list.sort(cmpNome);
                      break;
                    case _MpSort.nomeDesc:
                      list.sort((a, b) => cmpNome(b, a));
                      break;
                    case _MpSort.custoAsc:
                      list.sort(cmpCusto);
                      break;
                    case _MpSort.custoDesc:
                      list.sort((a, b) => cmpCusto(b, a));
                      break;
                  }

                  final shown = list.length;

                  if (total == 0) {
                    return const Center(child: Text('Nenhuma matéria-prima cadastrada'));
                  }
                  if (shown == 0) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.search_off, size: 40, color: Colors.black38),
                        SizedBox(height: 10),
                        Text('Nenhum resultado para sua pesquisa'),
                      ],
                    );
                  }

                  return Column(
                    children: [
                      Row(
                        children: [
                          _pill(Icons.numbers, 'Total: $total'),
                          const SizedBox(width: 8),
                          if (_q.isNotEmpty) _pill(Icons.filter_alt, 'Filtrados: $shown'),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: ListView.separated(
                          itemCount: list.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, i) {
                            final mp = list[i];

                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFAF7F1),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Colors.black.withOpacity(0.06)),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: green,
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Center(
                                      child: Text(
                                        mp.nome.isNotEmpty ? mp.nome[0].toUpperCase() : '?',
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          mp.nome,
                                          style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800),
                                        ),
                                        const SizedBox(height: 6),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 6,
                                          children: [
                                            _pill(Icons.store, mp.fornecedor.isEmpty ? 'Sem fornecedor' : mp.fornecedor),
                                            _pill(Icons.straighten, mp.unidade),
                                            _pill(Icons.paid, _formatBRL(mp.custo)),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Column(
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
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
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
      body: LayoutBuilder(
        builder: (context, c) {
          final isWide = c.maxWidth >= 950;

          final content = isWide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: 420, child: _buildFormCard(uid)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildListCard(uid, mpProvider)),
                  ],
                )
              : Column(
                  children: [
                    _buildFormCard(uid),
                    const SizedBox(height: 16),
                    Expanded(child: _buildListCard(uid, mpProvider)),
                  ],
                );

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: content,
          );
        },
      ),
    );
  }
}


class _EditFornecedorResult {
  final String newName;
  final bool updateMPs;
  _EditFornecedorResult({required this.newName, required this.updateMPs});
}


class _BrMoneyInputFormatter extends TextInputFormatter {
  const _BrMoneyInputFormatter();

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digitsOnly = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.isEmpty) {
      return const TextEditingValue(
        text: 'R\$ 0,00',
        selection: TextSelection.collapsed(offset: 7),
      );
    }

   
    final cents = int.tryParse(digitsOnly) ?? 0;
    final reais = cents ~/ 100;
    final cent = cents % 100;

    final reaisStr = reais.toString();
    final sb = StringBuffer();

    for (int i = 0; i < reaisStr.length; i++) {
      final idxFromEnd = reaisStr.length - i;
      sb.write(reaisStr[i]);
      if (idxFromEnd > 1 && idxFromEnd % 3 == 1) sb.write('.');
    }

    final formatted = 'R\$ ${sb.toString()},${cent.toString().padLeft(2, '0')}';

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}