import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../models/currency_data.dart';
import '../models/currency_chart_data.dart';

class CurrencyService extends ChangeNotifier {
  CurrencyData? _eurToKrwData;
  bool _isLoading = false;
  String? _errorMessage;
  
  // 차트 데이터
  List<CurrencyChartData> _dailyChartData = [];
  List<CurrencyChartData> _monthlyChartData = [];
  List<CurrencyChartData> _yearlyChartData = [];
  ChartPeriod _selectedPeriod = ChartPeriod.day;
  bool _isChartLoading = false;

  CurrencyData? get eurToKrwData => _eurToKrwData;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  
  // 차트 데이터 getter
  List<CurrencyChartData> get dailyChartData => _dailyChartData;
  List<CurrencyChartData> get monthlyChartData => _monthlyChartData;
  List<CurrencyChartData> get yearlyChartData => _yearlyChartData;
  ChartPeriod get selectedPeriod => _selectedPeriod;
  bool get isChartLoading => _isChartLoading;
  
  // 현재 선택된 기간에 따른 차트 데이터 반환
  List<CurrencyChartData> get currentChartData {
    switch (_selectedPeriod) {
      case ChartPeriod.day:
        return _dailyChartData;
      case ChartPeriod.month:
        return _monthlyChartData;
      case ChartPeriod.year:
        return _yearlyChartData;
    }
  }

  // 선택된 기간 변경
  void setChartPeriod(ChartPeriod period) {
    _selectedPeriod = period;
    notifyListeners();
  }

  // 환율 정보 가져오기
  Future<void> fetchCurrencyData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 환율 API에서 데이터 가져오기
      // 여기서는 예시로 Open Exchange Rates API를 사용합니다
      // 실제 사용 시에는 API 키가 필요합니다
      final response = await http.get(
        Uri.parse('https://open.er-api.com/v6/latest/EUR'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final rates = data['rates'];
        final krwRate = rates['KRW'];
        final timestamp = data['time_last_update_unix'];

        _eurToKrwData = CurrencyData(
          fromCurrency: 'EUR',
          toCurrency: 'KRW',
          rate: krwRate.toDouble(),
          lastUpdated: DateTime.fromMillisecondsSinceEpoch(timestamp * 1000),
        );
        _errorMessage = null;
      } else {
        _errorMessage = '환율 정보를 가져오는데 실패했습니다. 상태 코드: ${response.statusCode}';
      }
    } catch (e) {
      _errorMessage = '환율 정보를 가져오는데 실패했습니다: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
      
      // 환율 정보를 가져온 후 차트 데이터도 가져옴
      fetchChartData();
    }
  }
  
  // 차트 데이터 가져오기 - 한 번만 생성하도록 수정
  Future<void> fetchChartData() async {
    // 이미 데이터가 있으면 새로 로딩하지 않음
    if (_dailyChartData.isNotEmpty && _monthlyChartData.isNotEmpty && _yearlyChartData.isNotEmpty) {
      return;
    }
    
    _isChartLoading = true;
    notifyListeners();
    
    try {
      // 실제 API에서는 과거 데이터를 가져와야 하지만,
      // 예시를 위해 가상의 데이터를 생성합니다.
      // 로딩 시뮬레이션 제거 - 깨박거림 방지
      
      final now = DateTime.now();
      final baseRate = _eurToKrwData?.rate ?? 1400.0;
      final random = Random(42); // 고정된 시드를 사용하여 매번 다른 랜덤 값 방지
      
      // 일간 데이터 생성 (24시간)
      _dailyChartData = List.generate(24, (index) {
        final date = now.subtract(Duration(hours: 23 - index));
        // 기준 환율에서 ±1% 범위 내의 랜덤 변동
        final randomFactor = 0.98 + (random.nextDouble() * 0.04);
        return CurrencyChartData(
          date: date,
          rate: baseRate * randomFactor,
        );
      });
      
      // 월간 데이터 생성 (30일)
      _monthlyChartData = List.generate(30, (index) {
        final date = now.subtract(Duration(days: 29 - index));
        // 기준 환율에서 ±3% 범위 내의 랜덤 변동
        final randomFactor = 0.97 + (random.nextDouble() * 0.06);
        return CurrencyChartData(
          date: date,
          rate: baseRate * randomFactor,
        );
      });
      
      // 년간 데이터 생성 (12개월)
      _yearlyChartData = List.generate(12, (index) {
        final date = DateTime(now.year, now.month - 11 + index, 1);
        // 기준 환율에서 ±5% 범위 내의 랜덤 변동
        final randomFactor = 0.95 + (random.nextDouble() * 0.10);
        return CurrencyChartData(
          date: date,
          rate: baseRate * randomFactor,
        );
      });
      
    } catch (e) {
      print('차트 데이터 로딩 오류: $e');
    } finally {
      _isChartLoading = false;
      notifyListeners();
    }
  }

  // 금액 변환 (EUR -> KRW)
  double convertEurToKrw(double eurAmount) {
    if (_eurToKrwData == null) return 0;
    return eurAmount * _eurToKrwData!.rate;
  }

  // 금액 변환 (KRW -> EUR)
  double convertKrwToEur(double krwAmount) {
    if (_eurToKrwData == null) return 0;
    return krwAmount / _eurToKrwData!.rate;
  }

  // 환율 정보 포맷팅
  String getFormattedRate() {
    if (_eurToKrwData == null) return 'N/A';
    final formatter = NumberFormat('#,##0.00');
    return '1 EUR = ${formatter.format(_eurToKrwData!.rate)} KRW';
  }

  // 마지막 업데이트 시간 포맷팅
  String getFormattedLastUpdated() {
    if (_eurToKrwData == null) return '';
    final formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
    return formatter.format(_eurToKrwData!.lastUpdated);
  }
}
