import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class ImageManagerScreen extends StatefulWidget {
  final List<String> imagenes;
  final String? firma;
  final Function(List<String> nuevasImagenes, String? nuevaFirma) onUpdate;

  const ImageManagerScreen({
    super.key,
    required this.imagenes,
    required this.firma,
    required this.onUpdate,
  });

  @override
  State<ImageManagerScreen> createState() => _ImageManagerScreenState();
}

class _ImageManagerScreenState extends State<ImageManagerScreen> {
  late List<String> _imagenes;
  String? _firma;
  Set<int> _selectedIndices = {};

  @override
  void initState() {
    super.initState();
    _imagenes = List.from(widget.imagenes);
    _firma = widget.firma;
  }

  Future<void> _pickImage({int? indexToReplace}) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.single.path != null) {
      setState(() {
        if (indexToReplace != null) {
          _imagenes[indexToReplace] = result.files.single.path!;
        } else {
          _imagenes.add(result.files.single.path!);
        }
      });
    }
  }

  Future<void> _pickSignature() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.single.path != null) {
      setState(() {
        _firma = result.files.single.path!;
      });
    }
  }

  void _deleteSelected() {
    setState(() {
      _imagenes = _imagenes
          .asMap()
          .entries
          .where((entry) => !_selectedIndices.contains(entry.key))
          .map((e) => e.value)
          .toList();
      _selectedIndices.clear();
    });
  }

  void _reorder(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex--;
    setState(() {
      final item = _imagenes.removeAt(oldIndex);
      _imagenes.insert(newIndex, item);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestor de Imágenes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () {
              widget.onUpdate(_imagenes, _firma);
              Navigator.pop(context);
            },
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _pickImage(),
        child: const Icon(Icons.add),
        tooltip: "Agregar Imagen",
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text("Firma:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(width: 10),
                _firma != null && File(_firma!).existsSync()
                    ? Image.file(File(_firma!), height: 60)
                    : const Text("No asignada"),
                const Spacer(),
                ElevatedButton.icon(
                  icon: const Icon(Icons.edit),
                  label: const Text("Seleccionar Firma"),
                  onPressed: _pickSignature,
                ),
              ],
            ),
          ),
          Expanded(
            child: ReorderableListView.builder(
              itemCount: _imagenes.length,
              onReorder: _reorder,
              padding: const EdgeInsets.all(8),
              itemBuilder: (context, index) {
                final path = _imagenes[index];
                final selected = _selectedIndices.contains(index);
                return AnimatedContainer(
                  key: ValueKey('img_$index'),
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: selected ? Colors.blue : Colors.grey.shade300,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ListTile(
                    leading: Image.file(File(path), width: 80, height: 80, fit: BoxFit.cover),
                    title: Text("Imagen ${index + 1}"),
                    subtitle: Text(File(path).path.split("/").last),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _pickImage(indexToReplace: index),
                        ),
                        Checkbox(
                          value: selected,
                          onChanged: (value) {
                            setState(() {
                              if (value == true) {
                                _selectedIndices.add(index);
                              } else {
                                _selectedIndices.remove(index);
                              }
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          if (_selectedIndices.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.delete),
                label: const Text("Eliminar seleccionadas"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: _deleteSelected,
              ),
            ),
        ],
      ),
    );
  }
}
