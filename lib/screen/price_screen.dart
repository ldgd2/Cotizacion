import 'package:flutter/material.dart';
import '../widgets/panel_widget.dart';
import '../widgets/cotizacion_widget.dart';

class PriceScreen extends StatelessWidget {
  final Map<String, dynamic> arguments;

  const PriceScreen({super.key, required this.arguments});

  @override
  Widget build(BuildContext context) {
    final cotizacion = _sanitizeCotizacion(arguments);

    return Scaffold(
      appBar: AppBar(title: const Text("Cotización")),
      drawer: PanelWidget(
        onItemSelected: (route) => Navigator.pushNamed(context, route),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: CotizacionWidget(cotizacion: cotizacion),
      ),
    );
  }

  Map<String, dynamic> _sanitizeCotizacion(Map<String, dynamic> c) {
    return {
      "empresa": c["empresa"] ?? "Seleccionar Empresa",
      "direccion": c["direccion"] ?? "",
      "telefono": c["telefono"] ?? "",
      "correo": c["correo"] ?? "",
      "logo": c["logo"],
      "nombre_proyecto": c["nombre_proyecto"] ?? "",
      "nombre_cliente": c["nombre_cliente"] ?? "",
      "moneda": c["moneda"] ?? "BOB (Bs)",
      "fecha": c["fecha"] ?? DateTime.now().toIso8601String().split("T").first,
      "firma": c["firma"] ?? "",
      "imagenes": List<String>.from(c["imagenes"] ?? []),
      "productos": List<Map<String, dynamic>>.from(c["productos"] ?? []),
    };
  }
}
