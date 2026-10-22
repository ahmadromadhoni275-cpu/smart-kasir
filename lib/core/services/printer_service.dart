import '../../models/printer_model.dart';
import 'printer_storage_service.dart';

class PrinterService {
  final PrinterStorageService _storage = PrinterStorageService();

  Future<PrinterModel> loadSettings(String storeId) {
    return _storage.load(storeId: storeId);
  }

  Future<void> saveSettings({
    required String storeId,
    required PrinterModel printer,
  }) {
    return _storage.save(
      storeId: storeId,
      printer: printer,
    );
  }

  // Simulasi/Pencarian Perangkat berdasarkan Tipe Koneksi
  Future<List<Map<String, String>>> scanDevices(PrinterConnectionType type) async {
    await Future.delayed(const Duration(seconds: 1)); // Simulasi delay jeda scan
    
    if (type == PrinterConnectionType.bluetooth) {
      return [
        {'name': 'Bluetooth Thermal 58mm', 'address': '00:11:22:33:44:55'},
        {'name': 'EPOS Printer 80mm', 'address': 'AA:BB:CC:DD:EE:FF'},
      ];
    } else if (type == PrinterConnectionType.wifi) {
      return [
        {'name': 'Network Printer (LAN)', 'address': '192.168.1.200:9100'},
      ];
    } else {
      return [
        {'name': 'USB POS Printer', 'address': 'USB_PORT_01'},
      ];
    }
  }

  Future<void> connect(PrinterModel printer) async {
    // Tempat integrasi driver fisik (misal: blue_thermal_printer / esc_pos_printer)
    await Future.delayed(const Duration(milliseconds: 800));
    if (printer.address == null || printer.address!.isEmpty) {
      throw Exception('Pilih atau tentukan perangkat terlebih dahulu.');
    }
  }

  Future<void> printTest(PrinterModel printer) async {
    await Future.delayed(const Duration(milliseconds: 800));
    if (!printer.isConnected) {
      throw Exception('Printer belum terhubung.');
    }
  }

  Future<void> disconnect(PrinterModel printer) async {
    await Future.delayed(const Duration(milliseconds: 500));
  }
}
