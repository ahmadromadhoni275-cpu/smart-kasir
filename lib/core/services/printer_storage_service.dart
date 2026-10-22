import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/printer_model.dart';

class PrinterStorageService {
  static const String _keyPrefix = 'smart_kasir_printer_';

  Future<void> save({
    required String storeId,
    required PrinterModel printer,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '$_keyPrefix$storeId',
      jsonEncode(printer.toJson()),
    );
  }

  Future<PrinterModel> load({
    required String storeId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('$_keyPrefix$storeId');

    if (jsonString == null) {
      return const PrinterModel();
    }

    try {
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      return PrinterModel.fromJson(data);
    } catch (_) {
      return const PrinterModel();
    }
  }

  Future<void> clear({
    required String storeId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_keyPrefix$storeId');
  }
}
