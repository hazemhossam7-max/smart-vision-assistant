class EgyptianCurrencyClass {
  const EgyptianCurrencyClass({
    required this.id,
    required this.label,
    required this.valueEgp,
    required this.side,
  });

  final int id;
  final String label;
  final int valueEgp;
  final String side;
}

class EgyptianCurrencyModel {
  const EgyptianCurrencyModel._();

  static const sourceRepository =
      'https://github.com/A7MEDELRAGGAL/Egyptian-Currency-System';
  static const pytorchAssetPath =
      'assets/models/egyptian_currency_yolov8.pt';
  static const labelsAssetPath =
      'assets/models/egyptian_currency_labels.json';
  static const expectedTfliteAssetPath =
      'assets/models/egyptian_currency_yolov8.tflite';

  static const inputImageSize = 640;
  static const precision = 0.9989;
  static const recall = 1.0;
  static const map50 = 0.995;
  static const map50_95 = 0.9907;

  static const classes = <EgyptianCurrencyClass>[
    EgyptianCurrencyClass(id: 0, label: '5_F', valueEgp: 5, side: 'front'),
    EgyptianCurrencyClass(id: 1, label: '5_B', valueEgp: 5, side: 'back'),
    EgyptianCurrencyClass(id: 2, label: '10_F', valueEgp: 10, side: 'front'),
    EgyptianCurrencyClass(id: 3, label: '10_B', valueEgp: 10, side: 'back'),
    EgyptianCurrencyClass(id: 4, label: '20_F', valueEgp: 20, side: 'front'),
    EgyptianCurrencyClass(id: 5, label: '20_B', valueEgp: 20, side: 'back'),
    EgyptianCurrencyClass(id: 6, label: '50_F', valueEgp: 50, side: 'front'),
    EgyptianCurrencyClass(id: 7, label: '50_B', valueEgp: 50, side: 'back'),
    EgyptianCurrencyClass(id: 8, label: '100_F', valueEgp: 100, side: 'front'),
    EgyptianCurrencyClass(id: 9, label: '100_B', valueEgp: 100, side: 'back'),
    EgyptianCurrencyClass(id: 10, label: '200_F', valueEgp: 200, side: 'front'),
    EgyptianCurrencyClass(id: 11, label: '200_B', valueEgp: 200, side: 'back'),
  ];
}
