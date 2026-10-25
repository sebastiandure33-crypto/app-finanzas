import '../utils/formato.dart';

/// Pago (o cobro) parcial o total de una deuda.
class Pago {
  final int? id;
  final int deudaId;
  final double monto;
  final DateTime fecha;
  final String nota;

  /// Movimiento de ingreso/egreso generado al registrar el pago, si existe.
  final int? movimientoId;

  const Pago({
    this.id,
    required this.deudaId,
    required this.monto,
    required this.fecha,
    this.nota = '',
    this.movimientoId,
  });

  Map<String, Object?> toMap() => {
        'id': id,
        'deuda_id': deudaId,
        'monto': monto,
        'fecha': fechaIso(fecha),
        'nota': nota,
        'movimiento_id': movimientoId,
      };

  factory Pago.fromMap(Map<String, Object?> m) => Pago(
        id: m['id'] as int?,
        deudaId: m['deuda_id'] as int,
        monto: (m['monto'] as num).toDouble(),
        fecha: DateTime.parse(m['fecha'] as String),
        nota: (m['nota'] as String?) ?? '',
        movimientoId: m['movimiento_id'] as int?,
      );
}
