import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/deuda.dart';
import '../models/pago.dart';
import '../providers/finanzas_provider.dart';
import '../utils/categorias.dart';
import '../utils/dialogos.dart';
import '../utils/formato.dart';
import '../widgets/comunes.dart';
import 'deuda_form_screen.dart';

class DeudaDetalleScreen extends StatelessWidget {
  final int deudaId;

  const DeudaDetalleScreen({super.key, required this.deudaId});

  Future<void> _eliminar(BuildContext context, Deuda d) async {
    final ok = await confirmar(
      context,
      titulo: 'Eliminar deuda',
      mensaje:
          'Se eliminarán la deuda y su historial de ${d.tipo.nombrePago.toLowerCase()}s. '
          'Los movimientos ya registrados en Ingresos/Egresos se conservan.',
    );
    if (!ok || !context.mounted) return;
    final p = context.read<FinanzasProvider>();
    Navigator.pop(context);
    await p.eliminarDeuda(d);
  }

  Future<void> _registrarPago(BuildContext context, Deuda d) async {
    final p = context.read<FinanzasProvider>();
    final r = await showDialog<_ResultadoPago>(
      context: context,
      builder: (_) => _DialogoPago(deuda: d, pendiente: p.pendiente(d)),
    );
    if (r == null) return;
    await p.registrarPago(
      deuda: d,
      monto: r.monto,
      fecha: r.fecha,
      nota: r.nota,
      registrarMovimiento: r.registrarMovimiento,
    );
    if (context.mounted && p.pendiente(p.deudaPorId(d.id!) ?? d) <= 0) {
      mostrarMensaje(context, '¡Deuda saldada!');
    }
  }

  Future<void> _eliminarPago(BuildContext context, Pago pago, Deuda d) async {
    final ok = await confirmar(
      context,
      titulo: 'Eliminar ${d.tipo.nombrePago.toLowerCase()}',
      mensaje: pago.movimientoId != null
          ? 'También se eliminará el movimiento asociado en Ingresos/Egresos.'
          : '¿Eliminar este registro de ${moneda(pago.monto)}?',
    );
    if (!ok || !context.mounted) return;
    await context.read<FinanzasProvider>().eliminarPago(pago);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<FinanzasProvider>();
    final d = p.deudaPorId(deudaId);
    if (d == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const EstadoVacio(icono: Icons.search_off, texto: 'La deuda ya no existe.'),
      );
    }

