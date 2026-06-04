import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Instância de [SharedPreferences] injetada em `main.dart` antes de `runApp`.
/// Nunca acesse diretamente fora do escopo do ProviderScope.
final sharedPrefsProvider = Provider<SharedPreferences>(
  (_) => throw StateError('sharedPrefsProvider não foi inicializado'),
);

class ClockFormatNotifier extends Notifier<bool> {
  static const _key = 'use_24h';

  @override
  bool build() => ref.read(sharedPrefsProvider).getBool(_key) ?? true;

  void toggle() {
    state = !state;
    ref.read(sharedPrefsProvider).setBool(_key, state);
  }
}

/// true = 24h · false = 12h (AM/PM).
final clockFormatProvider =
    NotifierProvider<ClockFormatNotifier, bool>(ClockFormatNotifier.new);
