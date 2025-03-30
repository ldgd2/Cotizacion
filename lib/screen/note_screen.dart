import 'package:flutter/material.dart';
import '../widgets/note_widget.dart';

class NoteScreen extends StatelessWidget {
  final Map<String, dynamic> cotizacion;

  const NoteScreen({super.key, required this.cotizacion});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Nota de Recibo de Pago"),
      ),
      body: NoteWidget(cotizacion: cotizacion),
    );
  }
}