    final pagos = p.pagosDe(deudaId);
    final pagado = p.pagado(deudaId);
    final pendiente = p.pendiente(d);
    final color = d.tipo == TipoDeuda.debo ? kColorEgreso : kColorIngreso;
    final tema = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(d.persona),
        actions: [
          IconButton(
            tooltip: 'Editar',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => DeudaFormScreen(deuda: d)),
            ),
          ),
          IconButton(
            tooltip: 'Eliminar',
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _eliminar(context, d),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Chip(
                        label: Text(d.tipo.etiqueta),
                        visualDensity: VisualDensity.compact,
                      ),
                      const Spacer(),
                      if (d.saldada)
                        const Chip(
                          avatar: Icon(Icons.check_circle, size: 18),
                          label: Text('Saldada'),
                          visualDensity: VisualDensity.compact,
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text('Pendiente', style: tema.textTheme.bodySmall),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      moneda(pendiente),
                      style: tema.textTheme.headlineMedium
                          ?.copyWith(color: color, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 16),
                  BarraProporcion(fraccion: p.progreso(d), color: color),
                  const SizedBox(height: 16),
                  _Dato('Monto total', moneda(d.monto)),
                  _Dato('${d.tipo.nombrePago}s realizados', moneda(pagado)),
                  _Dato('Fecha', fechaCorta(d.fecha)),
                  if (d.vencimiento != null)
                    _Dato('Vencimiento', fechaCorta(d.vencimiento!)),
                  if (d.descripcion.isNotEmpty) _Dato('Concepto', d.descripcion),
                ],
              ),
            ),
          ),
          TituloSeccion('Historial de ${d.tipo.nombrePago.toLowerCase()}s'),
          if (pagos.isEmpty)
            const EstadoVacio(
              icono: Icons.history,
              texto: 'Todavía no hay registros.',
            )
          else
            Card(
              child: Column(
                children: [
                  for (final pago in pagos)
                    ListTile(
                      leading: Icon(
                        d.tipo == TipoDeuda.debo ? Icons.call_made : Icons.call_received,
                        color: color,
                      ),
                      title: Text(moneda(pago.monto)),
                      subtitle: Text([
                        fechaCorta(pago.fecha),
                        if (pago.nota.isNotEmpty) pago.nota,
                      ].join(' · ')),
                      trailing: IconButton(
                        tooltip: 'Eliminar',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _eliminarPago(context, pago, d),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
      floatingActionButton: d.saldada
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _registrarPago(context, d),
              icon: const Icon(Icons.payments_outlined),
              label: Text(d.tipo.accionPago),
            ),
    );
  }
}

class _Dato extends StatelessWidget {
  final String etiqueta;
  final String valor;

  const _Dato(this.etiqueta, this.valor);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(etiqueta, style: Theme.of(context).textTheme.bodyMedium)),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              valor,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultadoPago {
  final double monto;
  final DateTime fecha;
  final String nota;
  final bool registrarMovimiento;

  const _ResultadoPago(this.monto, this.fecha, this.nota, this.registrarMovimiento);
}

class _DialogoPago extends StatefulWidget {
  final Deuda deuda;
  final double pendiente;

  const _DialogoPago({required this.deuda, required this.pendiente});

  @override
  State<_DialogoPago> createState() => _DialogoPagoState();
}

class _DialogoPagoState extends State<_DialogoPago> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _montoCtrl;
  final _notaCtrl = TextEditingController();
  DateTime _fecha = soloFecha(DateTime.now());
  bool _registrar = true;

  @override
  void initState() {
    super.initState();
    _montoCtrl = TextEditingController(text: montoParaCampo(widget.pendiente));
  }

  @override
  void dispose() {
    _montoCtrl.dispose();
    _notaCtrl.dispose();
    super.dispose();
  }

  void _aceptar() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      _ResultadoPago(
        parseMonto(_montoCtrl.text)!,
        _fecha,
        _notaCtrl.text.trim(),
        _registrar,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final esPago = widget.deuda.tipo == TipoDeuda.debo;
    return AlertDialog(
      title: Text(widget.deuda.tipo.accionPago),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _montoCtrl,
                autofocus: true,
                keyboardType: TextInputType.number,
                inputFormatters: [MilesInputFormatter()],
                decoration: InputDecoration(
                  labelText: 'Monto',
                  prefixText: '$kSimboloMoneda ',
                  helperText: 'Pendiente: ${moneda(widget.pendiente)}',
                ),
                validator: (v) {
                  final n = parseMonto(v ?? '');
                  if (n == null || n <= 0) return 'Ingresá un monto mayor a 0';
                  if (n > widget.pendiente) return 'Supera lo pendiente';
                  return null;
                },
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _notaCtrl,
                decoration: const InputDecoration(labelText: 'Nota (opcional)'),
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today_outlined),
                title: Text(fechaCorta(_fecha)),
                onTap: () async {
                  final f = await elegirFecha(context, _fecha);
                  if (f != null) setState(() => _fecha = f);
                },
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _registrar,
                onChanged: (v) => setState(() => _registrar = v ?? true),
                title: Text(esPago ? 'Registrar como egreso' : 'Registrar como ingreso'),
                subtitle: const Text('Afecta tu saldo disponible'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(onPressed: _aceptar, child: const Text('Guardar')),
      ],
    );
  }
}
