import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/finanzas_provider.dart';
import '../widgets/logo.dart';
import 'home_screen.dart';

/// Pantalla inicial: el logo se arma por partes y luego entra la app.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2000),
  );

  Animation<double> _tramo(double desde, double hasta,
          [Curve curva = Curves.easeOutCubic]) =>
      CurvedAnimation(parent: _c, curve: Interval(desde, hasta, curve: curva));

  late final _entrada = _tramo(0.00, 0.20);
  late final _barra1 = _tramo(0.08, 0.34, Curves.easeOutBack);
  late final _barra2 = _tramo(0.16, 0.42, Curves.easeOutBack);
  late final _barra3 = _tramo(0.24, 0.50, Curves.easeOutBack);
  late final _linea = _tramo(0.44, 0.72, Curves.easeInOutCubic);
  late final _punta = _tramo(0.68, 0.84, Curves.easeOutBack);
  late final _texto = _tramo(0.74, 1.00);

  @override
  void initState() {
    super.initState();
    _c.forward().then((_) => _continuar());
  }

  Future<void> _continuar() async {
    await Future.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;
    final p = context.read<FinanzasProvider>();
    while (p.cargando) {
      await Future.delayed(const Duration(milliseconds: 100));
      if (!mounted) return;
    }
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 450),
        pageBuilder: (_, __, ___) => const HomeScreen(),
        transitionsBuilder: (_, animacion, __, hijo) =>
            FadeTransition(opacity: animacion, child: hijo),
      ),
    );
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: LogoColores.fondo,
        body: Center(
          child: AnimatedBuilder(
            animation: _c,
            builder: (context, _) {
              final t = _texto.value;
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Opacity(
                    opacity: _entrada.value,
                    child: Transform.scale(
                      scale: 0.9 + 0.1 * _entrada.value,
                      child: SizedBox(
                        width: 150,
                        height: 150,
                        child: CustomPaint(
                          painter: LogoPainter(
                            fondo: 0,
                            barras: [_barra1.value, _barra2.value, _barra3.value],
                            linea: _linea.value,
                            punta: _punta.value,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Opacity(
                    opacity: t,
                    child: Transform.translate(
                      offset: Offset(0, 14 * (1 - t)),
                      child: const Column(
                        children: [
                          Text(
                            'Mis Finanzas',
                            style: TextStyle(
                              color: LogoColores.blanco,
                              fontSize: 30,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'CONTROL  ·  ORGANIZACIÓN  ·  TUS FINANZAS',
                            style: TextStyle(
                              color: LogoColores.gris,
                              fontSize: 11,
                              letterSpacing: 2.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
