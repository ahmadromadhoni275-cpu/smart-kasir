import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../tema.dart';

class PermissionHelper {
  static Future<void> checkAndRequestPermissions(BuildContext context) async {
    if (!Platform.isAndroid) return;

    // 1. Minta Izin Lokasi dan Bluetooth secara bersamaan
    Map<Permission, PermissionStatus> statuses = await [
      Permission.location,
      Permission.bluetoothConnect, // Perangkat di Sekitar (Koneksi)
      Permission.bluetoothScan,    // Perangkat di Sekitar (Pencarian)
    ].request();

    // 2. Cek apakah Izin "Perangkat di Sekitar" ditolak
    bool isNearbyDenied = statuses[Permission.bluetoothConnect]!.isDenied || 
                          statuses[Permission.bluetoothScan]!.isDenied ||
                          statuses[Permission.bluetoothConnect]!.isPermanentlyDenied;

    // Jika ditolak, paksa pengguna membuka pengaturan
    if (isNearbyDenied) {
      if (!context.mounted) return;
      _showMandatoryPermissionDialog(context);
    }
  }

  static void _showMandatoryPermissionDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, // Tidak bisa ditutup dengan mengetuk area luar
      builder: (ctx) => PopScope(
        canPop: false, // Tidak bisa ditutup dengan tombol back
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.bluetooth_disabled, color: AppColors.error, size: 28),
              SizedBox(width: 10),
              Expanded(child: Text('Izin Wajib Diperlukan', style: TextStyle(fontWeight: FontWeight.bold))),
            ],
          ),
          content: const Text(
            'Aplikasi Kasir mewajibkan izin "Perangkat di Sekitar" (Nearby Devices) dan "Lokasi" untuk dapat mencari dan terhubung dengan Printer Thermal.\n\nSilakan buka Pengaturan, pilih "Izin", dan Izinkan akses tersebut.',
            style: TextStyle(height: 1.5, color: AppColors.textSecondary),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryEmerald,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                // Buka pengaturan aplikasi di HP
                await openAppSettings();
                // Setelah kembali dari pengaturan, cek lagi
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  checkAndRequestPermissions(context);
                }
              },
              child: const Text('Buka Pengaturan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
