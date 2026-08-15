import 'package:flutter/material.dart';

import '../../../../core/utils/moneda_formatter.dart';
import '../../domain/models/resumen_cierre_caja.dart';

/// Tarjeta con el arqueo de una Sesión de Caja (Monto inicial, Ventas en
/// efectivo, Retiros, Monto esperado, y Monto contado/Diferencia si ya
/// Cerró) — extraída de CierreCajaScreen para reutilizarla también en
/// ArqueoCajaDialog (consulta rápida sin pasar por el flujo de cierre).
class TarjetaResumenCaja extends StatelessWidget {
  const TarjetaResumenCaja({super.key, required this.resumen});

  final ResumenCierreCaja resumen;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(resumen.cerrada ? 'Sesión Cerrada' : 'Sesión Abierta', style: const TextStyle(fontWeight: FontWeight.w600)),
                if (resumen.cerrada)
                  const Icon(Icons.lock_outline, size: 18)
                else
                  const Icon(Icons.lock_open_outlined, size: 18),
              ],
            ),
            const Divider(height: 20),
            _filaMonto('Monto inicial', resumen.montoInicial),
            _filaMonto('Ventas en efectivo', resumen.totalVentasEfectivo),
            _filaMonto('Retiros autorizados', -resumen.totalRetiros),
            if (resumen.totalDevolucionesEfectivo > 0)
              _filaMonto('Devoluciones reembolsadas', -resumen.totalDevolucionesEfectivo),
            const Divider(height: 20),
            _filaMonto('Monto esperado', resumen.montoEsperado, destacado: true),
            if (resumen.montoContado != null) _filaMonto('Monto contado', resumen.montoContado!, destacado: true),
            if (resumen.diferencia != null)
              _filaMonto('Diferencia', resumen.diferencia!,
                  destacado: true, color: resumen.diferencia == 0 ? Colors.green : Colors.red),
            if (resumen.totalVentasTarjetaDebito > 0 ||
                resumen.totalVentasTarjetaCredito > 0 ||
                resumen.totalVentasCredito > 0 ||
                resumen.totalVentasNotaCredito > 0) ...[
              const Divider(height: 20),
              Text('Otros medios de pago (no suman al efectivo)', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              const SizedBox(height: 4),
              if (resumen.totalVentasTarjetaDebito > 0) _filaMonto('Ventas con Tarjeta Débito', resumen.totalVentasTarjetaDebito),
              if (resumen.totalVentasTarjetaCredito > 0) _filaMonto('Ventas con Tarjeta Crédito', resumen.totalVentasTarjetaCredito),
              if (resumen.totalVentasCredito > 0) _filaMonto('Ventas a Crédito (Cuentas por Cobrar)', resumen.totalVentasCredito),
              if (resumen.totalVentasNotaCredito > 0) _filaMonto('Ventas con Nota de Crédito', resumen.totalVentasNotaCredito),
            ],
          ],
        ),
      ),
    );
  }

  Widget _filaMonto(String etiqueta, double monto, {bool destacado = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(etiqueta, style: TextStyle(fontWeight: destacado ? FontWeight.w600 : FontWeight.normal)),
          Text(
            MonedaFormatter.formatear(monto),
            style: TextStyle(fontWeight: destacado ? FontWeight.w700 : FontWeight.normal, color: color),
          ),
        ],
      ),
    );
  }
}

/// Fila de un movimiento (Venta en efectivo o Retiro) — mismo criterio de
/// reuso que TarjetaResumenCaja.
class TarjetaMovimientoCaja extends StatelessWidget {
  const TarjetaMovimientoCaja({super.key, required this.movimiento});

  final MovimientoCaja movimiento;

  (IconData, Color) get _iconoYColor => switch (movimiento.tipo) {
        TipoMovimientoCaja.retiro => (Icons.arrow_upward, Colors.red),
        TipoMovimientoCaja.devolucionEfectivo => (Icons.arrow_upward, Colors.red),
        TipoMovimientoCaja.ventaEfectivo => (Icons.arrow_downward, Colors.green),
        TipoMovimientoCaja.ventaTarjetaDebito || TipoMovimientoCaja.ventaTarjetaCredito => (Icons.credit_card, Colors.blueGrey),
        TipoMovimientoCaja.ventaCredito => (Icons.schedule, Colors.blueGrey),
        TipoMovimientoCaja.ventaNotaCredito => (Icons.receipt_long, Colors.blueGrey),
      };

  @override
  Widget build(BuildContext context) {
    final resta = movimiento.tipo.restaElEfectivo;
    final (icono, color) = _iconoYColor;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icono, color: color),
        title: Text(movimiento.tipo.etiqueta),
        subtitle: Text(
          '${movimiento.detalle ?? ''}${movimiento.detalle != null ? ' · ' : ''}'
          '${movimiento.fecha.toLocal().toString().split('.').first}',
        ),
        trailing: Text(
          '${resta ? '-' : '+'}${MonedaFormatter.formatear(movimiento.monto)}',
          style: TextStyle(fontWeight: FontWeight.w600, color: color),
        ),
      ),
    );
  }
}
