import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:alarme_feriados/core/datas.dart';
import 'package:alarme_feriados/domain/models/escala_usuario.dart';
import 'package:alarme_feriados/features/escala/escala_providers.dart';

class EscalaPage extends ConsumerStatefulWidget {
  const EscalaPage({super.key});

  @override
  ConsumerState<EscalaPage> createState() => _EscalaPageState();
}

class _EscalaPageState extends ConsumerState<EscalaPage> {
  static const _presets = [
    ('5×2', 5, 2),
    ('6×1', 6, 1),
    ('12×36', 1, 2),
    ('24×72', 1, 3),
  ];

  bool _ativa = false;
  String _tipoSelecionado = '5×2';
  int _diasTrabalho = 5;
  int _diasFolga = 2;
  DateTime _referencia = DateTime.now();
  bool _inicializado = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_inicializado) return;
    _inicializado = true;
    ref.read(escalaProvider.future).then((escala) {
      if (!mounted) return;
      if (escala == null) return;
      setState(() {
        _ativa = true;
        _diasTrabalho = escala.diasTrabalho;
        _diasFolga = escala.diasFolga;
        _referencia = DateTime.parse(escala.dataInicioReferencia);
        final match = _presets
            .where((p) => p.$2 == escala.diasTrabalho && p.$3 == escala.diasFolga)
            .firstOrNull;
        _tipoSelecionado = match?.$1 ?? '5×2';
      });
    });
  }

  void _selecionarPreset(String tipo) {
    final p = _presets.firstWhere((e) => e.$1 == tipo);
    setState(() {
      _tipoSelecionado = tipo;
      _diasTrabalho = p.$2;
      _diasFolga = p.$3;
    });
  }

  Future<void> _escolherReferencia() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _referencia,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      helpText: 'Primeiro dia de trabalho do ciclo',
    );
    if (picked != null) setState(() => _referencia = picked);
  }

  Future<void> _salvar() async {
    final notifier = ref.read(escalaProvider.notifier);
    if (!_ativa) {
      await notifier.remover();
    } else {
      await notifier.salvar(
        EscalaUsuario(
          tipo: _tipoSelecionado,
          diasTrabalho: _diasTrabalho,
          diasFolga: _diasFolga,
          dataInicioReferencia: isoDate(_referencia),
        ),
      );
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Minha escala')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            title: const Text('Usar escala de trabalho'),
            subtitle: const Text(
              'Alarmes não disparam em dias de folga do ciclo',
            ),
            value: _ativa,
            onChanged: (v) => setState(() => _ativa = v),
          ),
          if (_ativa) ...[
            const SizedBox(height: 16),
            const Text('Tipo de escala'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _presets
                  .map(
                    (p) => ChoiceChip(
                      label: Text(p.$1),
                      selected: _tipoSelecionado == p.$1,
                      onSelected: (_) => _selecionarPreset(p.$1),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Data de referência'),
              subtitle: Text(
                'Primeiro dia de trabalho do ciclo: ${isoDate(_referencia)}',
              ),
              trailing: const Icon(Icons.calendar_today_outlined),
              onTap: _escolherReferencia,
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Ciclo: $_diasTrabalho dia(s) trabalhando, $_diasFolga dia(s) de folga',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
          const SizedBox(height: 32),
          FilledButton(
            onPressed: _salvar,
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }
}
