import 'printer_model.dart';

class PrinterSettingModel {
  final String id;
  final String name;
  final PrinterConnectionType connectionType;
  final String address; // MAC Address untuk Bluetooth, IP untuk WiFi/LAN, ID untuk USB
  final int port; // Default 9100 untuk Network/WiFi
  final int paperWidth; // 58 atau 80
  final bool autoPrint;
  final bool isDefault;

  const PrinterSettingModel({
    required this.id,
    required this.name,
    required this.connectionType,
    required this.address,
    this.port = 9100,
    this.paperWidth = 58,
    this.autoPrint = true,
    this.isDefault = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'connectionType': connectionType.index,
        'address': address,
        'port': port,
        'paperWidth': paperWidth,
        'autoPrint': autoPrint,
        'isDefault': isDefault,
      };

  factory PrinterSettingModel.fromJson(Map<String, dynamic> json) => PrinterSettingModel(
        id: json['id'] ?? '',
        name: json['name'] ?? 'Printer Kasir',
        connectionType: PrinterConnectionType.values[json['connectionType'] ?? 0],
        address: json['address'] ?? '',
        port: json['port'] ?? 9100,
        paperWidth: json['paperWidth'] ?? 58,
        autoPrint: json['autoPrint'] ?? true,
        isDefault: json['isDefault'] ?? false,
      );

  PrinterSettingModel copyWith({
    String? id,
    String? name,
    PrinterConnectionType? connectionType,
    String? address,
    int? port,
    int? paperWidth,
    bool? autoPrint,
    bool? isDefault,
  }) {
    return PrinterSettingModel(
      id: id ?? this.id,
      name: name ?? this.name,
      connectionType: connectionType ?? this.connectionType,
      address: address ?? this.address,
      port: port ?? this.port,
      paperWidth: paperWidth ?? this.paperWidth,
      autoPrint: autoPrint ?? this.autoPrint,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}
