import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/deuda.dart';
import '../providers/finanzas_provider.dart';
import '../utils/categorias.dart';
import '../utils/formato.dart';
import '../widgets/comunes.dart';
import 'deuda_detalle_screen.dart';
import 'deuda_form_screen.dart';

class DeudasScreen extends StatefulWidget {
  const DeudasScreen({super.key});

  @override
  State<DeudasScreen> createState() => _DeudasScreenState();
}

class _DeudasScreenState extends State<DeudasScreen> {
  TipoDeuda _tipo = TipoDeuda.debo;
  bool _verSaldadas = false;

  @override
  Widget build(BuildContext context) {
    final p = context.watch<FinanzasProvider>();
    final lista = p.deudas
        .where((d) => d.tipo == _tipo && (_verSaldadas || !d.saldada))
        .toList()
      ..sort(_ordenar);
    final color = _tipo == TipoDeuda.debo ? kColorEgreso : kColorIngreso;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Deudas'),
        actions: [
          IconButton(
            tooltip: _verSaldadas ? 'Ocultar saldadas' : 'Mostrar saldadas',
            icon: Icon(_verSaldadas ? Icons.visibility : Icons.visibility_off_outlined),
            onPressed: () => setState(() => _verSaldadas = !_verSaldadas),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<TipoDeuda>(
                segments: const [
                  ButtonSegment(
                    value: TipoDeuda.debo,
                    label: Text('Debo'),
                    icon: Icon(Icons.call_made),
                  ),
                  ButtonSegment(
                    value: TipoDeuda.meDeben,
                    label: Text('Me deben'),
                    icon: Icon(Icons.call_received),
                  ),
                ],
                selected: {_tipo},
                onSelectionChanged: (s) => setState(() => _tipo = s.first),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Expanded(child: Text('Total pendiente')),
                Text(
                  moneda(p.totalPendiente(_tipo)),
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(color: color, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Expanded(
            child: lista.isEmpty
                ? EstadoVacio(
                    icono: Icons.handshake_outlined,
                    texto: _tipo == TipoDeuda.debo
                        ? 'No tenés deudas pendientes.'
                        : 'Nadie te debe dinero por ahora.',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 96),
                    itemCount: lista.length,
                    itemBuilder: (_, i) => _TarjetaDeuda(deuda: lista[i], color: color),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => DeudaFormScreen(tipoInicial: _tipo)),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Nueva deuda'),
      ),
    );
  }

  /// Pendientes primero; luego por vencimiento más cercano; luego por fecha.
  int _ordenar(Deuda a, Deuda b) {
    if (a.saldada != b.saldada) return a.saldada ? 1 : -1;
    final va = a.vencimiento, vb = b.vencimiento;
    if (va != null && vb != null) return va.compareTo(vb);
    if (va != null) return -1;
    if (vb != null) return 1;
    return b.fecha.compareTo(a.fecha);
  }
}

class _TarjetaDeuda extends StatelessWidget {
  final Deuda deuda;
  final Color color;

  const _TarjetaDeuda({required this.deuda, required this.color});

  @override
  Widget build(BuildContext context) {
    final p = context.read<FinanzasProvider>();
    final d = deuda;
    final hoy = soloFecha(DateTime.now());
    final vencida = !d.saldada && d.vencimiento != null && d.vencimiento!.isBefore(hoy);
    final tema = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => DeudaDetalleScreen(deudaId: d.id!)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(d.persona,
                        style: tema.textTheme.titleMedium,
                        overflow: TextOverflow.ellipsis),
                  ),
                  if (d.saldada)
                    const Chip(
                      label: Text('Saldada'),
                      avatar: Icon(Icons.check_circle, size: 18),
                      visualDensity: VisualDensity.compact,
                    )
                  else
                    Text(
                      moneda(p.pendiente(d)),
                      style: tema.textTheme.titleMedium
                          ?.copyWith(color: color, fontWeight: FontWeight.w600),
                    ),
                ],
              ),
              if (d.descripcion.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(d.descripcion,
                    style: tema.textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
              const SizedBox(height: 12),
              BarraProporcion(fraccion: p.progreso(d), color: color, alto: 8),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${d.tipo.nombrePago}s: ${moneda(p.pagado(d.id!))} de ${moneda(d.monto)}',
                      style: tema.textTheme.bodySmall,
                    ),
                  ),
                  if (d.vencimiento != null && !d.saldada)
                    Text(
                      vencida
                          ? 'Vencida ${fechaCorta(d.vencimiento!)}'
                          : 'Vence ${fechaCorta(d.vencimiento!)}',
                      style: tema.textTheme.bodySmall?.copyWith(
                        color: vencida ? kColorEgreso : null,
                        fontWeight: vencida ? FontWeight.w600 : null,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
