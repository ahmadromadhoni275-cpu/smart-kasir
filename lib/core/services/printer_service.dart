import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

// Package Cetak
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/printer_model.dart';
import 'receipt_generator.dart';

class PrinterService {
  
  // ==========================================
  // 1. MANAJEMEN PENGATURAN PRINTER (PER CABANG)
  // ==========================================
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

  // ==========================================
  // 2. SCAN PERANGKAT BLUETOOTH
  // ==========================================
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

  // ==========================================
  // 3. ROUTER CETAK STRUK TRANSAKSI UTAMA
  // ==========================================
  Future<void> cetakStruk(Map<String, dynamic> transaksi) async {
    if (kIsWeb || Platform.isIOS) {
      throw Exception('Pencetakan hanya didukung di perangkat Android/Windows.');
    }

    final prefs = await SharedPreferences.getInstance();
    final storeId = prefs.getString('store_id') ?? '0';
    
    final PrinterModel printerConfig = await loadSettings(storeId);

    if (printerConfig.address == null || printerConfig.address!.isEmpty) {
      throw Exception('Printer belum dikonfigurasi. Silakan atur di Pengaturan Toko.');
    }

    // Generate byte struk
    final List<int> bytes = await _generateStrukBytes(transaksi, printerConfig);

    bool isSuccess = false;
    
    // Arahkan ke hardware yang tepat
    if (printerConfig.connectionType == PrinterConnectionType.bluetooth) {
      isSuccess = await _cetakBluetooth(printerConfig.address!, bytes);
    } else if (printerConfig.connectionType == PrinterConnectionType.wifi) {
      isSuccess = await _cetakWifi(printerConfig.address!, bytes);
    } else if (printerConfig.connectionType == PrinterConnectionType.usb) {
      isSuccess = await _cetakUsb(printerConfig.address!, bytes);
    } else {
      throw Exception('Tipe koneksi printer tidak dikenali.');
    }

    if (!isSuccess) {
      throw Exception('Gagal mengirim data ke printer. Pastikan printer menyala dan terhubung.');
    }
  }

  // ==========================================
  // 4. CETAK STRUK TEST (PENGATURAN)
  // ==========================================
  Future<void> printTest(PrinterModel printer) async {
    if (printer.address == null || printer.address!.isEmpty) {
      throw Exception('Alamat MAC/IP Printer belum diatur');
    }

    List<int> bytes = await ReceiptGenerator.generateTestTicket(printer);
    bool isSuccess = false;

    if (printer.connectionType == PrinterConnectionType.bluetooth) {
      isSuccess = await _cetakBluetooth(printer.address!, bytes);
    } else if (printer.connectionType == PrinterConnectionType.wifi) {
      isSuccess = await _cetakWifi(printer.address!, bytes);
    } else if (printer.connectionType == PrinterConnectionType.usb) {
      isSuccess = await _cetakUsb(printer.address!, bytes);
    } else {
      throw Exception('Tipe koneksi tidak dikenali');
    }

    if (!isSuccess) throw Exception('Gagal mengirim data cetak ke printer.');
  }

  // ==========================================
  // 5. HELPER KONEKSI HARDWARE
  // ==========================================
  Future<bool> _cetakBluetooth(String macAddress, List<int> bytes) async {
    try {
      bool isConnected = await PrintBluetoothThermal.connectionStatus;
      
      if (!isConnected) {
        isConnected = await PrintBluetoothThermal.connect(macPrinterAddress: macAddress);
      }

      if (isConnected) {
        bool suksesCetak = await PrintBluetoothThermal.writeBytes(bytes);
        // Putus koneksi setelah jeda agar printer bisa dipakai device lain
        await Future.delayed(const Duration(seconds: 1));
        await PrintBluetoothThermal.disconnect;
        return suksesCetak;
      }
      return false;
    } catch (e) {
      debugPrint('Error Bluetooth: $e');
      return false;
    }
  }

