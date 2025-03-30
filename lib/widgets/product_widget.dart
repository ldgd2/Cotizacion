import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ProductRow extends StatefulWidget {
  final int index;
  final Map<String, dynamic> producto;
  final bool selected;
  final ValueChanged<bool?> onSelect;
  final ValueChanged<Map<String, dynamic>> onUpdate;

  const ProductRow({
    super.key,
    required this.index,
    required this.producto,
    required this.selected,
    required this.onSelect,
    required this.onUpdate,
  });

  @override
  State<ProductRow> createState() => _ProductRowState();
}

class _ProductRowState extends State<ProductRow> {
  late final TextEditingController _descController;
  late final TextEditingController _cantidadController;
  late final TextEditingController _precioController;

  double get importe {
    final cantidad = double.tryParse(_cantidadController.text) ?? 0.0;
    final precio = double.tryParse(_precioController.text) ?? 0.0;
    return cantidad * precio;
  }

  @override
  void initState() {
    super.initState();
    _descController = TextEditingController(text: widget.producto["descripcion"] ?? "");
    _cantidadController = TextEditingController(text: widget.producto["cantidad"].toString());
    _precioController = TextEditingController(text: widget.producto["precio_unitario"].toString());

    _descController.addListener(_onFieldChange);
    _cantidadController.addListener(_onFieldChange);
    _precioController.addListener(_onFieldChange);
  }

  @override
  
  void _updateControllerText(TextEditingController controller, String newText) {
    final cursorPosition = controller.selection;
    controller.text = newText;
    controller.selection = cursorPosition;
  }

  @override
  void dispose() {
    _descController.dispose();
    _cantidadController.dispose();
    _precioController.dispose();
    super.dispose();
  }

 void _onFieldChange() {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final cantidad = double.tryParse(_cantidadController.text);
    final precio = double.tryParse(_precioController.text);

    widget.onUpdate({
      ...widget.producto,
      "descripcion": _descController.text,
      "cantidad": cantidad ?? 0.0,
      "precio_unitario": precio ?? 0.0,
    });
  });
}




  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Descripción
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Descripción", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                TextFormField(
                  controller: _descController,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Cantidad
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Cantidad", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                TextFormField(
                  controller: _cantidadController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Precio
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Precio", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                TextFormField(
                  controller: _precioController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Importe
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Importe", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                Text(
                  "Bs ${importe.toStringAsFixed(2)}",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),

          // Checkbox + arrastre
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 10.0),
                child: Checkbox(
                  value: widget.selected,
                  onChanged: widget.onSelect,
                ),
              ),
              const Icon(Icons.drag_handle, size: 24, color: Colors.grey),
            ],
          ),
        ],
      ),
    );
  }
}
