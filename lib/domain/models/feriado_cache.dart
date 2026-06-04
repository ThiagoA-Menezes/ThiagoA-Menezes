class FeriadoCache {
  final int? id;
  final String data; // ISO "YYYY-MM-DD"
  final String nome;
  final String tipo; // "nacional" | "estadual" | "municipal"
  final String codigoIBGE;
  final int ano;

  const FeriadoCache({
    this.id,
    required this.data,
    required this.nome,
    required this.tipo,
    required this.codigoIBGE,
    required this.ano,
  });

  FeriadoCache copyWith({
    int? id,
    String? data,
    String? nome,
    String? tipo,
    String? codigoIBGE,
    int? ano,
  }) =>
      FeriadoCache(
        id: id ?? this.id,
        data: data ?? this.data,
        nome: nome ?? this.nome,
        tipo: tipo ?? this.tipo,
        codigoIBGE: codigoIBGE ?? this.codigoIBGE,
        ano: ano ?? this.ano,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FeriadoCache &&
          other.id == id &&
          other.data == data &&
          other.nome == nome &&
          other.tipo == tipo &&
          other.codigoIBGE == codigoIBGE &&
          other.ano == ano;

  @override
  int get hashCode => Object.hash(id, data, nome, tipo, codigoIBGE, ano);
}
