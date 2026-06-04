class Localizacao {
  final int? id;
  final String cidade;
  final String estado; // UF — 2 caracteres
  final String codigoIBGE;

  const Localizacao({
    this.id,
    required this.cidade,
    required this.estado,
    required this.codigoIBGE,
  });

  Localizacao copyWith({
    int? id,
    String? cidade,
    String? estado,
    String? codigoIBGE,
  }) =>
      Localizacao(
        id: id ?? this.id,
        cidade: cidade ?? this.cidade,
        estado: estado ?? this.estado,
        codigoIBGE: codigoIBGE ?? this.codigoIBGE,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Localizacao &&
          other.id == id &&
          other.cidade == cidade &&
          other.estado == estado &&
          other.codigoIBGE == codigoIBGE;

  @override
  int get hashCode => Object.hash(id, cidade, estado, codigoIBGE);
}
