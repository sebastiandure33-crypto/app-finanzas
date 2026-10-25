import 'dart:collection';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../db/database_helper.dart';
import '../models/deuda.dart';
import '../models/movimiento.dart';
import '../models/pago.dart';
import '../utils/categorias.dart';
import '../utils/formato.dart';

class FinanzasProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;

  List<Movimiento> _movimientos = [];
  List<Deuda> _deudas = [];
  List<Pago> _pagos = [];
  bool _cargando = true;

  bool get cargando => _cargando;
  UnmodifiableListView<Movimiento> get movimientos =>
      UnmodifiableListView(_movimientos);
  UnmodifiableListView<Deuda> get deudas => UnmodifiableListView(_deudas);

  Future<void> cargar() async {
    _movimientos = await _db.movimientos();
    _deudas = await _db.deudas();
    _pagos = await _db.pagos();
    _cargando = false;
    notifyListeners();
  }

  // ================= Movimientos =================

  Future<void> agregarMovimiento(Movimiento m) async {
    await _db.insertarMovimiento(m);
    await cargar();
  }

  Future<void> actualizarMovimiento(Movimiento m) async {
    await _db.actualizarMovimiento(m);
    await cargar();
  }

  Future<void> eliminarMovimiento(Movimiento m) async {
    if (m.id == null) return;
    // Se quita de inmediato de la lista para que la UI (Dismissible) se actualice.
    _movimientos = _movimientos.where((x) => x.id != m.id).toList();
    notifyListeners();
    await _db.eliminarMovimiento(m.id!);
    await cargar();
  }

  double get saldo =>
      _movimientos.fold(0.0, (suma, m) => suma + m.montoConSigno);

  List<Movimiento> movimientosDelMes(DateTime mes) =>
      _movimientos.where((m) => mismoMes(m.fecha, mes)).toList();

  double totalMes(DateTime mes, TipoMovimiento tipo) => _movimientos
      .where((m) => m.tipo == tipo && mismoMes(m.fecha, mes))
      .fold(0.0, (suma, m) => suma + m.monto);

  /// Totales por categoría del mes, de mayor a menor.
  List<MapEntry<String, double>> porCategoria(
      DateTime mes, TipoMovimiento tipo) {
    final mapa = <String, double>{};
    for (final m in _movimientos) {
      if (m.tipo == tipo && mismoMes(m.fecha, mes)) {
        mapa[m.categoria] = (mapa[m.categoria] ?? 0) + m.monto;
      }
    }
    final lista = mapa.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return lista;
  }

  // ================= Deudas =================

  Deuda? deudaPorId(int id) {
    for (final d in _deudas) {
      if (d.id == id) return d;
    }
    return null;
  }

  List<Pago> pagosDe(int deudaId) =>
      _pagos.where((p) => p.deudaId == deudaId).toList();

  double pagado(int deudaId) =>
      pagosDe(deudaId).fold(0.0, (suma, p) => suma + p.monto);

  double pendiente(Deuda d) =>
      d.id == null ? d.monto : math.max(0.0, d.monto - pagado(d.id!));

  double progreso(Deuda d) {
    if (d.monto <= 0 || d.id == null) return 0;
    return (pagado(d.id!) / d.monto).clamp(0.0, 1.0);
  }

  double totalPendiente(TipoDeuda tipo) => _deudas
      .where((d) => d.tipo == tipo && !d.saldada)
      .fold(0.0, (suma, d) => suma + pendiente(d));

  int cantidadPendientes(TipoDeuda tipo) =>
      _deudas.where((d) => d.tipo == tipo && !d.saldada).length;

  /// Deudas pendientes vencidas o que vencen en los próximos [dias] días.
  List<Deuda> proximosVencimientos({int dias = 7}) {
    final limite = soloFecha(DateTime.now()).add(Duration(days: dias));
    final lista = _deudas
        .where((d) =>
            !d.saldada &&
            d.vencimiento != null &&
            !d.vencimiento!.isAfter(limite))
        .toList()
      ..sort((a, b) => a.vencimiento!.compareTo(b.vencimiento!));
    return lista;
  }

  Future<int> agregarDeuda(Deuda d) async {
    final id = await _db.insertarDeuda(d);
    await cargar();
    return id;
  }

  Future<void> actualizarDeuda(Deuda d) async {
    final saldada = d.id != null && d.monto - pagado(d.id!) <= 0;
    await _db.actualizarDeuda(d.copyWith(saldada: saldada));
    await cargar();
  }

  Future<void> eliminarDeuda(Deuda d) async {
    if (d.id == null) return;
    await _db.eliminarDeuda(d.id!);
    await cargar();
  }

  /// Registra un pago (si debo) o un cobro (si me deben).
  /// Si [registrarMovimiento] es true, también crea el egreso/ingreso.
  Future<void> registrarPago({
    required Deuda deuda,
    required double monto,
    required DateTime fecha,
    String nota = '',
    bool registrarMovimiento = true,
  }) async {
    if (deuda.id == null) return;
    int? movimientoId;
    if (registrarMovimiento) {
      final esPago = deuda.tipo == TipoDeuda.debo;
      movimientoId = await _db.insertarMovimiento(Movimiento(
        tipo: esPago ? TipoMovimiento.egreso : TipoMovimiento.ingreso,
        monto: monto,
        categoria: esPago ? kCatPagoDeudas : kCatCobroDeudas,
        descripcion:
            '${esPago ? 'Pago a' : 'Cobro a'} ${deuda.persona}${nota.isEmpty ? '' : ' · $nota'}',
        fecha: fecha,
      ));
    }
    await _db.insertarPago(Pago(
      deudaId: deuda.id!,
      monto: monto,
      fecha: fecha,
      nota: nota,
      movimientoId: movimientoId,
    ));
    await _recalcularEstado(deuda.id!);
  }

  /// Elimina un pago y el movimiento que generó, si existe.
  Future<void> eliminarPago(Pago p) async {
    if (p.id == null) return;
    await _db.eliminarPago(p.id!);
    if (p.movimientoId != null) {
      await _db.eliminarMovimiento(p.movimientoId!);
    }
    await _recalcularEstado(p.deudaId);
  }

  Future<void> _recalcularEstado(int deudaId) async {
    _pagos = await _db.pagos();
    final d = deudaPorId(deudaId);
    if (d != null) {
      final saldada = d.monto - pagado(deudaId) <= 0;
      if (saldada != d.saldada) {
        await _db.actualizarDeuda(d.copyWith(saldada: saldada));
      }
    }
    await cargar();
  }
}
