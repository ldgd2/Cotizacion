import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/fileManager_core.dart';
import '../widgets/panel_widget.dart'; // Importamos el PanelWidget

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //--------------------- Barra de App -----------------------------------------
      appBar: AppBar(
        title: const Text('Gestión de Cotizaciones'),
        centerTitle: true,
      ),
      //-----------------------------------------------------------------------------

      //--------------------- Panel widget -----------------------------------------
      drawer: PanelWidget(
        onItemSelected: (route) {
          Navigator.pop(context); // Cierra el panel lateral antes de navegar
          Navigator.pushNamed(context, route);
        },
      ),
      //-----------------------------------------------------------------------------

      //--------------------- Contenido Principal -----------------------------------
      body: _buildBody(context),
      //-----------------------------------------------------------------------------
    );
  }

  /// 📌 **Construcción del Cuerpo Principal**
  Widget _buildBody(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.request_quote, size: 80, color: Colors.blueAccent),
          const SizedBox(height: 20),
          Text(
            "Bienvenido a la Gestión de Cotizaciones",
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          _buildQuickActions(context), // Acciones rápidas
        ],
      ),
    );
  }

  /// 📌 **Botones de Acciones Rápidas**
  Widget _buildQuickActions(BuildContext context) {
    final fileManager = Provider.of<FileManagerCore>(context, listen: false);

    return Column(
      children: [
        ElevatedButton.icon(
          icon: const Icon(Icons.note_add),
          label: const Text("Nueva Cotización"),
          onPressed: () async {
            await fileManager.newFile(context);
          },
        ),
        const SizedBox(height: 10),
        ElevatedButton.icon(
          icon: const Icon(Icons.folder_open),
          label: const Text("Abrir Cotización"),
          onPressed: () async {
            await fileManager.openFile(context);
          },
        ),
      ],
    );
  }
}
