class Alarme {
  final int? id;
  final String hora; // "HH:mm"
  // bitmask: bit 0 = segunda, bit 1 = terça, …, bit 6 = domingo
  final int diasDaSemana;
  final bool ativo;
  final String titulo;

  const Alarme({
    this.id,
    required this.hora,
    required this.diasDaSemana,
    this.ativo = true,
    this.titulo = '',
  });

  Alarme copyWith({
    int? id,
    String? hora,
    int? diasDaSemana,
    bool? ativo,
    String? titulo,
  }) =>
      Alarme(
        id: id ?? this.id,
        hora: hora ?? this.hora,
        diasDaSemana: diasDaSemana ?? this.diasDaSemana,
        ativo: ativo ?? this.ativo,
        titulo: titulo ?? this.titulo,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Alarme &&
          other.id == id &&
          other.hora == hora &&
          other.diasDaSemana == diasDaSemana &&
          other.ativo == ativo &&
          other.titulo == titulo;

  @override
  int get hashCode => Object.hash(id, hora, diasDaSemana, ativo, titulo);
}
