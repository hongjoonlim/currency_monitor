import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/currency_service.dart';
import 'package:intl/intl.dart';

class CurrencyConverter extends StatefulWidget {
  const CurrencyConverter({Key? key}) : super(key: key);

  @override
  State<CurrencyConverter> createState() => _CurrencyConverterState();
}

class _CurrencyConverterState extends State<CurrencyConverter> {
  final TextEditingController _eurController = TextEditingController(text: '1.00');
  final TextEditingController _krwController = TextEditingController();
  final NumberFormat _numberFormat = NumberFormat('#,##0.00');
  bool _isEurToKrw = true; // 변환 방향 (EUR -> KRW 또는 KRW -> EUR)

  @override
  void dispose() {
    _eurController.dispose();
    _krwController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // 화면이 처음 로드될 때 환율 정보 가져오기
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final service = Provider.of<CurrencyService>(context, listen: false);
      service.fetchCurrencyData().then((_) {
        // 환율 정보가 로드되면 초기값 1유로에 대한 원화 계산
        if (service.eurToKrwData != null) {
          _onEurChanged('1.00', service);
        }
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Provider가 업데이트될 때마다 초기값 설정
    final service = Provider.of<CurrencyService>(context, listen: false);
    if (service.eurToKrwData != null && _isEurToKrw) {
      _onEurChanged(_eurController.text, service);
    }
  }

  // 유로 입력값이 변경될 때 호출
  void _onEurChanged(String value, CurrencyService service) {
    if (value.isEmpty) {
      _krwController.text = '';
      return;
    }

    try {
      final double eurAmount = double.parse(value.replaceAll(',', ''));
      final double krwAmount = service.convertEurToKrw(eurAmount);
      _krwController.text = _numberFormat.format(krwAmount);
    } catch (e) {
      // 숫자 변환 오류 처리
      _krwController.text = '';
    }
  }

  // 원화 입력값이 변경될 때 호출
  void _onKrwChanged(String value, CurrencyService service) {
    if (value.isEmpty) {
      _eurController.text = '';
      return;
    }

    try {
      final double krwAmount = double.parse(value.replaceAll(',', ''));
      final double eurAmount = service.convertKrwToEur(krwAmount);
      _eurController.text = _numberFormat.format(eurAmount);
    } catch (e) {
      // 숫자 변환 오류 처리
      _eurController.text = '';
    }
  }

  // 변환 방향 전환
  void _toggleConversionDirection() {
    setState(() {
      _isEurToKrw = !_isEurToKrw;
      // 입력값 초기화 및 기본값 설정
      if (_isEurToKrw) {
        _eurController.text = '1.00';
        final service = Provider.of<CurrencyService>(context, listen: false);
        _onEurChanged('1.00', service);
      } else {
        _krwController.text = '';
        _eurController.text = '';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final currencyService = Provider.of<CurrencyService>(context);
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '환율 변환기',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.swap_vert),
                  tooltip: '변환 방향 전환',
                  onPressed: _toggleConversionDirection,
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // 첫 번째 통화 입력 필드
            if (_isEurToKrw) ...[
              _buildCurrencyField(
                label: '유로 (EUR)',
                controller: _eurController,
                currencySymbol: '€',
                onChanged: (value) => _onEurChanged(value, currencyService),
                enabled: true,
              ),
              const SizedBox(height: 16),
              _buildCurrencyField(
                label: '원화 (KRW)',
                controller: _krwController,
                currencySymbol: '₩',
                onChanged: (_) {}, // 읽기 전용
                enabled: false,
              ),
            ] else ...[
              _buildCurrencyField(
                label: '원화 (KRW)',
                controller: _krwController,
                currencySymbol: '₩',
                onChanged: (value) => _onKrwChanged(value, currencyService),
                enabled: true,
              ),
              const SizedBox(height: 16),
              _buildCurrencyField(
                label: '유로 (EUR)',
                controller: _eurController,
                currencySymbol: '€',
                onChanged: (_) {}, // 읽기 전용
                enabled: false,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCurrencyField({
    required String label,
    required TextEditingController controller,
    required String currencySymbol,
    required Function(String) onChanged,
    required bool enabled,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          enabled: enabled,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
          ],
          onChanged: onChanged,
          decoration: InputDecoration(
            prefixText: '$currencySymbol ',
            border: const OutlineInputBorder(),
            filled: !enabled,
            fillColor: enabled ? null : Colors.grey.shade100,
          ),
          style: TextStyle(
            color: enabled ? Colors.black : Colors.grey.shade700,
          ),
        ),
      ],
    );
  }
}
