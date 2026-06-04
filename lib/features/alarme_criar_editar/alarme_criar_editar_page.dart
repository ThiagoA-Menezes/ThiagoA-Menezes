import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:alarme_feriados/domain/models/alarme.dart';
import 'package:alarme_feriados/features/home/home_providers.dart';

class AlarmeCriarEditarPage extends ConsumerStatefulWidget {
  const AlarmeCriarEditarPage({super.key, this.alarme});
  final Alarme? alarme;

  @override
  ConsumerState<AlarmeCriarEditarPage> createState() =>
      _AlarmeCriarEditarPageState();
}

class _AlarmeCriarEditarPageState
    extends ConsumerState<AlarmeCriarEditarPage> {
  late final TextEditingController _tituloCtrl;
  late String _hora;
  late int _diasDaSemana;
  late bool _ativo;

  static const _nomesDias = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];

  @override
  void initState() {
    super.initState();
    final a = widget.alarme;
    _tituloCtrl = TextEditingController(text: a?.titulo ?? '');
    _hora = a?.hora ?? '07:00';
    _diasDaSemana = a?.diasDaSemana ?? 0x1F;
    _ativo = a?.ativo ?? true;
  }

  @override
  void dispose() {
    _tituloCtrl.dispose();
    super.dispose();
  }

  bool get _editando => widget.alarme != null;

  Future<void> _escolherHora() async {
    final partes = _hora.split(':');
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: int.parse(partes[0]),
        minute: int.parse(partes[1]),
      ),
    );
    if (picked == null) return;
    setState(() {
      _hora =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    });
  }

  void _toggleDia(int bit) => setState(() => _diasDaSemana ^= (1 << bit));

  Future<void> _salvar() async {
    if (_diasDaSemana == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione ao menos um dia.')),
      );
      return;
    }
    final novo = Alarme(
      id: widget.alarme?.id,
      hora: _hora,
      diasDaSemana: _diasDaSemana,
      ativo: _ativo,
      titulo: _tituloCtrl.text.trim(),
    );
    final notifier = ref.read(alarmesProvider.notifier);
    if (_editando) {
      await notifier.atualizar(novo);
    } else {
      await notifier.criar(novo);
    }
    if (mounted) Navigator.pop(context);
  }

  Future<void> _confirmarDelete() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir alarme?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmar != true) return;
    await ref.read(alarmesProvider.notifier).deletar(widget.alarme!.id!);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_editando ? 'Editar alarme' : 'Novo alarme'),
        actions: [
          if (_editando)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Excluir',
              onPressed: _confirmarDelete,
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: GestureDetector(
              onTap: _escolherHora,
              child: Text(
                _hora,
                style: Theme.of(context).textTheme.displayLarge,
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text('Repetir'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (var i = 0; i < 7; i++)
                FilterChip(
                  label: Text(_nomesDias[i]),
                  selected: _diasDaSemana & (1 << i) != 0,
                  onSelected: (_) => _toggleDia(i),
                ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _tituloCtrl,
            decoration: const InputDecoration(
              labelText: 'Título (opcional)',
              border: OutlineInputBorder(),
            ),
            maxLength: 50,
          ),
          SwitchListTile(
            title: const Text('Ativo'),
            value: _ativo,
            onChanged: (v) => setState(() => _ativo = v),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _salvar,
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }
}