  Future<bool> _cetakWifi(String ipAddress, List<int> bytes) async {
    try {
      // Printer Thermal LAN/Wi-Fi menggunakan TCP Port 9100
      final socket = await Socket.connect(ipAddress, 9100, timeout: const Duration(seconds: 5));
      socket.add(bytes);
      await socket.flush();
      socket.destroy();
      return true;
    } catch (e) {
      debugPrint('Error Wi-Fi/LAN: $e');
      return false;
    }
  }

  Future<bool> _cetakUsb(String deviceId, List<int> bytes) async {
    try {
      // TODO: Implementasi USB (flutter_usb_printer)
      debugPrint('Fitur USB perlu mengaktifkan package flutter_usb_printer.');
      return false;
    } catch (e) {
      debugPrint('Error USB: $e');
      return false;
    }
  }

  // ==========================================
  // 6. GENERATOR DESAIN STRUK TRANSAKSI (DINAMIS & SESUAI TABEL STORES)
  // ==========================================
  Future<List<int>> _generateStrukBytes(Map<String, dynamic> data, PrinterModel printerConfig) async {
    final profile = await CapabilityProfile.load();
    final paper = printerConfig.paperSize == PrinterPaperSize.mm80 ? PaperSize.mm80 : PaperSize.mm58;
    final generator = Generator(paper, profile); 
    List<int> bytes = [];

    // Ambil data dari SharedPreferences (Cabang Aktif) atau Fallback ke payload data transaksi
    final prefs = await SharedPreferences.getInstance();
    final namaToko = prefs.getString('nama_toko') ?? data['store_name'] ?? 'SMART KASIR';
    final alamatToko = prefs.getString('alamat_toko') ?? data['store_address'] ?? '';
    final teleponToko = prefs.getString('telepon_toko') ?? data['store_phone'] ?? '';

    String formatRp(dynamic val) {
      double parsed = double.tryParse(val.toString()) ?? 0;
      return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0).format(parsed);
    }

    String invoice = data['invoice'] ?? data['invoice_number'] ?? '-';
    String tanggal = data['created_at'] ?? DateFormat('dd-MM-yyyy HH:mm').format(DateTime.now());

