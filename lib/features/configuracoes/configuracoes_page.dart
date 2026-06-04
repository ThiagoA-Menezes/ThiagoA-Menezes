import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:alarme_feriados/features/configuracoes/configuracoes_providers.dart';
import 'package:alarme_feriados/features/permissoes/permissoes_page.dart';

class ConfiguracoesPage extends ConsumerWidget {
  const ConfiguracoesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final use24h = ref.watch(clockFormatProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: ListView(
        children: [
          const _Secao(label: 'Exibição'),
          SwitchListTile(
            title: const Text('Formato 24 horas'),
            subtitle:
                Text(use24h ? 'Ex: 07:00 · 13:30' : 'Ex: 7:00 AM · 1:30 PM'),
            value: use24h,
            onChanged: (_) =>
                ref.read(clockFormatProvider.notifier).toggle(),
          ),
          const Divider(),
          const _Secao(label: 'Sistema'),
          ListTile(
            leading: const Icon(Icons.security_outlined),
            title: const Text('Permissões e bateria'),
            subtitle: const Text(
              'Verifique alarme exato, notificações e otimização de bateria',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => const PermissoesPage(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Secao extends StatelessWidget {
  const _Secao({required this.label});
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
