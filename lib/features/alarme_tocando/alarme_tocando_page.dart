import 'package:flutter/material.dart';

import 'package:alarme_feriados/services/alarm_service.dart';

class AlarmeTocandoPage extends StatelessWidget {
  final int alarmId;
  final String titulo;

  const AlarmeTocandoPage({
    super.key,
    required this.alarmId,
    required this.titulo,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              const Icon(Icons.alarm, size: 96, color: Colors.white),
              Text(
                titulo.isEmpty ? 'Alarme Feriados' : titulo,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _BotaoAcao(
                    label: 'Soneca\n10 min',
                    icon: Icons.snooze,
                    onTap: () => _soneca(context),
                  ),
                  _BotaoAcao(
                    label: 'Parar',
                    icon: Icons.stop_circle_outlined,
                    onTap: () => _parar(context),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _parar(BuildContext context) async {
    await AlarmService.cancelar(alarmId);
    if (context.mounted) Navigator.of(context).pop();
  }

  Future<void> _soneca(BuildContext context) async {
    await AlarmService.soneca(alarmId);
    if (context.mounted) Navigator.of(context).pop();
  }
}

class _BotaoAcao extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _BotaoAcao({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.white24,
            child: Icon(icon, size: 40, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
