import 'package:flutter/material.dart';

/// Paleta de las tarjetas de menú (Home, hubs de sección) — fondo navy,
/// etiqueta de categoría en naranja, título blanco, subtítulo gris
/// azulado. Compartida para que todos los menús de la app (Home,
/// ComprasHubScreen, etc.) usen exactamente el mismo look.
class MenuCardColores {
  MenuCardColores._();

  static const fondoPagina = Color(0xFFF2ECE0);
  static const tarjeta = Color(0xFF14233A);
  static const acento = Color(0xFFE58A3D);
  static const subtitulo = Color(0xFFAAB8CB);
}

/// Tarjeta oscura con etiqueta de categoría — cada una es autocontenida
/// (no depende de un encabezado de sección compartido), así que se
/// acomodan en un `Wrap` que fluye a 1 columna en pantallas angostas tipo
/// celular y hasta 3-4 en pantallas anchas tipo desktop/web. Usada en
/// Home y en los hubs de sección (Compras, Inventario, etc.).
class MenuCard extends StatelessWidget {
  const MenuCard({
    super.key,
    required this.categoria,
    required this.titulo,
    required this.subtitulo,
    required this.onTap,
    this.badge,
    this.badgeKey,
  });

  final String categoria;
  final String titulo;
  final String subtitulo;
  final VoidCallback onTap;
  final int? badge;
  final Key? badgeKey;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      child: Card(
        color: MenuCardColores.tarjeta,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        categoria.toUpperCase(),
                        style: const TextStyle(
                          color: MenuCardColores.acento,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    if (badge != null)
                      Container(
                        key: badgeKey,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: MenuCardColores.acento,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$badge',
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  titulo,
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700, height: 1.2),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitulo,
                  style: const TextStyle(color: MenuCardColores.subtitulo, fontSize: 14, height: 1.35),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Contenedor estándar para una pantalla de menú tipo grilla — fondo
/// crema, tarjetas centradas arriba (no en el medio de la pantalla) y
/// anchas hasta 1200px en desktop/web.
class MenuScaffold extends StatelessWidget {
  const MenuScaffold({super.key, required this.appBar, required this.tarjetas});

  final PreferredSizeWidget appBar;
  final List<Widget> tarjetas;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MenuCardColores.fondoPagina,
      appBar: appBar,
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Wrap(spacing: 16, runSpacing: 16, children: tarjetas),
          ),
        ),
      ),
    );
  }
}
