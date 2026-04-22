import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

class TestStateProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _error;
  int _items = 0;

  bool get isLoading => _isLoading;
  String? get error => _error;
  int get items => _items;

  Future<void> simulateSuccessFlow() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    await Future<void>.delayed(Duration.zero);

    _items = 3;
    _isLoading = false;
    notifyListeners();
  }
}

void main() {
  test('UT-DART-05 Dart provider state update flow', () async {
    print('[UT-DART-05] Starting provider state flow test');
    final provider = TestStateProvider();
    final states = <(bool, String?, int)>[];

    provider.addListener(() {
      states.add((provider.isLoading, provider.error, provider.items));
    });

    await provider.simulateSuccessFlow();

    expect(states.length, 2);
    expect(states.first.$1, isTrue);
    expect(states.first.$2, isNull);
    expect(states.first.$3, 0);

    expect(states.last.$1, isFalse);
    expect(states.last.$2, isNull);
    expect(states.last.$3, 3);
    print('[UT-DART-05] Completed successfully');
  });
}
