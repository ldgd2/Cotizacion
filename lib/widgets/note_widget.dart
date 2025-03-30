import 'dart:io';
import 'package:cotizacion/core/note_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/fileManager_core.dart';

class NoteWidget extends StatefulWidget {
  final Map<String, dynamic> cotizacion;

  const NoteWidget({super.key, required this.cotizacion});

  @override
  State<NoteWidget> createState() => _NoteWidgetState();
}

class _NoteWidgetState extends State<NoteWidget> {
  late Map<String, dynamic> cotizacion;

  final TextEditingController _reciboController = TextEditingController();
  final TextEditingController _montoRecibidoController = TextEditingController();
  final TextEditingController _nitController = TextEditingController();
  bool mostrarNIT = false;

  @override
  void initState() {
    super.initState();
    cotizacion = widget.cotizacion;

    final nota = cotizacion['nota'] ?? {};

    _reciboController.text = nota['numero'] ?? '';
    mostrarNIT = nota['mostrarNIT'] ?? false;
    _nitController.text = cotizacion['nit']?.toString() ?? '';

    final recibido = nota['recibido'];
    if (recibido is int) {
      _montoRecibidoController.text = recibido.toDouble().toStringAsFixed(2);
    } else if (recibido is double) {
      _montoRecibidoController.text = recibido.toStringAsFixed(2);
    } else {
      _montoRecibidoController.text = '';
    }
  }

  Future<void> _guardarNota() async {
  final numeroRecibo = _reciboController.text.trim();
  final montoRecibido = double.tryParse(_montoRecibidoController.text.trim()) ?? 0;

  if (numeroRecibo.isEmpty || montoRecibido <= 0) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Completa los campos de número y monto recibido")),
    );
    return;
  }

  if (mostrarNIT && _nitController.text.trim().isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Debes ingresar el NIT si está activado")),
    );
    return;
  }

  final total = _calcularTotal();
  final saldo = total - montoRecibido;
  cotizacion["nit"] = _nitController.text.trim();

  final savedPath = await NotesCore.generarNotaPDF(
    reciboNumero: numeroRecibo,
    recibiDe: cotizacion["nombre_cliente"] ?? '',
    totalCotizacion: total,
    montoRecibido: montoRecibido,
    saldo: saldo,
    concepto: cotizacion["nombre_proyecto"] ?? '',
    empresa: cotizacion["empresa"] ?? '',
    gerente: "Benigno Llanos Veizaga", // puedes hacerlo dinámico si lo deseas
    logoPath: cotizacion["logo"],
    firmaPath: cotizacion["firma"],
    nit: cotizacion["nit"],
    mostrarNIT: mostrarNIT,
    plazoEntrega: "30 DÍAS CALENDARIO", // aquí puedes hacerlo dinámico si quieres
  );

  if (savedPath != null) {
    cotizacion["nota"] = {
      "numero": numeroRecibo,
      "recibido": montoRecibido,
      "mostrarNIT": mostrarNIT,
      "rutaPDF": savedPath,
      "fecha": DateTime.now().toIso8601String(),
    };

    final fileManager = Provider.of<FileManagerCore>(context, listen: false);
    await fileManager.saveFile(cotizacion);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("✅ Nota guardada en:\n$savedPath")),
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("❌ No se pudo guardar la nota.")),
    );
  }
}

  Future<void> _generarReciboPDF() async {
    final nota = cotizacion["nota"];
    if (nota == null || nota["rutaPDF"] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Primero debes guardar la nota.")),
      );
      return;
    }

    final originalPath = nota["rutaPDF"];
    final file = File(originalPath);

    if (!await file.exists()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("El archivo PDF original no existe.")),
      );
      return;
    }

    final dir = file.parent;
    final projectName = cotizacion["nombre_proyecto"]?.toString().trim().replaceAll(RegExp(r'[<>:"/\\|?*]'), '_') ?? 'Recibo';
    final newPath = "${dir.path}/$projectName - Recibo.pdf";

    await file.copy(newPath);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("📄 Recibo generado:\n$newPath")),
    );
  }

  double _calcularTotal() {
    final productos = cotizacion["productos"] as List<dynamic>? ?? [];
    return productos.fold(0.0, (sum, item) {
      final cantidad = double.tryParse(item["cantidad"].toString()) ?? 0;
      final precio = double.tryParse(item["precio_unitario"].toString()) ?? 0;
      return sum + (cantidad * precio);
    });
  }

  String _formatBs(double val) => "${val.toStringAsFixed(2)} Bs";

  Widget _infoRow(String label, String? value) {
    return Row(
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(width: 8),
        Expanded(child: Text(value ?? "-", overflow: TextOverflow.ellipsis)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text("Generar Nota de Recibo de Pago", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),

          if (cotizacion["logo"] != null && File(cotizacion["logo"]).existsSync())
            Center(child: Image.file(File(cotizacion["logo"]), height: 80)),

          const SizedBox(height: 16),
          _infoRow("Cliente:", cotizacion["nombre_cliente"]),
          _infoRow("Proyecto:", cotizacion["nombre_proyecto"]),
          _infoRow("Total Cotización:", _formatBs(_calcularTotal())),

          const SizedBox(height: 20),
          TextField(
            controller: _reciboController,
            decoration: const InputDecoration(labelText: "Número de Recibo"),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _montoRecibidoController,
            decoration: const InputDecoration(labelText: "Monto Recibido (Bs)"),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Checkbox(
                value: mostrarNIT,
                onChanged: (v) => setState(() => mostrarNIT = v ?? false),
              ),
              const Text("Incluir NIT en la nota"),
            ],
          ),

          if (mostrarNIT)
            TextField(
              controller: _nitController,
              decoration: const InputDecoration(labelText: "NIT de la Empresa"),
            ),

          const SizedBox(height: 20),
          ElevatedButton.icon(
            icon: const Icon(Icons.save),
            label: const Text("Guardar Nota"),
            onPressed: _guardarNota,
          ),

          const SizedBox(height: 10),
          ElevatedButton.icon(
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text("Generar Recibo"),
            onPressed: _generarReciboPDF,
          ),
        ],
      ),
    );
  }
}
