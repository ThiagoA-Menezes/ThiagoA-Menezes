import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:alarme_feriados/domain/models/localizacao.dart';
import 'package:alarme_feriados/features/localizacao/localizacao_providers.dart';
import 'package:alarme_feriados/services/localizacao_service.dart';

class LocalizacaoPage extends ConsumerStatefulWidget {
  const LocalizacaoPage({super.key});

  @override
  ConsumerState<LocalizacaoPage> createState() => _LocalizacaoPageState();
}

class _LocalizacaoPageState extends ConsumerState<LocalizacaoPage> {
  late final TextEditingController _cidadeCtrl;
  late final TextEditingController _estadoCtrl;
  late final TextEditingController _ibgeCtrl;
  bool _detectando = false;
  bool _inicializado = false;

  @override
  void initState() {
    super.initState();
    _cidadeCtrl = TextEditingController();
    _estadoCtrl = TextEditingController();
    _ibgeCtrl = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_inicializado) return;
    _inicializado = true;
    ref.read(localizacaoProvider.future).then((loc) {
      if (!mounted || loc == null) return;
      _cidadeCtrl.text = loc.cidade;
      _estadoCtrl.text = loc.estado;
      _ibgeCtrl.text = loc.codigoIBGE == '0' ? '' : loc.codigoIBGE;
    });
  }

  @override
  void dispose() {
    _cidadeCtrl.dispose();
    _estadoCtrl.dispose();
    _ibgeCtrl.dispose();
    super.dispose();
  }

  Future<void> _detectar() async {
    setState(() => _detectando = true);
    try {
      final loc = await LocalizacaoService.detectar();
      if (!mounted) return;
      if (loc == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível detectar a localização.'),
          ),
        );
        return;
      }
      _cidadeCtrl.text = loc.cidade;
      _estadoCtrl.text = loc.estado;
      _ibgeCtrl.text = '';
    } finally {
      if (mounted) setState(() => _detectando = false);
    }
  }

  Future<void> _salvar() async {
    final cidade = _cidadeCtrl.text.trim();
    final estado = _estadoCtrl.text.trim().toUpperCase();
    if (cidade.isEmpty || estado.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha cidade e estado.')),
      );
      return;
    }
    final ibge = _ibgeCtrl.text.trim();
    await ref.read(localizacaoProvider.notifier).salvar(
          Localizacao(
            cidade: cidade,
            estado: estado,
            codigoIBGE: ibge.isEmpty ? '0' : ibge,
          ),
        );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Localização')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          FilledButton.tonal(
            onPressed: _detectando ? null : _detectar,
            child: _detectando
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Detectar automaticamente'),
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 8),
          TextField(
            controller: _cidadeCtrl,
            decoration: const InputDecoration(
              labelText: 'Cidade',
              border: OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _estadoCtrl,
            decoration: const InputDecoration(
              labelText: 'Estado (UF)',
              border: OutlineInputBorder(),
              counterText: '',
            ),
            maxLength: 2,
            textCapitalization: TextCapitalization.characters,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _ibgeCtrl,
            decoration: const InputDecoration(
              labelText: 'Código IBGE (opcional)',
              helperText: 'Necessário para feriados municipais',
              border: OutlineInputBorder(),
              counterText: '',
            ),
            keyboardType: TextInputType.number,
            maxLength: 7,
          ),
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
