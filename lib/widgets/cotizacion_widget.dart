// Usa este archivo como cotizacion_widget.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/company_core.dart';
import '../core/fileManager_core.dart';
import '../core/convertPDF_core.dart';
import 'product_widget.dart';

class CotizacionWidget extends StatefulWidget {
  final Map<String, dynamic> cotizacion;

  const CotizacionWidget({super.key, required this.cotizacion});

  @override
  State<CotizacionWidget> createState() => _CotizacionWidgetState();
}

class _CotizacionWidgetState extends State<CotizacionWidget> {
  late Map<String, dynamic> cotizacion;
  List<Map<String, dynamic>> productos = [];
  List<Map<String, dynamic>> empresas = [];
  Set<int> selectedIndices = {};
  double total = 0.0;
  String selectedEmpresa = "Seleccionar Empresa";

  late TextEditingController proyectoController;
late TextEditingController clienteController;

@override
void initState() {
  super.initState();
  cotizacion = widget.cotizacion;
  productos = List<Map<String, dynamic>>.from(cotizacion["productos"] ?? []);
  cotizacion["productos"] = productos; // 👈 Importante para mantener referencias sincronizadas
  selectedEmpresa = cotizacion["empresa"] ?? "Seleccionar Empresa";

  proyectoController = TextEditingController(text: cotizacion["nombre_proyecto"] ?? "");
  clienteController = TextEditingController(text: cotizacion["nombre_cliente"] ?? "");

  _calculateTotal();
  _loadEmpresas();
}


  Future<void> _loadEmpresas() async {
    await CompanyCore.initializeCompanyFile();
    setState(() {
      empresas = CompanyCore.getCompanies();
    });
  }

 void _calculateTotal() {
  setState(() {
    total = productos.fold(0.0, (sum, item) {
      final cantidad = double.tryParse(item["cantidad"].toString()) ?? 0;
      final precio = double.tryParse(item["precio_unitario"].toString()) ?? 0;
      return sum + (cantidad * precio);
    });
  });
}



  void _onSelectEmpresa(String value) {
    final empresa = empresas.firstWhere((e) => e["nombre"] == value);
    setState(() {
      selectedEmpresa = value;
      cotizacion.addAll(empresa);
    });
  }

  void _addProduct() {
  setState(() {
    productos.add({
      "descripcion": "Producto",
      "cantidad": 1,
      "precio_unitario": 0.0,
    });
    cotizacion["productos"] = productos;
  });
}


  void _deleteSelected() {
  setState(() {
    productos.removeWhere((p) => selectedIndices.contains(productos.indexOf(p)));
    selectedIndices.clear();
    cotizacion["productos"] = productos; // ✅
    _calculateTotal(); // ✅ recalcula
  });
}


  Future<void> _generatePDF() async {
    final file = await ConvertPDFCore.generarPDF(
      nombreArchivo: "cotizacion",
      empresa: cotizacion["empresa"] ?? "",
      direccion: cotizacion["direccion"] ?? "",
      telefono: cotizacion["telefono"] ?? "",
      correo: cotizacion["correo"] ?? "",
      logoPath: cotizacion["logo"],
      productos: productos,
      total: total,
      moneda: cotizacion["moneda"] ?? "BOB (Bs)",
      fecha: cotizacion["fecha"] ?? "",
    );
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("PDF generado en ${file.path}")));
  }

 Future<void> _save() async {
  // 🧠 Asegurar sincronización completa antes de guardar
 cotizacion["nombre_proyecto"] = proyectoController.text;
cotizacion["nombre_cliente"] = clienteController.text;
cotizacion["productos"] = productos;

  cotizacion["empresa"] = selectedEmpresa;

  final manager = Provider.of<FileManagerCore>(context, listen: false);
  await manager.saveFile(Map.from(cotizacion)); // 👈 copia limpia
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text("✅ Cotización guardada")),
  );
}



 @override
