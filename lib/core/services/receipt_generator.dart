import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import '../../models/printer_model.dart';

class ReceiptGenerator {
  static Future<List<int>> generateTestTicket(PrinterModel printer) async {
    final profile = await CapabilityProfile.load();
    final paper = printer.paperWidth == 80 ? PaperSize.mm80 : PaperSize.mm58;
    final generator = Generator(paper, profile);
    List<int> bytes = [];

    bytes += generator.text('SMART KASIR',
        styles: const PosStyles(
          align: PosAlign.center,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
          bold: true,
        ));
    bytes += generator.text('Struk Uji Coba Printer', styles: const PosStyles(align: PosAlign.center));
    bytes += generator.emptyLines(1);

    bytes += generator.text('--------------------------------', styles: const PosStyles(align: PosAlign.center));

    bytes += generator.row([
      PosColumn(text: 'Tipe Koneksi', width: 6),
      PosColumn(
          text: printer.connectionType.toString().split('.').last.toUpperCase(),
          width: 6,
          styles: const PosStyles(align: PosAlign.right)),
    ]);
    bytes += generator.row([
      PosColumn(text: 'Ukuran Kertas', width: 6),
      PosColumn(
          text: '${printer.paperWidth} mm',
          width: 6,
          styles: const PosStyles(align: PosAlign.right)),
    ]);
    
    bytes += generator.text('--------------------------------', styles: const PosStyles(align: PosAlign.center));
    bytes += generator.emptyLines(1);
    
    bytes += generator.text('Printer siap digunakan!', styles: const PosStyles(align: PosAlign.center, bold: true));
    bytes += generator.text(DateTime.now().toString().substring(0, 19), styles: const PosStyles(align: PosAlign.center));
        
    bytes += generator.feed(2);
    bytes += generator.cut();
    
    return bytes;
  }
}
