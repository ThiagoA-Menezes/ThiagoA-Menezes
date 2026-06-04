import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

/// Mapa de status das permissões relevantes para o app.
/// Vazio quando rodando em ambiente sem suporte a plugins (ex: testes host).
final permissoesStatusProvider = FutureProvider<Map<String, bool>>((ref) async {
  try {
    if (Platform.isAndroid) {
      return {
        'alarme': (await Permission.scheduleExactAlarm.status).isGranted,
        'notificacao': (await Permission.notification.status).isGranted,
        'localizacao': (await Permission.locationWhenInUse.status).isGranted,
        'bateria':
            (await Permission.ignoreBatteryOptimizations.status).isGranted,
      };
    }
    if (Platform.isIOS) {
      return {
        'localizacao': (await Permission.locationWhenInUse.status).isGranted,
      };
    }
    return {};
  } catch (_) {
    return {};
  }
});

class PermissoesPage extends ConsumerWidget {
  const PermissoesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(permissoesStatusProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Permissões e bateria')),
      body: statusAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (status) => ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            if (Platform.isAndroid || status.isEmpty) ...[
              _PermissaoCard(
                icon: Icons.alarm,
                titulo: 'Alarme exato',
                descricao:
                    'Permite que o alarme dispare na hora exata configurada.',
                concedida: status['alarme'],
                onConceder: () async {
                  await Permission.scheduleExactAlarm.request();
                  ref.invalidate(permissoesStatusProvider);
                },
              ),
              _PermissaoCard(
                icon: Icons.notifications_outlined,
                titulo: 'Notificações',
                descricao: 'Exibe a notificação quando o alarme disparar.',
                concedida: status['notificacao'],
                onConceder: () async {
                  await Permission.notification.request();
                  ref.invalidate(permissoesStatusProvider);
                },
              ),
            ],
            _PermissaoCard(
              icon: Icons.location_on_outlined,
              titulo: 'Localização',
              descricao:
                  'Detecta sua cidade para aplicar feriados estaduais e municipais.',
              concedida: status['localizacao'],
              onConceder: () async {
                await Permission.locationWhenInUse.request();
                ref.invalidate(permissoesStatusProvider);
              },
            ),
            if (Platform.isAndroid || status.isEmpty) ...[
              _PermissaoCard(
                icon: Icons.battery_charging_full_outlined,
                titulo: 'Otimização de bateria',
                descricao:
                    'Impede que o sistema encerre o app em segundo plano '
                    'e cancele os alarmes.',
                concedida: status['bateria'],
                onConceder: () async {
                  await Permission.ignoreBatteryOptimizations.request();
                  ref.invalidate(permissoesStatusProvider);
                },
              ),
              const _CartaoOemBateria(),
            ],
          ],
        ),
      ),
    );
  }
}

class _PermissaoCard extends StatelessWidget {
  const _PermissaoCard({
    required this.icon,
    required this.titulo,
    required this.descricao,
    required this.concedida,
    required this.onConceder,
  });

  final IconData icon;
  final String titulo;
  final String descricao;
  final bool? concedida; // null = status desconhecido
  final VoidCallback onConceder;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final granted = concedida ?? false;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: cs.primary),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          titulo,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                      if (concedida != null)
                        Icon(
                          granted
                              ? Icons.check_circle
                              : Icons.cancel_outlined,
                          size: 18,
                          color: granted ? Colors.green : cs.error,
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    descricao,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (!granted) ...[
                    const SizedBox(height: 8),
                    FilledButton.tonal(
                      onPressed: onConceder,
                      child: const Text('Conceder'),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Educação sobre otimização de bateria de fabricantes (MIUI, One UI, etc.).
class _CartaoOemBateria extends StatelessWidget {
  const _CartaoOemBateria();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 16),
      color: cs.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, size: 18, color: cs.primary),
                const SizedBox(width: 8),
                Text(
                  'Fabricantes com restrições extras',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Xiaomi (MIUI), Samsung (One UI), Huawei e outros fabricantes '
              'possuem mecanismos próprios de economia de bateria que podem '
              'cancelar alarmes mesmo com a permissão acima concedida.\n\n'
              'Para cada fabricante, acesse Configurações → Bateria → '
              'Gerenciamento de energia → Alarme Feriados → Sem restrições '
              '(o caminho varia por dispositivo).',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: openAppSettings,
              icon: const Icon(Icons.open_in_new, size: 16),
              label: const Text('Abrir configurações do app'),
            ),
          ],
        ),
      ),
    );
  }
}
