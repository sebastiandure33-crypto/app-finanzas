import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/movimiento.dart';
import '../providers/finanzas_provider.dart';
import '../utils/categorias.dart';
import '../utils/dialogos.dart';
import '../utils/formato.dart';
import '../widgets/comunes.dart';
import 'movimiento_form_screen.dart';

class MovimientosScreen extends StatefulWidget {
  const MovimientosScreen({super.key});

  @override
  State<MovimientosScreen> createState() => _MovimientosScreenState();
}

/// 0 = todos, 1 = ingresos, 2 = egresos
class _MovimientosScreenState extends State<MovimientosScreen> {
  DateTime _mes = DateTime(DateTime.now().year, DateTime.now().month);
  int _filtro = 0;

  void _abrir(BuildContext context, {Movimiento? m, TipoMovimiento? tipo}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MovimientoFormScreen(
          movimiento: m,
          tipoInicial: tipo ?? TipoMovimiento.egreso,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<FinanzasProvider>();
    var lista = p.movimientosDelMes(_mes);
    if (_filtro == 1) lista = lista.where((m) => m.esIngreso).toList();
    if (_filtro == 2) lista = lista.where((m) => !m.esIngreso).toList();

    final ingresos = p.totalMes(_mes, TipoMovimiento.ingreso);
    final egresos = p.totalMes(_mes, TipoMovimiento.egreso);

    // Agrupar por día manteniendo el orden (más reciente primero).
    final grupos = <DateTime, List<Movimiento>>{};
    for (final m in lista) {
      grupos.putIfAbsent(soloFecha(m.fecha), () => []).add(m);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Movimientos')),
      body: Column(
        children: [
          SelectorMes(mes: _mes, onChanged: (m) => setState(() => _mes = m)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 0, label: Text('Todos')),
                  ButtonSegment(value: 1, label: Text('Ingresos')),
                  ButtonSegment(value: 2, label: Text('Egresos')),
                ],
                selected: {_filtro},
                showSelectedIcon: false,
                onSelectionChanged: (s) => setState(() => _filtro = s.first),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                Expanded(child: _Total('Ingresos', ingresos, kColorIngreso)),
                Expanded(child: _Total('Egresos', egresos, kColorEgreso)),
                Expanded(child: _Total('Balance', ingresos - egresos, null)),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: lista.isEmpty
                ? const EstadoVacio(
                    icono: Icons.receipt_long_outlined,
                    texto: 'No hay movimientos en este mes.',
                  )
                : ListView(
                    padding: const EdgeInsets.only(bottom: 96),
                    children: [
                      for (final entrada in grupos.entries) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                          child: Text(
                            fechaLarga(entrada.key),
                            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                          ),
                        ),
                        for (final m in entrada.value)
                          Dismissible(
                            key: ValueKey('mov-${m.id}'),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              color: kColorEgreso,
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 24),
                              child: const Icon(Icons.delete_outline, color: Colors.white),
                            ),
                            confirmDismiss: (_) => confirmar(
                              context,
                              titulo: 'Eliminar movimiento',
                              mensaje: '¿Eliminar ${m.categoria} por ${moneda(m.monto)}?',
                            ),
                            onDismissed: (_) => p.eliminarMovimiento(m),
                            child: MovimientoTile(
                              movimiento: m,
                              mostrarFecha: false,
                              onTap: () => _abrir(context, m: m),
                            ),
                          ),
                      ],
                    ],
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Nuevo movimiento',
        onPressed: () => _abrir(
          context,
          tipo: _filtro == 1 ? TipoMovimiento.ingreso : TipoMovimiento.egreso,
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _Total extends StatelessWidget {
  final String titulo;
  final double monto;
  final Color? color;

  const _Total(this.titulo, this.monto, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(titulo, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            moneda(monto),
            style: TextStyle(fontWeight: FontWeight.w600, color: color),
          ),
        ),
      ],
    );
  }
}
