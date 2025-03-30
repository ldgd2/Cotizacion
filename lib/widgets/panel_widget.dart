import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/fileManager_core.dart';

class PanelWidget extends StatefulWidget {
  final Function(String) onItemSelected;

  const PanelWidget({super.key, required this.onItemSelected});

  @override
  _PanelWidgetState createState() => _PanelWidgetState();
}

class _PanelWidgetState extends State<PanelWidget> {
  bool showAllRecent = false; // Estado para mostrar más archivos recientes

  @override
  Widget build(BuildContext context) {
    final fileManager = Provider.of<FileManagerCore>(context);

    return Drawer(
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: ListView(
              children: [
                _buildMenuArchivo(context, fileManager),
                const Divider(),
                _buildMenuItem(Icons.business, "Empresas", "/company"),
                _buildMenuItem(Icons.attach_money, "Cotizaciones", "/price"),
                _buildMenuItem(Icons.settings, "Configuración", "/config"),
                _buildMenuItem(Icons.note, "Notas", "/note"),
                _buildMenuItem(Icons.image, "Imágenes", "/image"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 📌 **Encabezado del Panel**
  Widget _buildHeader() {
    return DrawerHeader(
      decoration: BoxDecoration(color: Colors.blue.shade700),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.settings, color: Colors.white, size: 40),
          SizedBox(height: 10),
          Text(
            "Menú de Opciones",
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  /// 📌 **Menú de Archivo**
  Widget _buildMenuArchivo(BuildContext context, FileManagerCore fileManager) {
    return ExpansionTile(
      title: const Text("Archivo"),
      leading: const Icon(Icons.folder),
      children: [
        ListTile(
          title: const Text("Nuevo"),
          leading: const Icon(Icons.note_add),
          onTap: () async {
            await fileManager.newFile(context);
          },
        ),
        ListTile(
          title: const Text("Abrir"),
          leading: const Icon(Icons.folder_open),
          onTap: () async {
            await fileManager.openFile(context);
          },
        ),
        ListTile(
          title: const Text("Guardar"),
          leading: const Icon(Icons.save),
          onTap: () async {
            if (fileManager.currentFile != null) {
              await fileManager.saveFile({});
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Archivo guardado exitosamente")),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("No hay un archivo abierto para guardar")),
              );
            }
          },
        ),
        ListTile(
          title: const Text("Guardar Como"),
          leading: const Icon(Icons.save_as),
          onTap: () async {
            await fileManager.saveAsFile({});
          },
        ),
        _buildRecentFiles(context, fileManager),
      ],
    );
  }

  /// 📌 **Menú de archivos recientes**
  Widget _buildRecentFiles(BuildContext context, FileManagerCore fileManager) {
    final recentFiles = fileManager.recentFiles;
    final visibleFiles = showAllRecent ? recentFiles : recentFiles.take(10).toList();

    return ExpansionTile(
      title: const Text("Recientes"),
      leading: const Icon(Icons.history),
      children: [
        if (recentFiles.isEmpty)
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text("No hay archivos recientes"),
          )
        else
          ...visibleFiles.map((fileData) {
            List<String> fileParts = fileData.split('|');
            String fileName = fileParts[0];
            String filePath = fileParts[1];

            return ListTile(
              title: Text(fileName, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(filePath, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              leading: const Icon(Icons.insert_drive_file),
              trailing: const Icon(Icons.arrow_forward),
              onTap: () async {
                await fileManager.openRecentFile(context, filePath);
              },
            );
          }).toList(),
        if (recentFiles.length > 10)
          ListTile(
            title: Text(showAllRecent ? "Ocultar archivos" : "Cargar más"),
            leading: Icon(showAllRecent ? Icons.arrow_drop_up : Icons.arrow_drop_down),
            onTap: () {
              setState(() {
                showAllRecent = !showAllRecent;
              });
            },
          ),
      ],
    );
  }

  /// 📌 **Item de Menú con navegación**
  Widget _buildMenuItem(IconData icon, String title, String route) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue.shade700),
      title: Text(title),
      onTap: () {
        widget.onItemSelected(route);
      },
    );
  }
}
