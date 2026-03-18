import 'package:flutter_test/flutter_test.dart';
import 'package:parkflow_manager/core/session/app_session_context.dart';
import 'package:parkflow_manager/features/auth/domain/entities/user.dart';

void main() {
  group('AppSessionContext', () {
    test('requireLotId returns effective selected lot when present', () {
      const context = AppSessionContext(
        userId: 'u1',
        role: UserRole.manager,
        assignedLotId: 'lot-a',
        selectedLotId: 'lot-b',
      );

      expect(context.requireLotId(), 'lot-b');
    });

    test('requireLotId throws when no lot scope exists', () {
      const context = AppSessionContext(
        userId: 'u1',
        role: UserRole.employee,
        assignedLotId: null,
      );

      expect(
        context.requireLotId,
        throwsA(isA<MissingSessionContextException>()),
      );
    });
  });
}
