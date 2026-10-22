import 'dart:convert';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/printer_model.dart';
import 'receipt_generator.dart';

class PrinterService {
  Future<PrinterModel> loadSettings(String storeId) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('printer_settings_$storeId');
    if (data != null) {
      return PrinterModel.fromJson(jsonDecode(data));
    }
    return const PrinterModel();
  }

  Future<void> saveSettings({required String storeId, required PrinterModel printer}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('printer_settings_$storeId', jsonEncode(printer.toJson()));
  }

  /// 1. MENCARI PERANGKAT BLUETOOTH YANG SUDAH DI-PAIRING
  Future<List<Map<String, String>>> scanDevices(PrinterConnectionType type) async {
    if (type == PrinterConnectionType.bluetooth) {
      // Pastikan Bluetooth aktif
      final bool isBluetoothOn = await PrintBluetoothThermal.bluetoothEnabled;
      if (!isBluetoothOn) throw Exception('Bluetooth tidak aktif. Harap nyalakan Bluetooth HP Anda.');

      // Ambil daftar perangkat yang sudah di-pairing
      final List<BluetoothInfo> devices = await PrintBluetoothThermal.pairedBluetooths;
      
      return devices.map((d) => {
        'name': d.name,
        'address': d.macAdress,
      }).toList();
    }
    
    return [];
  }

  /// 2. EKSEKUSI CETAK (MENGIRIM BYTE KE HARDWARE)
  Future<void> printTest(PrinterModel printer) async {
    if (printer.connectionType == PrinterConnectionType.bluetooth) {
      if (printer.address == null || printer.address!.isEmpty) {
        throw Exception('Alamat MAC Bluetooth belum diatur');
      }

      // Cek status koneksi saat ini
      bool isConnected = await PrintBluetoothThermal.connectionStatus;
      
      if (!isConnected) {
        // Coba hubungkan ke printer
        bool terhubung = await PrintBluetoothThermal.connect(macPrinterAddress: printer.address!);
        if (!terhubung) {
          throw Exception('Gagal terhubung ke printer. Pastikan printer menyala dan berada dalam jangkauan.');
        }
      }

      // Generate byte ESC/POS
      List<int> bytes = await ReceiptGenerator.generateTestTicket(printer);

      // Kirim ke printer
      bool suksesCetak = await PrintBluetoothThermal.writeBytes(bytes);
      if (!suksesCetak) {
         throw Exception('Gagal mengirim data cetak ke printer.');
      }
      
      // Beri sedikit jeda, lalu putus koneksi agar printer bisa diakses perangkat lain jika perlu
      await Future.delayed(const Duration(seconds: 1));
      await PrintBluetoothThermal.disconnect;
      
    } else {
      throw Exception('Saat ini baru mendukung koneksi Bluetooth');
    }
  }
}
