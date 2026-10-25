# Mis Finanzas (Flutter)

Control personal de ingresos, egresos y deudas. Datos guardados en el teléfono (SQLite).

## Funciones
- **Resumen:** saldo disponible, ingresos/egresos del mes, deudas pendientes, vencimientos próximos (7 días) y últimos movimientos.
- **Movimientos:** alta, edición y borrado (deslizar a la izquierda) de ingresos y egresos por categoría, filtrados por mes.
- **Deudas:** "Debo" y "Me deben", con monto, vencimiento, pagos/cobros parciales, barra de progreso y marcado automático como saldada. Cada pago puede registrarse también como egreso/ingreso.
- **Reportes:** balance mensual, gastos e ingresos por categoría y comparación de los últimos 6 meses.

## Cómo ejecutarla
1. Instalar Flutter: https://docs.flutter.dev/get-started/install
2. Crear el proyecto base (genera las carpetas de Android/iOS):
   ```
   flutter create --org com.tunombre --platforms android,ios finanzas_app
   ```
3. Reemplazar en ese proyecto la carpeta `lib/`, la carpeta `test/` y el archivo `pubspec.yaml` por los de este paquete.
4. Dentro de la carpeta del proyecto:
   ```
   flutter pub get
   flutter run
   ```

Ícono y pantalla de inicio (una sola vez, y cada vez que cambies el logo):
```
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

Nombre visible de la app en Android: editar `android:label` en `android/app/src/main/AndroidManifest.xml` (por ejemplo, `Mis Finanzas`).

## Moneda
Definida en `lib/utils/formato.dart` (`kSimboloMoneda = 'Gs.'`, montos sin decimales).

## Estructura
```
lib/
  main.dart                     Tema, idioma español y arranque
  db/database_helper.dart       SQLite: tablas movimientos, deudas, pagos
  models/                       Movimiento, Deuda, Pago
  providers/finanzas_provider.dart  Estado y cálculos (saldo, totales, pendientes)
  screens/                      Resumen, Movimientos, Deudas, Detalle, Formularios, Reportes
  utils/                        Formato de montos/fechas, categorías, diálogos
  widgets/comunes.dart          Componentes reutilizables
```

## Publicar en Play Store (cuando esté lista)
```
flutter build appbundle --release
```
Antes hay que configurar la firma de la app: https://docs.flutter.dev/deployment/android
