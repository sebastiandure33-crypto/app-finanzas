import 'package:flutter/material.dart';

import '../models/movimiento.dart';
import '../utils/categorias.dart';
import '../utils/formato.dart';

/// Selector de mes con flechas.
class SelectorMes extends StatelessWidget {
  final DateTime mes;
  final ValueChanged<DateTime> onChanged;

  const SelectorMes({super.key, required this.mes, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final hoy = DateTime.now();
    final esActual = mismoMes(mes, hoy);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          tooltip: 'Mes anterior',
          icon: const Icon(Icons.chevron_left),
          onPressed: () => onChanged(DateTime(mes.year, mes.month - 1)),
        ),
        GestureDetector(
          onTap: esActual ? null : () => onChanged(DateTime(hoy.year, hoy.month)),
          child: SizedBox(
            width: 170,
            child: Text(
              nombreMes(mes),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ),
        IconButton(
          tooltip: 'Mes siguiente',
          icon: const Icon(Icons.chevron_right),
          onPressed: () => onChanged(DateTime(mes.year, mes.month + 1)),
        ),
      ],
    );
  }
}

/// Fila de un movimiento en una lista.
class MovimientoTile extends StatelessWidget {
  final Movimiento movimiento;
  final VoidCallback? onTap;
  final bool mostrarFecha;

  const MovimientoTile({
    super.key,
    required this.movimiento,
    this.onTap,
    this.mostrarFecha = true,
  });

  @override
  Widget build(BuildContext context) {
    final m = movimiento;
    final color = colorTipo(m.tipo);
    final subtitulo = [
      if (m.descripcion.isNotEmpty) m.descripcion,
      if (mostrarFecha) fechaCorta(m.fecha),
    ].join(' · ');
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Icon(iconoCategoria(m.categoria), color: color, size: 20),
      ),
      title: Text(m.categoria),
      subtitle: subtitulo.isEmpty
          ? null
          : Text(subtitulo, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: Text(
        '${m.esIngreso ? '+' : '-'} ${moneda(m.monto)}',
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// Mensaje para listas vacías.
class EstadoVacio extends StatelessWidget {
  final IconData icono;
  final String texto;

  const EstadoVacio({super.key, required this.icono, required this.texto});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.outline;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icono, size: 56, color: color),
            const SizedBox(height: 12),
            Text(texto, textAlign: TextAlign.center, style: TextStyle(color: color)),
          ],
        ),
      ),
    );
  }
}

/// Título de sección.
class TituloSeccion extends StatelessWidget {
  final String texto;
  final Widget? accion;

  const TituloSeccion(this.texto, {super.key, this.accion});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(texto, style: Theme.of(context).textTheme.titleMedium),
          ),
          if (accion != null) accion!,
        ],
      ),
    );
  }
}

/// Barra horizontal proporcional.
class BarraProporcion extends StatelessWidget {
  final double fraccion;
  final Color color;
  final double alto;

  const BarraProporcion({
    super.key,
    required this.fraccion,
    required this.color,
    this.alto = 10,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(alto / 2),
      child: Container(
        height: alto,
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: fraccion.isNaN ? 0.0 : fraccion.clamp(0.0, 1.0),
          child: Container(color: color),
        ),
      ),
    );
  }
}
