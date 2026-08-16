import 'package:flutter_test/flutter_test.dart';
import 'package:novapos_app/core/utils/pdf_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('tema() carga las fuentes embebidas sin lanzar (assets declarados correctamente)', () async {
    final tema = await PdfFonts.tema();

    expect(tema, isNotNull);
  });
}
