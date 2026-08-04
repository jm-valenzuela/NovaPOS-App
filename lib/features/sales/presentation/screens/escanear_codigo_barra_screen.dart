import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Escanea un código de barras con la cámara y lo devuelve vía
/// Navigator.pop — no conoce nada de Catalog/Sales, solo decodifica (ver
/// PosScreen._escanear, que hace la búsqueda y el agregado al carrito).
class EscanearCodigoBarraScreen extends StatefulWidget {
  const EscanearCodigoBarraScreen({super.key});

  @override
  State<EscanearCodigoBarraScreen> createState() => _EscanearCodigoBarraScreenState();
}

class _EscanearCodigoBarraScreenState extends State<EscanearCodigoBarraScreen> {
  final _controller = MobileScannerController();

  // Evita popear dos veces si el mismo frame dispara onDetect otra vez
  // antes de que la pantalla alcance a cerrarse.
  bool _yaDetectado = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_yaDetectado || capture.barcodes.isEmpty) return;
    final codigo = capture.barcodes.first.rawValue;
    if (codigo == null || codigo.isEmpty) return;

    _yaDetectado = true;
    Navigator.of(context).pop(codigo);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escanear código de barras'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            tooltip: 'Linterna',
            onPressed: () => _controller.toggleTorch(),
          ),
        ],
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),
          Container(
            width: 260,
            height: 140,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 2),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ],
      ),
    );
  }
}
