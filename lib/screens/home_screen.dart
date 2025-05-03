import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/currency_service.dart';
import '../widgets/currency_converter.dart';
import '../widgets/currency_chart.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // 데이터 로드를 위한 Future 객체
  Future<void>? _dataFuture;

  @override
  void initState() {
    super.initState();
  }
  
  // 데이터 로드 함수 - 처음 호출시에만 로드하고 이후에는 캐시된 Future 반환
  Future<void> _loadData(BuildContext context) {
    if (_dataFuture == null) {
      final service = Provider.of<CurrencyService>(context, listen: false);
      if (service.eurToKrwData == null) {
        _dataFuture = service.fetchCurrencyData();
      } else {
        _dataFuture = Future.value();
      }
    }
    return _dataFuture!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('환율 모니터'),
        centerTitle: true,
        elevation: 0,
      ),
      body: FutureBuilder<void>(
        // 처음 한 번만 데이터를 로드하고 그 후에는 캐시된 데이터 사용
        future: _loadData(context),
        builder: (context, snapshot) {
          final currencyService = Provider.of<CurrencyService>(context, listen: false);
          if (currencyService.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (currencyService.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 60,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    currencyService.errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => currencyService.fetchCurrencyData(),
                    child: const Text('다시 시도'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => currencyService.fetchCurrencyData(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 현재 환율 정보 카드
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '현재 환율',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            currencyService.getFormattedRate(),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '마지막 업데이트: ${currencyService.getFormattedLastUpdated()}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // 환율 변환기
                  const CurrencyConverter(),
                  
                  const SizedBox(height: 24),
                  
                  // 환율 변화 그래프
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '환율 변화 추이',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const CurrencyChart(),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // 정보 섹션
                  const Card(
                    elevation: 2,
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '알림',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            '이 앱은 Open Exchange Rates API를 사용하여 환율 정보를 제공합니다. '
                            '환율은 실시간으로 변동될 수 있으며, 참고용으로만 사용해 주세요.',
                            style: TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Provider.of<CurrencyService>(context, listen: false).fetchCurrencyData();
        },
        tooltip: '새로고침',
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
