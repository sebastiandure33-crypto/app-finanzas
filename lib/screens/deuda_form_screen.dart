import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/deuda.dart';
import '../providers/finanzas_provider.dart';
import '../utils/dialogos.dart';
import '../utils/formato.dart';

class DeudaFormScreen extends StatefulWidget {
  final Deuda? deuda;
  final TipoDeuda tipoInicial;

  const DeudaFormScreen({super.key, this.deuda, this.tipoInicial = TipoDeuda.debo});

  @override
  State<DeudaFormScreen> createState() => _DeudaFormScreenState();
}

class _DeudaFormScreenState extends State<DeudaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TipoDeuda _tipo;
  late final TextEditingController _personaCtrl;
  late final TextEditingController _montoCtrl;
  late final TextEditingController _descCtrl;
  late DateTime _fecha;
  DateTime? _vencimiento;
  bool _guardando = false;

  bool get _editando => widget.deuda != null;

  @override
  void initState() {
    super.initState();
    final d = widget.deuda;
    _tipo = d?.tipo ?? widget.tipoInicial;
    _personaCtrl = TextEditingController(text: d?.persona ?? '');
    _montoCtrl = TextEditingController(text: d == null ? '' : montoParaCampo(d.monto));
    _descCtrl = TextEditingController(text: d?.descripcion ?? '');
    _fecha = d?.fecha ?? soloFecha(DateTime.now());
    _vencimiento = d?.vencimiento;
  }

  @override
  void dispose() {
    _personaCtrl.dispose();
    _montoCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);
    final p = context.read<FinanzasProvider>();
    final datos = Deuda(
      id: widget.deuda?.id,
      tipo: _tipo,
      persona: _personaCtrl.text.trim(),
      descripcion: _descCtrl.text.trim(),
      monto: parseMonto(_montoCtrl.text)!,
      fecha: _fecha,
      vencimiento: _vencimiento,
      saldada: widget.deuda?.saldada ?? false,
    );
    if (_editando) {
      await p.actualizarDeuda(datos);
    } else {
      await p.agregarDeuda(datos);
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.read<FinanzasProvider>();
    final yaPagado = _editando ? p.pagado(widget.deuda!.id!) : 0.0;

    return Scaffold(
      appBar: AppBar(title: Text(_editando ? 'Editar deuda' : 'Nueva deuda')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SegmentedButton<TipoDeuda>(
              segments: const [
                ButtonSegment(
                  value: TipoDeuda.debo,
                  label: Text('Yo debo'),
                  icon: Icon(Icons.call_made),
                ),
                ButtonSegment(
                  value: TipoDeuda.meDeben,
                  label: Text('Me deben'),
                  icon: Icon(Icons.call_received),
                ),
              ],
              selected: {_tipo},
              onSelectionChanged: _editando
                  ? null
                  : (s) => setState(() => _tipo = s.first),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _personaCtrl,
              autofocus: !_editando,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: _tipo == TipoDeuda.debo
                    ? '¿A quién le debés?'
                    : '¿Quién te debe?',
                hintText: 'Persona, banco o comercio',
                prefixIcon: const Icon(Icons.person_outline),
                border: const OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Este campo es obligatorio' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _montoCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [MilesInputFormatter()],
              decoration: const InputDecoration(
                labelText: 'Monto total',
                prefixText: '$kSimboloMoneda ',
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                final n = parseMonto(v ?? '');
                if (n == null || n <= 0) return 'Ingresá un monto mayor a 0';
                if (n < yaPagado) {
                  return 'No puede ser menor a lo ya pagado (${moneda(yaPagado)})';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descCtrl,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Concepto (opcional)',
                hintText: 'Ej.: préstamo, cuota del celular',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today_outlined),
              title: const Text('Fecha de la deuda'),
              subtitle: Text(fechaCorta(_fecha)),
              onTap: () async {
                final f = await elegirFecha(context, _fecha);
                if (f != null) setState(() => _fecha = f);
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event_outlined),
              title: const Text('Vencimiento (opcional)'),
              subtitle: Text(_vencimiento == null ? 'Sin vencimiento' : fechaCorta(_vencimiento!)),
              trailing: _vencimiento == null
                  ? null
                  : IconButton(
                      tooltip: 'Quitar vencimiento',
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(() => _vencimiento = null),
                    ),
              onTap: () async {
                final f = await elegirFecha(
                  context,
                  _vencimiento ?? _fecha.add(const Duration(days: 30)),
                );
                if (f != null) setState(() => _vencimiento = f);
              },
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _guardando ? null : _guardar,
              icon: const Icon(Icons.check),
              label: const Text('Guardar'),
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            ),
          ],
        ),
      ),
    );
  }
}
