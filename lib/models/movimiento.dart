import '../utils/formato.dart';

enum TipoMovimiento { ingreso, egreso }

class Movimiento {
  final int? id;
  final TipoMovimiento tipo;
  final double monto;
  final String categoria;
  final String descripcion;
  final DateTime fecha;

  const Movimiento({
    this.id,
    required this.tipo,
    required this.monto,
    required this.categoria,
    this.descripcion = '',
    required this.fecha,
  });

  bool get esIngreso => tipo == TipoMovimiento.ingreso;

  /// Monto con signo: positivo si es ingreso, negativo si es egreso.
  double get montoConSigno => esIngreso ? monto : -monto;

  Movimiento copyWith({
    int? id,
    TipoMovimiento? tipo,
    double? monto,
    String? categoria,
    String? descripcion,
    DateTime? fecha,
  }) {
    return Movimiento(
      id: id ?? this.id,
      tipo: tipo ?? this.tipo,
      monto: monto ?? this.monto,
      categoria: categoria ?? this.categoria,
      descripcion: descripcion ?? this.descripcion,
      fecha: fecha ?? this.fecha,
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'tipo': tipo.name,
        'monto': monto,
        'categoria': categoria,
        'descripcion': descripcion,
        'fecha': fechaIso(fecha),
      };

  factory Movimiento.fromMap(Map<String, Object?> m) => Movimiento(
        id: m['id'] as int?,
        tipo: TipoMovimiento.values.byName(m['tipo'] as String),
        monto: (m['monto'] as num).toDouble(),
        categoria: m['categoria'] as String,
        descripcion: (m['descripcion'] as String?) ?? '',
        fecha: DateTime.parse(m['fecha'] as String),
      );
}
