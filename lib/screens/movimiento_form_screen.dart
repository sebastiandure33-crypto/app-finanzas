import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/movimiento.dart';
import '../providers/finanzas_provider.dart';
import '../utils/categorias.dart';
import '../utils/dialogos.dart';
import '../utils/formato.dart';

class MovimientoFormScreen extends StatefulWidget {
  final Movimiento? movimiento;
  final TipoMovimiento tipoInicial;

  const MovimientoFormScreen({
    super.key,
    this.movimiento,
    this.tipoInicial = TipoMovimiento.egreso,
  });

  @override
  State<MovimientoFormScreen> createState() => _MovimientoFormScreenState();
}

class _MovimientoFormScreenState extends State<MovimientoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TipoMovimiento _tipo;
  late final TextEditingController _montoCtrl;
  late final TextEditingController _descCtrl;
  String? _categoria;
  late DateTime _fecha;
  bool _guardando = false;

  bool get _editando => widget.movimiento != null;

  @override
  void initState() {
    super.initState();
    final m = widget.movimiento;
    _tipo = m?.tipo ?? widget.tipoInicial;
    _montoCtrl = TextEditingController(text: m == null ? '' : montoParaCampo(m.monto));
    _descCtrl = TextEditingController(text: m?.descripcion ?? '');
    _categoria = m?.categoria;
    _fecha = m?.fecha ?? soloFecha(DateTime.now());
  }

  @override
  void dispose() {
    _montoCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_categoria == null) {
      mostrarMensaje(context, 'Elegí una categoría');
      return;
    }
    setState(() => _guardando = true);
    final p = context.read<FinanzasProvider>();
    final datos = Movimiento(
      id: widget.movimiento?.id,
      tipo: _tipo,
      monto: parseMonto(_montoCtrl.text)!,
      categoria: _categoria!,
      descripcion: _descCtrl.text.trim(),
      fecha: _fecha,
    );
    if (_editando) {
      await p.actualizarMovimiento(datos);
    } else {
      await p.agregarMovimiento(datos);
    }
    if (mounted) Navigator.pop(context);
  }

  Future<void> _eliminar() async {
    final ok = await confirmar(
      context,
      titulo: 'Eliminar movimiento',
      mensaje: 'Esta acción no se puede deshacer.',
    );
    if (!ok || !mounted) return;
    await context.read<FinanzasProvider>().eliminarMovimiento(widget.movimiento!);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final categorias = categoriasDe(_tipo);
    final color = colorTipo(_tipo);

    return Scaffold(
      appBar: AppBar(
        title: Text(_editando ? 'Editar movimiento' : 'Nuevo movimiento'),
        actions: [
          if (_editando)
            IconButton(
              tooltip: 'Eliminar',
              icon: const Icon(Icons.delete_outline),
              onPressed: _eliminar,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SegmentedButton<TipoMovimiento>(
              segments: const [
                ButtonSegment(
                  value: TipoMovimiento.ingreso,
                  label: Text('Ingreso'),
                  icon: Icon(Icons.south_west),
                ),
                ButtonSegment(
                  value: TipoMovimiento.egreso,
                  label: Text('Egreso'),
                  icon: Icon(Icons.north_east),
                ),
              ],
              selected: {_tipo},
              onSelectionChanged: (s) => setState(() {
                _tipo = s.first;
                if (!categoriasDe(_tipo).contains(_categoria)) _categoria = null;
              }),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _montoCtrl,
              autofocus: !_editando,
              keyboardType: TextInputType.number,
              inputFormatters: [MilesInputFormatter()],
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: color),
              decoration: const InputDecoration(
                labelText: 'Monto',
                prefixText: '$kSimboloMoneda ',
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                final n = parseMonto(v ?? '');
                if (n == null || n <= 0) return 'Ingresá un monto mayor a 0';
                return null;
              },
            ),
            const SizedBox(height: 20),
            Text('Categoría', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final c in categorias)
                  ChoiceChip(
                    label: Text(c),
                    avatar: _categoria == c ? null : Icon(iconoCategoria(c), size: 18),
                    selected: _categoria == c,
                    onSelected: (_) => setState(() => _categoria = c),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _descCtrl,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Descripción (opcional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today_outlined),
              title: const Text('Fecha'),
              subtitle: Text(fechaCorta(_fecha)),
              onTap: () async {
                final f = await elegirFecha(context, _fecha);
                if (f != null) setState(() => _fecha = f);
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
