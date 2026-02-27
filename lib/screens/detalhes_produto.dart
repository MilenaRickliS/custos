// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/materia_prima_provider.dart';
import '../models/materia_prima_model.dart';
import '../models/produto_model.dart';

class ProdutoDetalheScreen extends StatelessWidget {
  const ProdutoDetalheScreen({super.key});

  static const _bg = Color(0xFFFDF7ED);
  static const _green = Color(0xFF428E2E);
  static const _text = Color(0xFF2B2B2B);

  String _brl(double v) {
    final cents = (v * 100).round();
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

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final produto = ModalRoute.of(context)!.settings.arguments as ProdutoModel;

    if (user == null) return const SizedBox();

    final uid = user.uid;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        iconTheme: const IconThemeData(color: _text),
        title: Text(produto.nome, style: const TextStyle(color: _text, fontWeight: FontWeight.w900)),
      ),
      body: StreamBuilder<List<MateriaPrimaModel>>(
        stream: context.read<MateriaPrimaProvider>().streamAll(uid),
        builder: (context, snap) {
          final mps = snap.data ?? [];

          double total = 0;
          final rows = produto.items.map((it) {
            final mp = mps.where((x) => x.id == it.mpId).cast<MateriaPrimaModel?>().firstWhere(
                  (x) => x != null,
                  orElse: () => null,
                );

            final custoUnit = mp?.custo ?? 0.0;
            final sub = custoUnit * it.quantidade;
            total += sub;

            return _RowDetail(
              nome: it.mpNome,
              unidade: it.unidade,
              qtd: it.quantidade,
              custoUnit: custoUnit,
              subtotal: sub,
            );
          }).toList();

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Card(
                  elevation: 0,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.black.withOpacity(0.06)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: _green.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.paid, color: _green),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text('Custo total do produto', style: TextStyle(fontWeight: FontWeight.w900)),
                        ),
                        Text(_brl(total), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Card(
                    elevation: 0,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: Colors.black.withOpacity(0.06)),
                    ),
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: rows.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        final r = rows[i];
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFAF7F1),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.black.withOpacity(0.06)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(r.nome, style: const TextStyle(fontWeight: FontWeight.w900)),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 10,
                                runSpacing: 8,
                                children: [
                                  _pill(Icons.exposure_plus_1, 'Qtd: ${r.qtd} ${r.unidade}'),
                                  _pill(Icons.sell_outlined, 'Unit: ${_brl(r.custoUnit)}'),
                                  _pill(Icons.calculate_outlined, 'Sub: ${_brl(r.subtotal)}'),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
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
          Icon(icon, size: 14, color: _green),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _RowDetail {
  final String nome;
  final String unidade;
  final double qtd;
  final double custoUnit;
  final double subtotal;

  _RowDetail({
    required this.nome,
    required this.unidade,
    required this.qtd,
    required this.custoUnit,
    required this.subtotal,
  });
}