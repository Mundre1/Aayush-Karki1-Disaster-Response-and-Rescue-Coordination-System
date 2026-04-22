import 'package:disaster_response_mobile/features/auth/models/user_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('UT-DART-01 UserModel.fromJson parses snake_case and role map', () {
    print('[UT-DART-01] Starting UserModel.fromJson parsing test');
    final json = {
      'user_id': '42',
      'name': 'Ayush',
      'email': 'ayush@example.com',
      'role_id': 2,
      'role': {'roleName': 'volunteer'},
    };

    final user = UserModel.fromJson(json);

    expect(user.userId, 42);
    expect(user.roleId, 2);
    expect(user.roleName, 'volunteer');
    print('[UT-DART-01] Completed successfully');
  });
}
