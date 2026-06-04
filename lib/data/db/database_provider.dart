import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:alarme_feriados/data/db/app_database.dart';

final appDatabaseProvider = FutureProvider<AppDatabase>((ref) async {
  final dir = await getApplicationDocumentsDirectory();
  final db = AppDatabase(
    NativeDatabase(File(p.join(dir.path, 'alarme_feriados.db'))),
  );
  ref.onDispose(db.close);
  return db;
});
