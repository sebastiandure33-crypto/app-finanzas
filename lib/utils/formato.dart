import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Moneda usada en toda la app. Cambiar aquí si se necesita otra.
const String kSimboloMoneda = 'Gs.';

/// Agrupa una cadena de dígitos con puntos de miles: 1500000 -> 1.500.000
String agruparMiles(String digitos) {
  final buf = StringBuffer();
  for (var i = 0; i < digitos.length; i++) {
    if (i > 0 && (digitos.length - i) % 3 == 0) buf.write('.');
    buf.write(digitos[i]);
  }
  return buf.toString();
}

/// Formatea un monto: -1500000 -> -Gs. 1.500.000
String moneda(double valor) {
  final signo = valor < 0 ? '-' : '';
  final digitos = valor.abs().round().toString();
  return '$signo$kSimboloMoneda ${agruparMiles(digitos)}';
}

/// Convierte el texto del campo de monto en número.
double? parseMonto(String texto) {
  final limpio = texto.replaceAll('.', '').replaceAll(' ', '').trim();
  if (limpio.isEmpty) return null;
  return double.tryParse(limpio);
}

/// Texto inicial para un campo de monto.
String montoParaCampo(double valor) => agruparMiles(valor.round().toString());

/// Formatea mientras se escribe: solo dígitos, con puntos de miles.
class MilesInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    var digitos = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    digitos = digitos.replaceFirst(RegExp(r'^0+(?=\d)'), '');
    final texto = agruparMiles(digitos);
    return TextEditingValue(
      text: texto,
      selection: TextSelection.collapsed(offset: texto.length),
    );
  }
}

String fechaIso(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

DateTime soloFecha(DateTime d) => DateTime(d.year, d.month, d.day);

String fechaCorta(DateTime d) => DateFormat('dd/MM/yyyy').format(d);

String capitalizar(String s) =>
    s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

String nombreMes(DateTime d) => capitalizar(DateFormat('MMMM yyyy', 'es').format(d));

String mesCorto(DateTime d) => capitalizar(DateFormat('MMM', 'es').format(d));

String fechaLarga(DateTime d) =>
    capitalizar(DateFormat("EEEE d 'de' MMMM", 'es').format(d));

bool mismoMes(DateTime a, DateTime b) => a.year == b.year && a.month == b.month;
