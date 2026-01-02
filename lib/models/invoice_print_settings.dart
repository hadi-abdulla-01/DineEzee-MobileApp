class InvoiceNumbering {
  final String prefix;
  final int nextNumber;

  InvoiceNumbering({
    required this.prefix,
    required this.nextNumber,
  });

  factory InvoiceNumbering.fromMap(Map<String, dynamic> data) {
    return InvoiceNumbering(
      prefix: data['prefix'] ?? '',
      nextNumber: data['nextNumber'] ?? 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'prefix': prefix,
      'nextNumber': nextNumber,
    };
  }

  InvoiceNumbering copyWith({
    String? prefix,
    int? nextNumber,
  }) {
    return InvoiceNumbering(
      prefix: prefix ?? this.prefix,
      nextNumber: nextNumber ?? this.nextNumber,
    );
  }
}

class InvoiceSettings {
  final bool useUnifiedNumbering;
  final InvoiceNumbering unified;
  final InvoiceNumbering dineIn;
  final InvoiceNumbering online;
  final InvoiceNumbering takeAway;

  InvoiceSettings({
    required this.useUnifiedNumbering,
    required this.unified,
    required this.dineIn,
    required this.online,
    required this.takeAway,
  });

  factory InvoiceSettings.defaultSettings() {
    return InvoiceSettings(
      useUnifiedNumbering: true,
      unified: InvoiceNumbering(prefix: 'INV-', nextNumber: 1),
      dineIn: InvoiceNumbering(prefix: 'DI-', nextNumber: 1),
      online: InvoiceNumbering(prefix: 'ON-', nextNumber: 1),
      takeAway: InvoiceNumbering(prefix: 'TA-', nextNumber: 1),
    );
  }

  factory InvoiceSettings.fromMap(Map<String, dynamic> data) {
    return InvoiceSettings(
      useUnifiedNumbering: data['useUnifiedNumbering'] ?? true,
      unified: InvoiceNumbering.fromMap(data['unified'] ?? {}),
      dineIn: InvoiceNumbering.fromMap(data['dineIn'] ?? {}),
      online: InvoiceNumbering.fromMap(data['online'] ?? {}),
      takeAway: InvoiceNumbering.fromMap(data['takeAway'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'useUnifiedNumbering': useUnifiedNumbering,
      'unified': unified.toMap(),
      'dineIn': dineIn.toMap(),
      'online': online.toMap(),
      'takeAway': takeAway.toMap(),
    };
  }

  InvoiceSettings copyWith({
    bool? useUnifiedNumbering,
    InvoiceNumbering? unified,
    InvoiceNumbering? dineIn,
    InvoiceNumbering? online,
    InvoiceNumbering? takeAway,
  }) {
    return InvoiceSettings(
      useUnifiedNumbering: useUnifiedNumbering ?? this.useUnifiedNumbering,
      unified: unified ?? this.unified,
      dineIn: dineIn ?? this.dineIn,
      online: online ?? this.online,
      takeAway: takeAway ?? this.takeAway,
    );
  }
}

enum PrintSize {
  a4,
  thermal80mm,
  custom;

  String get displayName {
    switch (this) {
      case PrintSize.a4:
        return 'A4 / US Letter';
      case PrintSize.thermal80mm:
        return '80mm Thermal Receipt';
      case PrintSize.custom:
        return 'Custom (mm)';
    }
  }

  static PrintSize fromString(String value) {
    switch (value) {
      case 'a4':
        return PrintSize.a4;
      case 'thermal80mm':
        return PrintSize.thermal80mm;
      case 'custom':
        return PrintSize.custom;
      default:
        return PrintSize.a4;
    }
  }

  String toStringValue() {
    return toString().split('.').last;
  }
}

class PrintSettings {
  final PrintSize invoicePrintSize;
  final int? invoiceCustomWidth;
  final PrintSize kitchenTicketPrintSize;
  final int? kitchenTicketCustomWidth;

  PrintSettings({
    required this.invoicePrintSize,
    this.invoiceCustomWidth,
    required this.kitchenTicketPrintSize,
    this.kitchenTicketCustomWidth,
  });

  factory PrintSettings.defaultSettings() {
    return PrintSettings(
      invoicePrintSize: PrintSize.a4,
      invoiceCustomWidth: 80,
      kitchenTicketPrintSize: PrintSize.thermal80mm,
      kitchenTicketCustomWidth: 80,
    );
  }

  factory PrintSettings.fromMap(Map<String, dynamic> data) {
    return PrintSettings(
      invoicePrintSize: PrintSize.fromString(data['invoicePrintSize'] ?? 'a4'),
      invoiceCustomWidth: data['invoiceCustomWidth'],
      kitchenTicketPrintSize: PrintSize.fromString(data['kitchenTicketPrintSize'] ?? 'thermal80mm'),
      kitchenTicketCustomWidth: data['kitchenTicketCustomWidth'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'invoicePrintSize': invoicePrintSize.toStringValue(),
      'invoiceCustomWidth': invoiceCustomWidth,
      'kitchenTicketPrintSize': kitchenTicketPrintSize.toStringValue(),
      'kitchenTicketCustomWidth': kitchenTicketCustomWidth,
    };
  }

  PrintSettings copyWith({
    PrintSize? invoicePrintSize,
    int? invoiceCustomWidth,
    PrintSize? kitchenTicketPrintSize,
    int? kitchenTicketCustomWidth,
  }) {
    return PrintSettings(
      invoicePrintSize: invoicePrintSize ?? this.invoicePrintSize,
      invoiceCustomWidth: invoiceCustomWidth ?? this.invoiceCustomWidth,
      kitchenTicketPrintSize: kitchenTicketPrintSize ?? this.kitchenTicketPrintSize,
      kitchenTicketCustomWidth: kitchenTicketCustomWidth ?? this.kitchenTicketCustomWidth,
    );
  }
}
