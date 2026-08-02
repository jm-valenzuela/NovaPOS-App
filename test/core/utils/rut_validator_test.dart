import 'package:flutter_test/flutter_test.dart';
import 'package:novapos_app/core/utils/rut_validator.dart';

void main() {
  group('RutValidator.esValido', () {
    test('acepta RUTs válidos conocidos, con y sin formato', () {
      expect(RutValidator.esValido('11111111-1'), isTrue);
      expect(RutValidator.esValido('12345678-5'), isTrue);
      expect(RutValidator.esValido('12.345.678-5'), isTrue);
      expect(RutValidator.esValido('76192083-9'), isTrue);
    });

    test('rechaza un dígito verificador incorrecto', () {
      expect(RutValidator.esValido('12345678-9'), isFalse);
    });

    test('rechaza entradas vacías o sin dígito verificador', () {
      expect(RutValidator.esValido(''), isFalse);
      expect(RutValidator.esValido('1'), isFalse);
    });

    test('rechaza un cuerpo no numérico', () {
      expect(RutValidator.esValido('ABCDEFGH-5'), isFalse);
    });

    test('acepta dígito verificador K', () {
      // Cualquier RUT cuyo módulo 11 dé resto 10 exige K como DV.
      expect(RutValidator.esValido('90345671-K'), isTrue);
    });
  });

  group('RutValidator.normalizarConGuion', () {
    test('quita los puntos y deja el guión', () {
      expect(RutValidator.normalizarConGuion('12.345.678-5'), '12345678-5');
    });

    test('deja igual un RUT ya sin puntos', () {
      expect(RutValidator.normalizarConGuion('12345678-5'), '12345678-5');
    });
  });

  group('RutValidator.formatear', () {
    test('agrega puntos de miles y guión', () {
      expect(RutValidator.formatear('123456785'), '12.345.678-5');
    });

    test('funciona con un cuerpo de 7 dígitos', () {
      // Últimos 8 caracteres: cuerpo="1111111" (7 dígitos) + dv="1".
      expect(RutValidator.formatear('11111111'), '1.111.111-1');
    });
  });
}
