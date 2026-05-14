import 'package:flutter/material.dart';

import '../../services/currency_service.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';

class CurrencyConverterScreen extends StatefulWidget {
  const CurrencyConverterScreen({super.key});

  @override
  State<CurrencyConverterScreen> createState() =>
      _CurrencyConverterScreenState();
}

class _CurrencyConverterScreenState extends State<CurrencyConverterScreen> {
  final CurrencyService _currencyService = CurrencyService();

  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();

  String _baseCurrency = 'VND';
  String _targetCurrency = 'USD';

  double? _convertedAmount;
  double? _exchangeRate;

  bool _isLoading = false;

  final List<String> _currencies = [
    'VND',
    'USD',
    'EUR',
    'JPY',
    'KRW',
    'CNY',
    'THB',
    'SGD',
    'AUD',
    'GBP',
  ];

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  String _formatNumber(double value) {
    final String fixed = value.toStringAsFixed(2);
    final List<String> parts = fixed.split('.');

    final RegExp regExp = RegExp(r'\B(?=(\d{3})+(?!\d))');
    final String integerPart =
        parts[0].replaceAllMapped(regExp, (match) => '.');

    final String decimalPart = parts.length > 1 ? parts[1] : '00';

    if (decimalPart == '00') {
      return integerPart;
    }

    return '$integerPart,$decimalPart';
  }

  String? _validateAmount(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập số tiền';
    }

    final double? amount = double.tryParse(value.trim());

    if (amount == null) {
      return 'Số tiền không hợp lệ';
    }

    if (amount <= 0) {
      return 'Số tiền phải lớn hơn 0';
    }

    return null;
  }

  Future<void> _convertCurrency() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_baseCurrency == _targetCurrency) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn hai loại tiền khác nhau.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _convertedAmount = null;
      _exchangeRate = null;
    });

    try {
      final double amount = double.parse(_amountController.text.trim());

      final rateModel = await _currencyService.getExchangeRate(
        baseCode: _baseCurrency,
        targetCode: _targetCurrency,
      );

      final double result = rateModel.convert(amount);

      if (!mounted) return;

      setState(() {
        _exchangeRate = rateModel.rate;
        _convertedAmount = result;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _swapCurrencies() {
    setState(() {
      final String oldBase = _baseCurrency;
      _baseCurrency = _targetCurrency;
      _targetCurrency = oldBase;
      _convertedAmount = null;
      _exchangeRate = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8F5),
      appBar: AppBar(
        title: const Text('Chuyển đổi tiền tệ'),
        centerTitle: true,
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _buildIntroCard(),
              const SizedBox(height: 18),
              _buildConverterCard(),
              const SizedBox(height: 18),
              if (_convertedAmount != null && _exchangeRate != null)
                _buildResultCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIntroCard() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.currency_exchange,
              size: 76,
              color: Colors.green,
            ),
            SizedBox(height: 14),
            Text(
              'Chuyển đổi tiền tệ',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Nhập số tiền, chọn loại tiền cần quy đổi và xem kết quả theo tỷ giá mới nhất.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.black54,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConverterCard() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              CustomTextField(
                controller: _amountController,
                labelText: 'Số tiền',
                hintText: 'Ví dụ: 1000000',
                prefixIcon: Icons.payments,
                keyboardType: TextInputType.number,
                validator: _validateAmount,
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _buildCurrencyDropdown(
                      label: 'Từ',
                      value: _baseCurrency,
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _baseCurrency = value;
                            _convertedAmount = null;
                            _exchangeRate = null;
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    onPressed: _swapCurrencies,
                    icon: const Icon(Icons.swap_horiz),
                    color: Colors.green,
                    tooltip: 'Đổi chiều',
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildCurrencyDropdown(
                      label: 'Sang',
                      value: _targetCurrency,
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _targetCurrency = value;
                            _convertedAmount = null;
                            _exchangeRate = null;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              CustomButton(
                text: 'Chuyển đổi',
                isLoading: _isLoading,
                onPressed: _convertCurrency,
                backgroundColor: Colors.green,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrencyDropdown({
    required String label,
    required String value,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: Colors.grey.shade300,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Colors.green,
            width: 2,
          ),
        ),
      ),
      items: _currencies.map((String currency) {
        return DropdownMenuItem<String>(
          value: currency,
          child: Text(currency),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildResultCard() {
    final double amount = double.tryParse(_amountController.text.trim()) ?? 0;

    return Card(
      elevation: 3,
      color: Colors.green.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            const Icon(
              Icons.check_circle,
              size: 60,
              color: Colors.green,
            ),
            const SizedBox(height: 12),
            const Text(
              'Kết quả chuyển đổi',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '${_formatNumber(amount)} $_baseCurrency',
              style: const TextStyle(
                fontSize: 17,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 6),
            const Icon(
              Icons.arrow_downward,
              color: Colors.green,
            ),
            const SizedBox(height: 6),
            Text(
              '${_formatNumber(_convertedAmount!)} $_targetCurrency',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Tỷ giá: 1 $_baseCurrency = ${_exchangeRate!.toStringAsFixed(8)} $_targetCurrency',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}