    // --- HEADER TOKO (Dinamis dari Database Stores) ---
    bytes += generator.text(namaToko.toUpperCase(), styles: const PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2));
    
    if (alamatToko.isNotEmpty) {
      bytes += generator.text(alamatToko, styles: const PosStyles(align: PosAlign.center, fontType: PosFontType.fontB));
    }
    if (teleponToko.isNotEmpty) {
      bytes += generator.text("Telp: $teleponToko", styles: const PosStyles(align: PosAlign.center, fontType: PosFontType.fontB));
    }
    
    bytes += generator.text("--------------------------------", styles: const PosStyles(align: PosAlign.center));
    
    // --- INFO TRANSAKSI ---
    bytes += generator.row([PosColumn(text: "No", width: 4), PosColumn(text: ": $invoice", width: 8)]);
    bytes += generator.row([PosColumn(text: "Tgl", width: 4), PosColumn(text: ": $tanggal", width: 8)]);
    
    if (data['cashier_name'] != null) {
      bytes += generator.row([PosColumn(text: "Ksr", width: 4), PosColumn(text: ": ${data['cashier_name']}", width: 8)]);
    }
    
    // Jika tabel stores mengaktifkan nomor meja & order type
    if (data['table_id'] != null || data['table_number'] != null) {
      String meja = data['table_id']?.toString() ?? data['table_number']?.toString() ?? '';
      bytes += generator.row([PosColumn(text: "Meja", width: 4), PosColumn(text: ": $meja", width: 8)]);
    }
    
    bytes += generator.text("--------------------------------", styles: const PosStyles(align: PosAlign.center));

    // --- DAFTAR ITEM PEMBELIAN ---
    List items = data['items'] ?? [];
    for (var item in items) {
      String name = item['name'] ?? item['product_name'] ?? '';
      String orderType = item['order_type'] ?? '';
      
      // Berikan tanda jika Takeaway
      if (orderType == 'TAKEAWAY') {
        name += ' (Takeaway)';
      }

      bytes += generator.text(name, styles: const PosStyles(align: PosAlign.left, bold: true));
      
      if (item['note'] != null && item['note'].toString().isNotEmpty) {
        bytes += generator.text(" * Catatan: ${item['note']}", styles: const PosStyles(align: PosAlign.left, fontType: PosFontType.fontB));
      }
      
      double price = double.tryParse(item['price'].toString()) ?? 0;
      int qty = int.tryParse(item['quantity']?.toString() ?? item['qty']?.toString() ?? '1') ?? 1;
      double totalItem = price * qty;

      bytes += generator.row([
        PosColumn(text: "$qty x ${formatRp(price)}", width: 8),
        PosColumn(text: formatRp(totalItem), width: 4, styles: const PosStyles(align: PosAlign.right)),
      ]);
    }
    
    bytes += generator.text("--------------------------------", styles: const PosStyles(align: PosAlign.center));
    
    // --- RINCIAN TOTAL & DISKON ---
    double subTotal = double.tryParse(data['sub_total']?.toString() ?? '0') ?? 0;
    double diskon = double.tryParse(data['discount']?.toString() ?? data['discount_total']?.toString() ?? '0') ?? 0;
    double grandTotal = double.tryParse(data['grand_total']?.toString() ?? '0') ?? 0;

    if (subTotal > 0 && diskon > 0) {
      bytes += generator.row([PosColumn(text: "Subtotal", width: 7), PosColumn(text: formatRp(subTotal), width: 5, styles: const PosStyles(align: PosAlign.right))]);
      bytes += generator.row([PosColumn(text: "Diskon", width: 7), PosColumn(text: "- ${formatRp(diskon)}", width: 5, styles: const PosStyles(align: PosAlign.right))]);
    }

    bytes += generator.row([
      PosColumn(text: "TOTAL TAGIHAN", width: 6, styles: const PosStyles(bold: true)), 
      PosColumn(text: formatRp(grandTotal), width: 6, styles: const PosStyles(align: PosAlign.right, bold: true))
    ]);
    
    // --- PEMBAYARAN (Mendukung Split Payment) ---
    List payments = data['payments'] ?? [];
    double totalBayar = 0;
    for (var pay in payments) {
      double amt = double.tryParse(pay['amount'].toString()) ?? 0;
      totalBayar += amt;
      bytes += generator.row([PosColumn(text: "Bayar (${pay['method']})", width: 7), PosColumn(text: formatRp(amt), width: 5, styles: const PosStyles(align: PosAlign.right))]);
    }
    
    double kembali = double.tryParse(data['kembalian']?.toString() ?? '0') ?? (totalBayar - grandTotal);
    if (kembali > 0) {
      bytes += generator.row([PosColumn(text: "Kembalian", width: 7), PosColumn(text: formatRp(kembali), width: 5, styles: const PosStyles(align: PosAlign.right))]);
    }

    // --- FOOTER DINAMIS ---
    bytes += generator.text("================================", styles: const PosStyles(align: PosAlign.center));
    bytes += generator.text("Terima Kasih Atas Kunjungan Anda!", styles: const PosStyles(align: PosAlign.center, bold: true));
    bytes += generator.text("Barang yang sudah dibeli", styles: const PosStyles(align: PosAlign.center, fontType: PosFontType.fontB));
    bytes += generator.text("tidak dapat ditukar/dikembalikan.", styles: const PosStyles(align: PosAlign.center, fontType: PosFontType.fontB));
    bytes += generator.feed(2); // Spasi akhir agar kertas mudah disobek

    return bytes;
  }

}
