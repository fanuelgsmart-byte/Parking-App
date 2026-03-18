import 'package:flutter_test/flutter_test.dart';
import 'package:parkflow_manager/features/parking_session/domain/entities/parking_session.dart';

void main() {
  group('SessionStatus transitions', () {
    test('active can only transition to flaggedForCheckout', () {
      expect(
        SessionStatus.active.canTransitionTo(SessionStatus.flaggedForCheckout),
        isTrue,
      );
      expect(
        SessionStatus.active.canTransitionTo(SessionStatus.completed),
        isFalse,
      );
      expect(
        SessionStatus.active.canTransitionTo(SessionStatus.paymentPending),
        isFalse,
      );
    });

    test('paymentPending can recover to flagged or complete', () {
      expect(
        SessionStatus.paymentPending
            .canTransitionTo(SessionStatus.flaggedForCheckout),
        isTrue,
      );
      expect(
        SessionStatus.paymentPending.canTransitionTo(SessionStatus.completed),
        isTrue,
      );
    });

    test('completed is terminal', () {
      expect(
        SessionStatus.completed.canTransitionTo(SessionStatus.active),
        isFalse,
      );
      expect(
        SessionStatus.completed.canTransitionTo(SessionStatus.flaggedForCheckout),
        isFalse,
      );
      expect(
        SessionStatus.completed.canTransitionTo(SessionStatus.paymentPending),
        isFalse,
      );
    });
  });
}
