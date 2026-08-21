/// Un Anticipo de Orden de Trabajo que se puede elegir como medio de pago
/// (MedioPago.anticipo) al cobrar la Venta que la entrega — ver
/// CheckoutDialog._selectorAnticipo. Sales no conoce el modelo completo de
/// WorkOrders (AnticipoOrdenTrabajoDetalle); CobrarOrdenTrabajoDialog mapea
/// a esta forma mínima antes de pasarla a CheckoutDialog, mismo criterio
/// que evita que Sales importe tipos de otro feature.
class AnticipoDisponibleParaPago {
  const AnticipoDisponibleParaPago({required this.id, required this.monto, required this.etiquetaMedioPagoOriginal});

  final String id;
  final double monto;

  /// Ej. "Efectivo" — cómo se recibió este Anticipo en su momento, para mostrarlo junto al monto en el selector.
  final String etiquetaMedioPagoOriginal;
}
