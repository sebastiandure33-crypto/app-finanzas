import 'package:flutter_test/flutter_test.dart';

import 'package:finanzas_app/utils/formato.dart';

void main() {
  test('formatea montos en guaraníes', () {
    expect(moneda(0), 'Gs. 0');
    expect(moneda(1500), 'Gs. 1.500');
    expect(moneda(1500000), 'Gs. 1.500.000');
    expect(moneda(-25000), '-Gs. 25.000');
  });

  test('interpreta montos escritos', () {
    expect(parseMonto('1.500.000'), 1500000);
    expect(parseMonto(''), isNull);
  });
}
