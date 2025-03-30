import 'dart:io';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class NotesCore {
  static Future<String?> generarNotaPDF({
    required String reciboNumero,
    required String recibiDe,
    required double totalCotizacion,
    required double montoRecibido,
    required double saldo,
    required String concepto,
    required String empresa,
    required String gerente,
    required String plazoEntrega,
    String? logoPath,
    String? firmaPath,
    String? nit,
    bool mostrarNIT = false,
  }) async {
    final pdf = pw.Document();
    final now = DateTime.now();
    final fechaTexto = DateFormat('dd/MM/yyyy').format(now);

    // Imagenes
    pw.ImageProvider? logo;
    pw.ImageProvider? firma;
    if (logoPath != null && File(logoPath).existsSync()) {
      logo = pw.MemoryImage(await File(logoPath).readAsBytes());
    }
    if (firmaPath != null && File(firmaPath).existsSync()) {
      firma = pw.MemoryImage(await File(firmaPath).readAsBytes());
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // Logo y Fecha
              pw.Row(
                children: [
                  if (logo != null)
                    pw.Container(width: 200, height: 80, child: pw.Image(logo)),
                  pw.Spacer(),
                  pw.Container(
                    decoration: pw.BoxDecoration(border: pw.Border.all()),
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text('FECHA: $fechaTexto'),
                  ),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Container(
                alignment: pw.Alignment.center,
                decoration: pw.BoxDecoration(border: pw.Border.all()),
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text('RECIBO # $reciboNumero',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              ),
              _infoBox("RECIBI DE:", recibiDe, boldValue: true),
              _infoBox("LA SUMA DE:", "${_bs(montoRecibido)}", boldValue: true),
              _infoBox("CONCEPTO DE:", concepto),
              _infoBox("PLAZO DE ENTREGA:", plazoEntrega),
              pw.Container(
                decoration: pw.BoxDecoration(border: pw.Border.all()),
                padding: const pw.EdgeInsets.all(6),
                child: pw.Text(
                  "A CUENTA: ${_bs(montoRecibido)}     SALDO: ${_bs(saldo)}     TOTAL: ${_bs(totalCotizacion)}",
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.SizedBox(height: 30),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    children: [
                      pw.Text("___________________"),
                      pw.Text("ENTREGUE CONFORME"),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      if (firma != null)
                        pw.Container(height: 40, width: 100, child: pw.Image(firma)),
                      pw.Text(gerente, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                      pw.Text("GERENTE GENERAL", style: const pw.TextStyle(fontSize: 10)),
                      pw.Text(empresa, style: const pw.TextStyle(fontSize: 10)),
                      if (mostrarNIT && nit != null && nit.isNotEmpty)
                        pw.Text("NIT: $nit", style: const pw.TextStyle(fontSize: 10)),
                      pw.Text("RECIBI CONFORME"),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    // Permitir seleccionar carpeta
        // Permitir seleccionar carpeta
    String? dirPath = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Selecciona la carpeta para guardar el recibo',
    );

    if (dirPath == null || !(await Directory(dirPath).exists())) {
      print("❌ Ruta inválida o no existe: $dirPath");
      return null;
    }

    // Nombre del archivo limpio
    final sanitizedName = concepto.trim().replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
    final fileName = '$sanitizedName - Recibo.pdf';
    final fullPath = '$dirPath/$fileName';

    try {
      final file = File(fullPath);
      await file.writeAsBytes(await pdf.save());
      print("✅ Recibo guardado en: $fullPath");
      return fullPath;
    } catch (e) {
      print("❌ Error al guardar PDF: $e");
      return null;
    }
  }


  static pw.Widget _infoBox(String title, String value, {bool boldValue = false}) {
    return pw.Container(
      decoration: pw.BoxDecoration(border: pw.Border.all()),
      padding: const pw.EdgeInsets.all(6),
      child: pw.Row(
        children: [
          pw.Text(title, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(width: 4),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(fontWeight: boldValue ? pw.FontWeight.bold : pw.FontWeight.normal),
            ),
          ),
        ],
      ),
    );
  }

  static String _bs(double value) => "${value.toStringAsFixed(2)} Bs";
}