Widget build(BuildContext context) {
  return LayoutBuilder(
    builder: (context, constraints) {
      return SingleChildScrollView(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: IntrinsicHeight(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // COMBO EMPRESA
                Row(
                  children: [
                    const Text("Empresa:", style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: selectedEmpresa != "Seleccionar Empresa" ? selectedEmpresa : null,
                        hint: const Text("Seleccionar Empresa"),
                        items: empresas
                            .map((e) => DropdownMenuItem<String>(
                                  value: e["nombre"],
                                  child: Text(e["nombre"]),
                                ))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) _onSelectEmpresa(value);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // LOGO E INFO
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (cotizacion["logo"] != null && File(cotizacion["logo"]).existsSync())
                      Image.file(File(cotizacion["logo"]), width: 80, height: 80, fit: BoxFit.contain),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(cotizacion["empresa"] ?? "", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text(cotizacion["direccion"] ?? ""),
                          Text(cotizacion["telefono"] ?? ""),
                          Text(cotizacion["correo"] ?? ""),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // PROYECTO Y CLIENTE
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: proyectoController,
                        onChanged: (v) => cotizacion["nombre_proyecto"] = v,
                        decoration: const InputDecoration(labelText: "Nombre del Proyecto"),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: clienteController,
                        onChanged: (v) => cotizacion["nombre_cliente"] = v,
                        decoration: const InputDecoration(labelText: "Nombre del Cliente"),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // PRODUCTOS
                SizedBox(
                  height: 400, // Altura fija scrollable
                  child: ReorderableListView.builder(
                    itemCount: productos.length,
                    onReorder: (oldIndex, newIndex) {
                      if (newIndex > oldIndex) newIndex--;
                      final item = productos.removeAt(oldIndex);
                      productos.insert(newIndex, item);
                      _calculateTotal();
                      setState(() {});
                    },
                    itemBuilder: (context, index) {
                      return ProductRow(
                        key: ValueKey('producto_$index'),
                        index: index,
                        producto: productos[index],
                        selected: selectedIndices.contains(index),
                        onSelect: (selected) {
                          setState(() {
                            selected == true ? selectedIndices.add(index) : selectedIndices.remove(index);
                          });
                        },
                        onUpdate: (updatedProducto) {
                          productos[index] = updatedProducto;
                          _calculateTotal();
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),

                // BOTONES
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text("Total: ${total.toStringAsFixed(2)} Bs", style: const TextStyle(fontSize: 18)),
                    const SizedBox(height: 10),
                    Wrap(
  spacing: 12,
  runSpacing: 8,
  alignment: WrapAlignment.center,
  children: [
    ElevatedButton.icon(
      onPressed: _addProduct,
      icon: const Icon(Icons.add),
      label: const Text("Agregar"),
    ),
    ElevatedButton.icon(
      onPressed: selectedIndices.isNotEmpty ? _deleteSelected : null,
      icon: const Icon(Icons.delete),
      label: const Text("Eliminar"),
      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
    ),
    ElevatedButton.icon(
      icon: const Icon(Icons.image),
      label: const Text("Imágenes y Firma"),
      onPressed: () {
        final imagenes = List<String>.from(cotizacion["imagenes"] ?? []);
        final firma = cotizacion["firma"];
        Navigator.pushNamed(context, "/image", arguments: {
          "imagenes": imagenes,
          "firma": firma,
          "onUpdate": (List<String> imgs, String? f) {
            setState(() {
              cotizacion["imagenes"] = imgs;
              cotizacion["firma"] = f;
            });
          }
        });
      },
    ),
    ElevatedButton.icon(
      icon: const Icon(Icons.receipt_long),
      label: const Text("Recibo de Anticipo"),
      onPressed: () {
        Navigator.pushNamed(context, "/notes", arguments: cotizacion);
      },
    ),
    ElevatedButton.icon(
      onPressed: _generatePDF,
      icon: const Icon(Icons.picture_as_pdf),
      label: const Text("PDF"),
    ),
    ElevatedButton.icon(
      onPressed: _save,
      icon: const Icon(Icons.save),
      label: const Text("Guardar"),
    ),
  ],
),

                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
}