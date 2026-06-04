import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:alarme_feriados/core/relogio.dart';
import 'package:alarme_feriados/domain/models/alarme.dart';
import 'package:alarme_feriados/features/alarme_criar_editar/alarme_criar_editar_page.dart';
import 'package:alarme_feriados/features/configuracoes/configuracoes_page.dart';
import 'package:alarme_feriados/features/configuracoes/configuracoes_providers.dart';
import 'package:alarme_feriados/features/escala/escala_page.dart';
import 'package:alarme_feriados/features/feriados/feriados_page.dart';
import 'package:alarme_feriados/features/home/home_providers.dart';
import 'package:alarme_feriados/features/localizacao/localizacao_page.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(alarmesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alarmes'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) {
              final route = switch (v) {
                'feriados' => MaterialPageRoute<void>(
                    builder: (_) => const FeriadosPage(),
                  ),
                'escala' => MaterialPageRoute<void>(
                    builder: (_) => const EscalaPage(),
                  ),
                'localizacao' => MaterialPageRoute<void>(
                    builder: (_) => const LocalizacaoPage(),
                  ),
                'configuracoes' => MaterialPageRoute<void>(
                    builder: (_) => const ConfiguracoesPage(),
                  ),
                _ => null,
              };
              if (route != null) Navigator.push(context, route);
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'feriados', child: Text('Feriados')),
              PopupMenuItem(value: 'escala', child: Text('Minha escala')),
              PopupMenuItem(
                value: 'localizacao',
                child: Text('Localização'),
              ),
              PopupMenuItem(
                value: 'configuracoes',
                child: Text('Configurações'),
              ),
            ],
          ),
        ],
      ),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (alarmes) => alarmes.isEmpty
            ? const Center(child: Text('Nenhum alarme cadastrado.'))
            : ListView.builder(
                itemCount: alarmes.length,
                itemBuilder: (_, i) => _AlarmeTile(alarme: alarmes[i]),
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => const AlarmeCriarEditarPage(),
          ),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _AlarmeTile extends ConsumerWidget {
  const _AlarmeTile({required this.alarme});
  final Alarme alarme;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(alarmesProvider.notifier);
    final use24h = ref.watch(clockFormatProvider);

    return Dismissible(
      key: ValueKey(alarme.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => notifier.deletar(alarme.id!),
      child: ListTile(
        leading: Switch(
          value: alarme.ativo,
          onChanged: (_) => notifier.toggleAtivo(alarme),
        ),
        title: Text(
          formatarHora(alarme.hora, use24h: use24h),
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        subtitle: Text(
          alarme.titulo.isEmpty
              ? _descDias(alarme.diasDaSemana)
              : '${alarme.titulo} · ${_descDias(alarme.diasDaSemana)}',
        ),
        trailing: IconButton(
          icon: const Icon(Icons.edit),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (_) => AlarmeCriarEditarPage(alarme: alarme),
            ),
          ),
        ),
      ),
    );
  }

  String _descDias(int mask) {
    if (mask == 0x7F) return 'Todos os dias';
    if (mask == 0x1F) return 'Dias úteis';
    if (mask == 0x60) return 'Fim de semana';
    const nomes = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
    return [
      for (var i = 0; i < 7; i++)
        if (mask & (1 << i) != 0) nomes[i],
    ].join(', ');
  }
}
