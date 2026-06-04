class EscalaUsuario {
  final int? id;
  final String tipo; // ex: "5x2", "6x1", "12x36"
  final int diasTrabalho;
  final int diasFolga;
  // Ancora o ciclo rotativo; ISO "YYYY-MM-DD"
  final String dataInicioReferencia;

  const EscalaUsuario({
    this.id,
    required this.tipo,
    required this.diasTrabalho,
    required this.diasFolga,
    required this.dataInicioReferencia,
  });

  EscalaUsuario copyWith({
    int? id,
    String? tipo,
    int? diasTrabalho,
    int? diasFolga,
    String? dataInicioReferencia,
  }) =>
      EscalaUsuario(
        id: id ?? this.id,
        tipo: tipo ?? this.tipo,
        diasTrabalho: diasTrabalho ?? this.diasTrabalho,
        diasFolga: diasFolga ?? this.diasFolga,
        dataInicioReferencia: dataInicioReferencia ?? this.dataInicioReferencia,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EscalaUsuario &&
          other.id == id &&
          other.tipo == tipo &&
          other.diasTrabalho == diasTrabalho &&
          other.diasFolga == diasFolga &&
          other.dataInicioReferencia == dataInicioReferencia;

  @override
  int get hashCode =>
      Object.hash(id, tipo, diasTrabalho, diasFolga, dataInicioReferencia);
}
