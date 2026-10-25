import '../utils/formato.dart';

/// debo: dinero que yo debo. meDeben: dinero que me deben a mí.
enum TipoDeuda { debo, meDeben }

extension TipoDeudaTexto on TipoDeuda {
  String get etiqueta => this == TipoDeuda.debo ? 'Debo' : 'Me deben';
  String get accionPago => this == TipoDeuda.debo ? 'Registrar pago' : 'Registrar cobro';
  String get nombrePago => this == TipoDeuda.debo ? 'Pago' : 'Cobro';
}

class Deuda {
  final int? id;
  final TipoDeuda tipo;
  final String persona;
  final String descripcion;
  final double monto;
  final DateTime fecha;
  final DateTime? vencimiento;
  final bool saldada;

  const Deuda({
    this.id,
    required this.tipo,
    required this.persona,
    this.descripcion = '',
    required this.monto,
    required this.fecha,
    this.vencimiento,
    this.saldada = false,
  });

  Deuda copyWith({
    int? id,
    TipoDeuda? tipo,
    String? persona,
    String? descripcion,
    double? monto,
    DateTime? fecha,
    DateTime? vencimiento,
    bool quitarVencimiento = false,
    bool? saldada,
  }) {
    return Deuda(
      id: id ?? this.id,
      tipo: tipo ?? this.tipo,
      persona: persona ?? this.persona,
      descripcion: descripcion ?? this.descripcion,
      monto: monto ?? this.monto,
      fecha: fecha ?? this.fecha,
      vencimiento: quitarVencimiento ? null : (vencimiento ?? this.vencimiento),
      saldada: saldada ?? this.saldada,
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'tipo': tipo.name,
        'persona': persona,
        'descripcion': descripcion,
        'monto': monto,
        'fecha': fechaIso(fecha),
        'vencimiento': vencimiento == null ? null : fechaIso(vencimiento!),
        'saldada': saldada ? 1 : 0,
      };

  factory Deuda.fromMap(Map<String, Object?> m) => Deuda(
        id: m['id'] as int?,
        tipo: TipoDeuda.values.byName(m['tipo'] as String),
        persona: m['persona'] as String,
        descripcion: (m['descripcion'] as String?) ?? '',
        monto: (m['monto'] as num).toDouble(),
        fecha: DateTime.parse(m['fecha'] as String),
        vencimiento: m['vencimiento'] == null
            ? null
            : DateTime.parse(m['vencimiento'] as String),
        saldada: (m['saldada'] as int? ?? 0) == 1,
      );
}
