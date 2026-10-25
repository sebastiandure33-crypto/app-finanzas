import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';

/// Colores de la marca.
class LogoColores {
  static const fondo = Color(0xFF111111);
  static const rojo = Color(0xFFE5252A);
  static const blanco = Color(0xFFF5F5F5);
  static const gris = Color(0xFF8A8A8A);
}

/// Dibuja el logo (barras de progreso + flecha ascendente) en una caja de 100x100.
/// Cada parte acepta un progreso de 0 a 1 para poder animarla.
class LogoPainter extends CustomPainter {
  /// Opacidad del fondo redondeado (0 = sin fondo).
  final double fondo;

  /// Altura de cada una de las 3 barras (0..1, admite un poco de rebote).
  final List<double> barras;

  /// Porción dibujada de la línea de la flecha (0..1).
  final double linea;

  /// Escala de la punta de la flecha (0..1, admite rebote).
  final double punta;

  const LogoPainter({
    this.fondo = 1,
    this.barras = const [1, 1, 1],
    this.linea = 1,
    this.punta = 1,
  });

  static const _base = 76.0;
  static const _ancho = 12.0;
  static const _xs = [26.0, 44.0, 62.0];
  static const _altos = [14.0, 24.0, 34.0];

  /// Flecha recta, paralela a la pendiente de las barras.
  static const _puntos = [
    Offset(24, 47),
    Offset(70, 22),
  ];

  /// Centro óptico del dibujo y escala para dejar margen en máscaras circulares.
  static const _centro = Offset(49.6, 45.8);
  static const _escalaContenido = 0.88;

  @override
  void paint(Canvas canvas, Size size) {
    final escala = size.shortestSide / 100;
    canvas.save();
    canvas.translate(
      (size.width - 100 * escala) / 2,
      (size.height - 100 * escala) / 2,
    );
    canvas.scale(escala);

    // Fondo
    if (fondo > 0) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(0, 0, 100, 100),
          const Radius.circular(22),
        ),
        Paint()..color = LogoColores.fondo.withAlpha((255 * fondo.clamp(0.0, 1.0)).round()),
      );
    }

    // Contenido centrado y reducido (entra en íconos circulares sin recortarse)
    canvas.save();
    canvas.translate(50, 50);
    canvas.scale(_escalaContenido);
    canvas.translate(-_centro.dx, -_centro.dy);

    // Barras
    final pintaBarra = Paint()..color = LogoColores.blanco;
    for (var i = 0; i < 3; i++) {
      final alto = _altos[i] * barras[i].clamp(0.0, 1.2);
      if (alto <= 0.1) continue;
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(_xs[i], _base - alto, _ancho, alto),
          topLeft: const Radius.circular(2.5),
          topRight: const Radius.circular(2.5),
        ),
        pintaBarra,
      );
    }

    // Línea de la flecha
    final pintaRojo = Paint()
      ..color = LogoColores.rojo
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final camino = Path()..moveTo(_puntos.first.dx, _puntos.first.dy);
    for (final p in _puntos.skip(1)) {
      camino.lineTo(p.dx, p.dy);
    }

    final avance = linea.clamp(0.0, 1.0);
    if (avance >= 1) {
      canvas.drawPath(camino, pintaRojo);
    } else if (avance > 0) {
      final parcial = Path();
      for (final PathMetric m in camino.computeMetrics()) {
        parcial.addPath(m.extractPath(0, m.length * avance), Offset.zero);
      }
      canvas.drawPath(parcial, pintaRojo);
    }

    // Punta de la flecha
    final p = punta.clamp(0.0, 1.3);
    if (p > 0) {
      final fin = _puntos.last;
      final dir = fin - _puntos[_puntos.length - 2];
      final d = dir / dir.distance;
      final perp = Offset(-d.dy, d.dx);
      final triangulo = Path()
        ..moveTo(fin.dx + d.dx * 12, fin.dy + d.dy * 12)
        ..lineTo(fin.dx + perp.dx * 9.5 - d.dx * 1.5, fin.dy + perp.dy * 9.5 - d.dy * 1.5)
        ..lineTo(fin.dx - perp.dx * 9.5 - d.dx * 1.5, fin.dy - perp.dy * 9.5 - d.dy * 1.5)
        ..close();
      canvas.save();
      canvas.translate(fin.dx, fin.dy);
      canvas.scale(p);
      canvas.translate(-fin.dx, -fin.dy);
      canvas.drawPath(
        triangulo,
        Paint()
          ..color = LogoColores.rojo
          ..style = PaintingStyle.fill
          ..strokeJoin = StrokeJoin.round,
      );
      canvas.restore();
    }

    canvas.restore(); // contenido
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant LogoPainter old) =>
      old.fondo != fondo ||
      old.linea != linea ||
      old.punta != punta ||
      old.barras[0] != barras[0] ||
      old.barras[1] != barras[1] ||
      old.barras[2] != barras[2];
}

/// Logo estático.
class LogoApp extends StatelessWidget {
  final double tamano;
  final bool conFondo;

  const LogoApp({super.key, this.tamano = 48, this.conFondo = true});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: tamano,
      height: tamano,
      child: CustomPaint(painter: LogoPainter(fondo: conFondo ? 1 : 0)),
    );
  }
}
