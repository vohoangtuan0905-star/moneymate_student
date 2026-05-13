import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/currency_model.dart';

class CurrencyService {
  static const String _apiKey = 'd576b39358d3c1679d58326a';
  static const String _baseUrl = 'https://v6.exchangerate-api.com/v6';

  Future<CurrencyModel> getExchangeRate({
    required String baseCode,
    required String targetCode,
  }) async {
    final Uri uri = Uri.parse('$_baseUrl/$_apiKey/latest/$baseCode');

    final http.Response response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Không thể kết nối ExchangeRate-API.');
    }

    final Map<String, dynamic> data =
        jsonDecode(response.body) as Map<String, dynamic>;

    final String result = data['result'] ?? 'error';

    if (result != 'success') {
      final String errorType = data['error-type'] ?? 'unknown-error';
      throw Exception('ExchangeRate-API lỗi: $errorType');
    }

    return CurrencyModel.fromExchangeRateApi(
      data: data,
      targetCode: targetCode,
    );
  }

  Future<double> convertCurrency({
    required double amount,
    required String baseCode,
    required String targetCode,
  }) async {
    final CurrencyModel currencyModel = await getExchangeRate(
      baseCode: baseCode,
      targetCode: targetCode,
    );

    return currencyModel.convert(amount);
  }
}