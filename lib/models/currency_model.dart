class CurrencyModel {
  final String baseCode;
  final String targetCode;
  final double rate;
  final DateTime lastUpdated;

  CurrencyModel({
    required this.baseCode,
    required this.targetCode,
    required this.rate,
    required this.lastUpdated,
  });

  factory CurrencyModel.fromExchangeRateApi({
    required Map<String, dynamic> data,
    required String targetCode,
  }) {
    final Map<String, dynamic> conversionRates =
        Map<String, dynamic>.from(data['conversion_rates'] ?? {});

    final dynamic rawRate = conversionRates[targetCode];

    if (rawRate == null) {
      throw Exception('Không tìm thấy tỷ giá cho $targetCode.');
    }

    return CurrencyModel(
      baseCode: data['base_code'] ?? 'VND',
      targetCode: targetCode,
      rate: (rawRate as num).toDouble(),
      lastUpdated: DateTime.now(),
    );
  }

  double convert(double amount) {
    return amount * rate;
  }
}