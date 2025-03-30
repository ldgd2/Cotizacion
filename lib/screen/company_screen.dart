import 'dart:io';
import 'package:flutter/material.dart';
import '../core/company_core.dart';

class CompanyScreen extends StatefulWidget {
  const CompanyScreen({super.key});

  @override
  _CompanyScreenState createState() => _CompanyScreenState();
}

class _CompanyScreenState extends State<CompanyScreen> {
  List<Map<String, dynamic>> companies = [];

  @override
  void initState() {
    super.initState();
    _loadCompanies();
  }

  Future<void> _loadCompanies() async {
    await CompanyCore.initializeCompanyFile();
    setState(() {
      companies = CompanyCore.getCompanies();
    });
  }

  void _showCompanyDialog({Map<String, dynamic>? empresa}) {
    final isEditing = empresa != null;

    final nameController = TextEditingController(text: empresa?["nombre"] ?? "");
    final direccionController = TextEditingController(text: empresa?["direccion"] ?? "");
    final telefonoController = TextEditingController(text: empresa?["telefono"] ?? "");
    final correoController = TextEditingController(text: empresa?["correo"] ?? "");
    final esloganController = TextEditingController(text: empresa?["eslogan"] ?? "");
    String? logoPath = empresa?["logo"];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(isEditing ? "Editar Empresa" : "Nueva Empresa"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: "Nombre de la Empresa"),
                    ),
                    TextField(
                      controller: direccionController,
                      decoration: const InputDecoration(labelText: "Dirección"),
                    ),
                    TextField(
                      controller: telefonoController,
                      decoration: const InputDecoration(labelText: "Teléfono"),
                    ),
                    TextField(
                      controller: correoController,
                      decoration: const InputDecoration(labelText: "Correo"),
                    ),
                    TextField(
                      controller: esloganController,
                      decoration: const InputDecoration(labelText: "Eslogan"),
                    ),
                    const SizedBox(height: 10),
                    if (logoPath != null && File(logoPath!).existsSync())
                      Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        height: 120,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            File(logoPath!),
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.image),
                      label: const Text("Seleccionar Logo"),
                      onPressed: () async {
                        final selected = await CompanyCore.pickAndSaveLogo(nameController.text.trim());
                        if (selected != null) {
                          setStateDialog(() {
                            logoPath = selected;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancelar"),
                ),
                ElevatedButton(
                  child: Text(isEditing ? "Actualizar" : "Guardar"),
                  onPressed: () async {
                    final name = nameController.text.trim();
                    if (name.isEmpty) return;

                    await CompanyCore.addOrUpdateCompany(
                      name: name,
                      direccion: direccionController.text.trim(),
                      telefono: telefonoController.text.trim(),
                      correo: correoController.text.trim(),
                      eslogan: esloganController.text.trim(),
                      logoPath: logoPath,
                    );

                    Navigator.pop(context);
                    _loadCompanies();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _deleteCompany(String name) async {
    final confirmed = await _showConfirmationDialog(
      "Eliminar Empresa",
      "¿Deseas eliminar la empresa '$name'?",
    );

    if (confirmed) {
      await CompanyCore.deleteCompany(name);
      _loadCompanies();
    }
  }

  Future<bool> _showConfirmationDialog(String title, String message) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancelar"),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Eliminar"),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Gestión de Empresas")),
      body: companies.isEmpty
          ? const Center(child: Text("No hay empresas registradas"))
          : ListView.builder(
              itemCount: companies.length,
              itemBuilder: (context, index) {
                final empresa = companies[index];

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    leading: empresa["logo"] != null &&
                            empresa["logo"].isNotEmpty &&
                            File(empresa["logo"]).existsSync()
                        ? Container(
                            width: 60,
                            height: 60,
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Image.file(
                                File(empresa["logo"]),
                                fit: BoxFit.contain,
                              ),
                            ),
                          )
                        : const Icon(Icons.business, size: 40),
                    title: Text(empresa["nombre"]),
                    subtitle: Text(empresa["direccion"] ?? ""),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _showCompanyDialog(empresa: empresa),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteCompany(empresa["nombre"]),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCompanyDialog(),
        icon: const Icon(Icons.add),
        label: const Text("Agregar Empresa"),
      ),
    );
  }
}
