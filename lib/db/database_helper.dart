import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/deuda.dart';
import '../models/movimiento.dart';
import '../models/pago.dart';

class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  static const _nombreDb = 'finanzas.db';
  static const _version = 1;

  Database? _db;

  Future<Database> get db async => _db ??= await _abrir();

  Future<Database> _abrir() async {
    final ruta = join(await getDatabasesPath(), _nombreDb);
    return openDatabase(
      ruta,
      version: _version,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE movimientos (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            tipo TEXT NOT NULL,
            monto REAL NOT NULL,
            categoria TEXT NOT NULL,
            descripcion TEXT NOT NULL DEFAULT '',
            fecha TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE deudas (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            tipo TEXT NOT NULL,
            persona TEXT NOT NULL,
            descripcion TEXT NOT NULL DEFAULT '',
            monto REAL NOT NULL,
            fecha TEXT NOT NULL,
            vencimiento TEXT,
            saldada INTEGER NOT NULL DEFAULT 0
          )
        ''');
        await db.execute('''
          CREATE TABLE pagos (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            deuda_id INTEGER NOT NULL REFERENCES deudas(id) ON DELETE CASCADE,
            monto REAL NOT NULL,
            fecha TEXT NOT NULL,
            nota TEXT NOT NULL DEFAULT '',
            movimiento_id INTEGER REFERENCES movimientos(id) ON DELETE SET NULL
          )
        ''');
        await db.execute(
            'CREATE INDEX idx_movimientos_fecha ON movimientos(fecha)');
        await db.execute('CREATE INDEX idx_pagos_deuda ON pagos(deuda_id)');
      },
    );
  }

  // ---------- Movimientos ----------

  Future<List<Movimiento>> movimientos() async {
    final filas = await (await db)
        .query('movimientos', orderBy: 'fecha DESC, id DESC');
    return filas.map(Movimiento.fromMap).toList();
  }

  Future<int> insertarMovimiento(Movimiento m) async {
    final datos = m.toMap()..remove('id');
    return (await db).insert('movimientos', datos);
  }

  Future<void> actualizarMovimiento(Movimiento m) async {
    await (await db).update('movimientos', m.toMap(),
        where: 'id = ?', whereArgs: [m.id]);
  }

  Future<void> eliminarMovimiento(int id) async {
    await (await db).delete('movimientos', where: 'id = ?', whereArgs: [id]);
  }

  // ---------- Deudas ----------

  Future<List<Deuda>> deudas() async {
    final filas = await (await db).query('deudas', orderBy: 'fecha DESC, id DESC');
    return filas.map(Deuda.fromMap).toList();
  }

  Future<int> insertarDeuda(Deuda d) async {
    final datos = d.toMap()..remove('id');
    return (await db).insert('deudas', datos);
  }

  Future<void> actualizarDeuda(Deuda d) async {
    await (await db)
        .update('deudas', d.toMap(), where: 'id = ?', whereArgs: [d.id]);
  }

  Future<void> eliminarDeuda(int id) async {
    await (await db).delete('deudas', where: 'id = ?', whereArgs: [id]);
  }

  // ---------- Pagos ----------

  Future<List<Pago>> pagos() async {
    final filas = await (await db).query('pagos', orderBy: 'fecha DESC, id DESC');
    return filas.map(Pago.fromMap).toList();
  }

  Future<int> insertarPago(Pago p) async {
    final datos = p.toMap()..remove('id');
    return (await db).insert('pagos', datos);
  }

  Future<void> eliminarPago(int id) async {
    await (await db).delete('pagos', where: 'id = ?', whereArgs: [id]);
  }
}
