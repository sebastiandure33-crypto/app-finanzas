import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/deuda.dart';
import '../models/movimiento.dart';
import '../providers/finanzas_provider.dart';
import '../utils/categorias.dart';
import '../utils/formato.dart';
import '../widgets/comunes.dart';
import 'deuda_detalle_screen.dart';
import 'movimiento_form_screen.dart';

class ResumenScreen extends StatelessWidget {
  final ValueChanged<int> irA;

  const ResumenScreen({super.key, required this.irA});

  void _nuevoMovimiento(BuildContext context, TipoMovimiento tipo) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => MovimientoFormScreen(tipoInicial: tipo)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<FinanzasProvider>();
    if (p.cargando) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final hoy = DateTime.now();
    final ingresos = p.totalMes(hoy, TipoMovimiento.ingreso);
    final egresos = p.totalMes(hoy, TipoMovimiento.egreso);
    final vencimientos = p.proximosVencimientos();
    final ultimos = p.movimientos.take(5).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Mis Finanzas')),
      body: RefreshIndicator(
        onRefresh: p.cargar,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
          children: [
            _TarjetaSaldo(saldo: p.saldo),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _TarjetaMonto(
                    titulo: 'Ingresos del mes',
                    monto: ingresos,
                    color: kColorIngreso,
                    icono: Icons.south_west,
                    onTap: () => _nuevoMovimiento(context, TipoMovimiento.ingreso),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _TarjetaMonto(
                    titulo: 'Egresos del mes',
                    monto: egresos,
                    color: kColorEgreso,
                    icono: Icons.north_east,
                    onTap: () => _nuevoMovimiento(context, TipoMovimiento.egreso),
                  ),
                ),
              ],
            ),
            TituloSeccion(
              'Deudas pendientes',
              accion: TextButton(onPressed: () => irA(2), child: const Text('Ver todas')),
            ),
            Card(
              child: Column(
                children: [
                  _FilaDeuda(
                    titulo: 'Debo',
                    cantidad: p.cantidadPendientes(TipoDeuda.debo),
                    monto: p.totalPendiente(TipoDeuda.debo),
                    color: kColorEgreso,
                  ),
                  const Divider(height: 1),
                  _FilaDeuda(
                    titulo: 'Me deben',
                    cantidad: p.cantidadPendientes(TipoDeuda.meDeben),
                    monto: p.totalPendiente(TipoDeuda.meDeben),
                    color: kColorIngreso,
                  ),
                ],
              ),
            ),
            if (vencimientos.isNotEmpty) ...[
              const TituloSeccion('Vencimientos próximos'),
              Card(
                child: Column(
                  children: [
                    for (final d in vencimientos) _FilaVencimiento(deuda: d),
                  ],
                ),
              ),
            ],
            TituloSeccion(
              'Últimos movimientos',
              accion: TextButton(onPressed: () => irA(1), child: const Text('Ver todos')),
            ),
            if (ultimos.isEmpty)
              const EstadoVacio(
                icono: Icons.receipt_long_outlined,
                texto: 'Todavía no registraste movimientos.\nToca "+ Movimiento" para empezar.',
              )
            else
              Card(
                child: Column(
                  children: [
                    for (final m in ultimos)
                      MovimientoTile(
                        movimiento: m,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MovimientoFormScreen(movimiento: m),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _nuevoMovimiento(context, TipoMovimiento.egreso),
        icon: const Icon(Icons.add),
        label: const Text('Movimiento'),
      ),
    );
  }
}

class _TarjetaSaldo extends StatelessWidget {
  final double saldo;

  const _TarjetaSaldo({required this.saldo});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      color: cs.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Saldo disponible',
                style: TextStyle(color: cs.onPrimaryContainer)),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                moneda(saldo),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: cs.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TarjetaMonto extends StatelessWidget {
  final String titulo;
  final double monto;
  final Color color;
  final IconData icono;
  final VoidCallback onTap;

  const _TarjetaMonto({
    required this.titulo,
    required this.monto,
    required this.color,
    required this.icono,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icono, color: color, size: 18),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(titulo,
                        style: Theme.of(context).textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  moneda(monto),
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(color: color, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilaDeuda extends StatelessWidget {
  final String titulo;
  final int cantidad;
  final double monto;
  final Color color;

  const _FilaDeuda({
    required this.titulo,
    required this.cantidad,
    required this.monto,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(titulo),
      subtitle: Text(cantidad == 1 ? '1 pendiente' : '$cantidad pendientes'),
      trailing: Text(
        moneda(monto),
        style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 16),
      ),
    );
  }
}

class _FilaVencimiento extends StatelessWidget {
  final Deuda deuda;

  const _FilaVencimiento({required this.deuda});

  @override
  Widget build(BuildContext context) {
    final p = context.read<FinanzasProvider>();
    final hoy = soloFecha(DateTime.now());
    final dias = deuda.vencimiento!.difference(hoy).inDays;
    final String cuando;
    if (dias < 0) {
      cuando = 'Vencida hace ${-dias} ${-dias == 1 ? 'día' : 'días'}';
    } else if (dias == 0) {
      cuando = 'Vence hoy';
    } else {
      cuando = 'Vence en $dias ${dias == 1 ? 'día' : 'días'}';
    }
    final urgente = dias <= 0;
    return ListTile(
      leading: Icon(
        urgente ? Icons.warning_amber_rounded : Icons.event_outlined,
        color: urgente ? kColorEgreso : null,
      ),
      title: Text('${deuda.tipo.etiqueta}: ${deuda.persona}'),
      subtitle: Text(cuando),
      trailing: Text(moneda(p.pendiente(deuda))),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => DeudaDetalleScreen(deudaId: deuda.id!)),
      ),
    );
  }
}
