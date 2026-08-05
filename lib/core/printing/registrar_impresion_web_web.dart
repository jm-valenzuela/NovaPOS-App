// ignore: implementation_imports
import 'package:printing/src/interface.dart';
import 'package:printing/printing_web.dart';

/// El auto-registro del plugin web de `printing` (vía el plugin registrant
/// que genera `flutter build/run web`) no está tomando efecto en este
/// entorno — `PrintingPlatform.instance` se queda en el `MethodChannelPrinting`
/// por defecto, que depende de canales de plataforma nativos inexistentes
/// en un navegador y falla con "Unsupported operation: Platform._operatingSystem"
/// antes de siquiera llamar al callback de generación del PDF. Se fuerza acá
/// el mismo efecto que `PrintingPlugin.registerWith(registrar)` hace
/// internamente (ver código fuente del paquete): asignar la instancia web.
void registrarImpresionWeb() {
  PrintingPlatform.instance = PrintingPlugin();
}
