enum PrinterConnectionType {
  bluetooth,
  usb,
  wifi,
}

class PrinterModel {
  final PrinterConnectionType connectionType;
  final String? deviceName;
  final String? address; // MAC Address untuk Bluetooth, IP Address untuk Wi-Fi, Port/Path untuk USB
  final int paperWidth; // 58 atau 80
  final bool autoPrint;
  final bool isConnected;

  const PrinterModel({
    this.connectionType = PrinterConnectionType.bluetooth,
    this.deviceName,
    this.address,
    this.paperWidth = 58,
    this.autoPrint = false,
    this.isConnected = false,
  });

  PrinterModel copyWith({
    PrinterConnectionType? connectionType,
    String? deviceName,
    String? address,
    int? paperWidth,
    bool? autoPrint,
    bool? isConnected,
  }) {
    return PrinterModel(
      connectionType: connectionType ?? this.connectionType,
      deviceName: deviceName ?? this.deviceName,
      address: address ?? this.address,
      paperWidth: paperWidth ?? this.paperWidth,
      autoPrint: autoPrint ?? this.autoPrint,
      isConnected: isConnected ?? this.isConnected,
    );
  }

  Map<String, dynamic> toJson() => {
        'connectionType': connectionType.name,
        'deviceName': deviceName,
        'address': address,
        'paperWidth': paperWidth,
        'autoPrint': autoPrint,
      };

  factory PrinterModel.fromJson(Map<String, dynamic> json) {
    final typeName = json['connectionType'] as String?;

    return PrinterModel(
      connectionType: PrinterConnectionType.values.firstWhere(
        (type) => type.name == typeName,
        orElse: () => PrinterConnectionType.bluetooth,
      ),
      deviceName: json['deviceName'] as String?,
      address: json['address'] as String?,
      paperWidth: json['paperWidth'] as int? ?? 58,
      autoPrint: json['autoPrint'] as bool? ?? false,
    );
  }
}
