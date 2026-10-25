import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/movimiento.dart';
import '../providers/finanzas_provider.dart';
import '../utils/categorias.dart';
import '../utils/formato.dart';
import '../widgets/comunes.dart';

class ReportesScreen extends StatefulWidget {
  const ReportesScreen({super.key});

  @override
  State<ReportesScreen> createState() => _ReportesScreenState();
}

class _ReportesScreenState extends State<ReportesScreen> {
  DateTime _mes = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  Widget build(BuildContext context) {
    final p = context.watch<FinanzasProvider>();
    final ingresos = p.totalMes(_mes, TipoMovimiento.ingreso);
    final egresos = p.totalMes(_mes, TipoMovimiento.egreso);
    final balance = ingresos - egresos;
    final gastosCat = p.porCategoria(_mes, TipoMovimiento.egreso);
    final ingresosCat = p.porCategoria(_mes, TipoMovimiento.ingreso);

    // Últimos 6 meses terminando en el mes elegido.
    final meses = [
      for (var i = 5; i >= 0; i--) DateTime(_mes.year, _mes.month - i),
    ];
    final datosMeses = [
      for (final m in meses)
        (
          mes: m,
          ing: p.totalMes(m, TipoMovimiento.ingreso),
          egr: p.totalMes(m, TipoMovimiento.egreso),
        ),
    ];
    final maxMes = datosMeses.fold<double>(
        0, (mx, d) => math.max(mx, math.max(d.ing, d.egr)));

    return Scaffold(
      appBar: AppBar(title: const Text('Reportes')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        children: [
          SelectorMes(mes: _mes, onChanged: (m) => setState(() => _mes = m)),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _Linea('Ingresos', moneda(ingresos), kColorIngreso),
                  _Linea('Egresos', moneda(egresos), kColorEgreso),
                  const Divider(),
                  _Linea(
                    'Balance del mes',
                    moneda(balance),
                    balance >= 0 ? kColorIngreso : kColorEgreso,
                    negrita: true,
                  ),
                  if (ingresos > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        balance >= 0
                            ? 'Ahorraste el ${(balance / ingresos * 100).toStringAsFixed(0)}% de tus ingresos'
                            : 'Gastaste ${moneda(-balance)} más de lo que ingresó',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const TituloSeccion('Gastos por categoría'),
          _ListaCategorias(datos: gastosCat, total: egresos, color: kColorEgreso),
          const TituloSeccion('Ingresos por categoría'),
          _ListaCategorias(datos: ingresosCat, total: ingresos, color: kColorIngreso),
          const TituloSeccion('Últimos 6 meses'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: const [
                      _Leyenda('Ingresos', kColorIngreso),
                      SizedBox(width: 16),
                      _Leyenda('Egresos', kColorEgreso),
                    ],
                  ),
                  const SizedBox(height: 12),
                  for (final d in datosMeses)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 44,
                            child: Text(
                              mesCorto(d.mes),
                              style: TextStyle(
                                fontWeight: mismoMes(d.mes, _mes) ? FontWeight.bold : null,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Column(
                              children: [
                                BarraProporcion(
                                  fraccion: maxMes == 0 ? 0.0 : d.ing / maxMes,
                                  color: kColorIngreso,
                                  alto: 8,
                                ),
                                const SizedBox(height: 4),
                                BarraProporcion(
                                  fraccion: maxMes == 0 ? 0.0 : d.egr / maxMes,
                                  color: kColorEgreso,
                                  alto: 8,
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            width: 110,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerRight,
                              child: Text(
                                moneda(d.ing - d.egr),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: d.ing - d.egr >= 0 ? kColorIngreso : kColorEgreso,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Linea extends StatelessWidget {
  final String titulo;
  final String valor;
  final Color color;
  final bool negrita;

  const _Linea(this.titulo, this.valor, this.color, {this.negrita = false});

  @override
  Widget build(BuildContext context) {
    final peso = negrita ? FontWeight.bold : FontWeight.w500;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(titulo, style: TextStyle(fontWeight: peso))),
          Text(valor, style: TextStyle(color: color, fontWeight: peso, fontSize: 16)),
        ],
      ),
    );
  }
}

class _ListaCategorias extends StatelessWidget {
  final List<MapEntry<String, double>> datos;
  final double total;
  final Color color;

  const _ListaCategorias({required this.datos, required this.total, required this.color});

  @override
  Widget build(BuildContext context) {
    if (datos.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Sin registros en este mes.'),
        ),
      );
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            for (final e in datos)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(iconoCategoria(e.key), size: 18, color: color),
                        const SizedBox(width: 8),
                        Expanded(child: Text(e.key)),
                        Text(
                          '${(e.value / total * 100).toStringAsFixed(0)}%',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(width: 12),
                        Text(moneda(e.value),
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    BarraProporcion(fraccion: e.value / total, color: color, alto: 6),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Leyenda extends StatelessWidget {
  final String texto;
  final Color color;

  const _Leyenda(this.texto, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 6),
        Text(texto, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
