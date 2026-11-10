import 'package:flutter/foundation.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';

class BluetoothPrinterService {
  static Future<bool> isBluetoothEnabled() async {
    try {
      return await PrintBluetoothThermal.bluetoothEnabled;
    } catch (e) {
      debugPrint('Error cek bluetooth: $e');
      return false;
    }
  }

  static Future<List>> scanPairedDevices() async {
    try {
      final bool isEnabled = await isBluetoothEnabled();
      if (!isEnabled) {
        throw Exception('Bluetooth tidak aktif. Nyalakan Bluetooth perangkat Anda.');
      }

      final List<BluetoothInfo> devices = await PrintBluetoothThermal.pairedBluetooths;
      return devices.map((d) => {
            'name': d.name.isNotEmpty ? d.name : 'Unknown Printer',
            'address': d.macAdress,
          }).toList();
    } catch (e) {
      throw Exception('Gagal memindai perangkat Bluetooth: $e');
    }
  }

  static Future<bool> connectAndPrint(String macAddress, List<int> bytes) async {
    try {
      bool status = await PrintBluetoothThermal.connectionStatus;
      if (!status) {
        status = await PrintBluetoothThermal.connect(macPrinterAddress: macAddress);
      }

      if (status) {
        bool result = await PrintBluetoothThermal.writeBytes(bytes);
        await Future.delayed(const Duration(milliseconds: 500));
        await PrintBluetoothThermal.disconnect;
        return result;
      }
      return false;
    } catch (e) {
      debugPrint('Error cetak Bluetooth: $e');
      return false;
    }
  }

  static Future<bool> testConnection(String macAddress) async {
    try {
      bool status = await PrintBluetoothThermal.connect(macPrinterAddress: macAddress);
      if (status) {
        await PrintBluetoothThermal.disconnect;
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
