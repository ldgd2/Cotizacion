import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class ConvertPDFCore {
  /// Genera un PDF con los datos de la cotización
  static Future<File> generarPDF({
    required String nombreArchivo,
    required String empresa,
    required String direccion,
    required String telefono,
    required String correo,
    required String? logoPath,
    required List<Map<String, dynamic>> productos,
    required double total,
    required String moneda,
    required String fecha,
  }) async {
    final pdf = pw.Document();

    // Cargar fuente personalizada si es necesario
    final pw.Font font = await _loadFont();

    // Cargar imagen del logo si existe
    pw.Widget? logoWidget;
    if (logoPath != null && File(logoPath).existsSync()) {
      final Uint8List imageData = File(logoPath).readAsBytesSync();
      logoWidget = pw.Image(
        pw.MemoryImage(imageData),
        width: 80,
        height: 80,
      );
    }

    // Definir estilos
    final pw.TextStyle estiloNormal = pw.TextStyle(font: font, fontSize: 12);
    final pw.TextStyle estiloNegrita = pw.TextStyle(font: font, fontSize: 12, fontWeight: pw.FontWeight.bold);
    final pw.TextStyle estiloTitulo = pw.TextStyle(font: font, fontSize: 14, fontWeight: pw.FontWeight.bold);

    // 1. Encabezado
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) => [
          // Encabezado
          pw.Table(
            columnWidths: {
              0: const pw.FixedColumnWidth(120),
              1: const pw.FlexColumnWidth(),
            },
            children: [
              pw.TableRow(
                children: [
                  logoWidget ?? pw.Container(), // Logo
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(empresa, style: estiloTitulo),
                      pw.Text(direccion, style: estiloNormal),
                      pw.Text(telefono, style: estiloNormal),
                      pw.Text(correo, style: estiloNormal),
                    ],
                  ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 20),
          pw.Text("Fecha: $fecha", style: estiloNegrita),
          pw.SizedBox(height: 10),

          // 2. Tabla de Productos
          _buildTable(productos, font),

          pw.SizedBox(height: 20),
          pw.Text("Total: ${total.toStringAsFixed(2)} $moneda", style: estiloTitulo),

          // Pie de página con numeración
        ],
        footer: (pw.Context context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(top: 10),
          child: pw.Text("Página ${context.pageNumber}", style: estiloNormal),
        ),
      ),
    );

    // Guardar el PDF en un archivo
    final Directory dir = await getApplicationDocumentsDirectory();
    final String filePath = "${dir.path}/$nombreArchivo.pdf";
    final File file = File(filePath);
    await file.writeAsBytes(await pdf.save());

    return file;
  }

  /// Construye la tabla de productos
  static pw.Widget _buildTable(List<Map<String, dynamic>> productos, pw.Font font) {
    return pw.Table(
      border: pw.TableBorder.all(),
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(1),
        2: const pw.FlexColumnWidth(1),
        3: const pw.FlexColumnWidth(1.5),
        4: const pw.FlexColumnWidth(1.5),
      },
      children: [
        // Encabezado de la tabla
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.black),
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(5),
              child: pw.Text("Descripción", style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(5),
              child: pw.Text("Cantidad", style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(5),
              child: pw.Text("Unidad", style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(5),
              child: pw.Text("Precio Unitario", style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(5),
              child: pw.Text("Importe", style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold)),
            ),
          ],
        ),
        // Filas de productos
        ...productos.map((producto) => pw.TableRow(
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5),
                  child: pw.Text(producto['descripcion']),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5),
                  child: pw.Text(producto['cantidad'].toString()),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5),
                  child: pw.Text(producto['unidad']),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5),
                  child: pw.Text("${producto['precio_unitario'].toStringAsFixed(2)} Bs"),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5),
                  child: pw.Text("${producto['importe'].toStringAsFixed(2)} Bs"),
                ),
              ],
            )),
      ],
    );
  }

  /// Carga una fuente personalizada
  static Future<pw.Font> _loadFont() async {
    final ByteData fontData = await rootBundle.load("assets/fonts/Roboto-Regular.ttf");
    return pw.Font.ttf(fontData);
  }
}
