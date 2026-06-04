import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:alarme_feriados/core/datas.dart';
import 'package:alarme_feriados/domain/models/feriado_cache.dart';
import 'package:alarme_feriados/features/feriados/feriados_providers.dart';
import 'package:alarme_feriados/features/localizacao/localizacao_providers.dart';

class FeriadosPage extends ConsumerWidget {
  const FeriadosPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ano = DateTime.now().year;
    final state = ref.watch(feriadosProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Feriados $ano'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: 'Atualizar da API',
            onPressed: () => ref.read(feriadosProvider.notifier).sincronizar(),
          ),
        ],
      ),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (feriados) {
          if (feriados.isEmpty) {
            return const Center(
              child: Text('Nenhum feriado. Toque em ↻ para buscar.'),
            );
          }
          final nacionais = feriados
              .where((f) => f.tipo != 'municipal')
              .toList()
            ..sort((a, b) => a.data.compareTo(b.data));
          final municipais = feriados
              .where((f) => f.tipo == 'municipal')
              .toList()
            ..sort((a, b) => a.data.compareTo(b.data));

          return ListView(
            children: [
              if (nacionais.isNotEmpty) ...[
                _Cabecalho(label: 'Nacional / Estadual'),
                ...nacionais.map((f) => _FeriadoTile(feriado: f)),
              ],
              if (municipais.isNotEmpty) ...[
                _Cabecalho(label: 'Municipal (manual)'),
                ...municipais.map(
                  (f) => _FeriadoTile(feriado: f, deletavel: true),
                ),
              ],
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Adicionar feriado municipal',
        onPressed: () => _mostrarFormulario(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _mostrarFormulario(BuildContext context, WidgetRef ref) async {
    final hoje = DateTime.now();
    var dataSelecionada = hoje;
    final nomeCtrl = TextEditingController();

    // Pre-fill IBGE code from saved location
    final locState = ref.read(localizacaoProvider);
    final ibgeAutoFill = locState.valueOrNull?.codigoIBGE ?? '0';
    final ibgeCtrl = TextEditingController(
      text: ibgeAutoFill == '0' ? '' : ibgeAutoFill,
    );

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          title: const Text('Feriado municipal'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(dataSelecionada.toString().substring(0, 10)),
                trailing: const Icon(Icons.calendar_today_outlined),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: dataSelecionada,
                    firstDate: DateTime(hoje.year),
                    lastDate: DateTime(hoje.year + 1),
                  );
                  if (picked != null) {
                    setModalState(() => dataSelecionada = picked);
                  }
                },
              ),
              TextField(
                controller: nomeCtrl,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Nome do feriado'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: ibgeCtrl,
                decoration: const InputDecoration(
                  labelText: 'Código IBGE',
                  helperText: 'Da sua cidade (7 dígitos)',
                ),
                keyboardType: TextInputType.number,
                maxLength: 7,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );

    if (ok != true) {
      nomeCtrl.dispose();
      ibgeCtrl.dispose();
      return;
    }

    final nome = nomeCtrl.text.trim();
    final ibge = ibgeCtrl.text.trim();
    nomeCtrl.dispose();
    ibgeCtrl.dispose();

    if (nome.isEmpty) return;

    await ref.read(feriadosProvider.notifier).inserirManual(
          FeriadoCache(
            data: isoDate(dataSelecionada),
            nome: nome,
            tipo: 'municipal',
            codigoIBGE: ibge.isEmpty ? '0' : ibge,
            ano: dataSelecionada.year,
          ),
        );
  }
}

class _Cabecalho extends StatelessWidget {
  const _Cabecalho({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              letterSpacing: 1.2,
            ),
      ),
    );
  }
}

class _FeriadoTile extends ConsumerWidget {
  const _FeriadoTile({required this.feriado, this.deletavel = false});
  final FeriadoCache feriado;
  final bool deletavel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hoje = isoDate(DateTime.now());
    final isHoje = feriado.data == hoje;

    Widget tile = ListTile(
      leading: isHoje
          ? CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Text(
                _dia(feriado.data),
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            )
          : CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Text(_dia(feriado.data), style: const TextStyle(fontSize: 12)),
            ),
      title: Text(feriado.nome),
      subtitle: Text(_mesAbrev(feriado.data)),
      trailing: isHoje
          ? Chip(
              label: const Text('Hoje'),
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              labelStyle: TextStyle(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
            )
          : null,
    );

    if (!deletavel) return tile;

    return Dismissible(
      key: ValueKey(feriado.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) =>
          ref.read(feriadosProvider.notifier).deletar(feriado.id!),
      child: tile,
    );
  }

  String _dia(String iso) => iso.substring(8, 10);

  String _mesAbrev(String iso) {
    const meses = [
      'jan', 'fev', 'mar', 'abr', 'mai', 'jun',
      'jul', 'ago', 'set', 'out', 'nov', 'dez',
    ];
    final mes = int.parse(iso.substring(5, 7)) - 1;
    return '${iso.substring(0, 4)} · ${meses[mes]}';
  }
}
