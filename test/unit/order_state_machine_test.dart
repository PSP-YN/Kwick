import 'package:flutter_test/flutter_test.dart';
import 'package:kwick/shared/models/service_request.dart';

void main() {
  group('OrderStatus State Transitions & Rules', () {
    test('cancellable states match operational policy', () {
      expect(OrderStatus.requested.isCancellable, isTrue);
      expect(OrderStatus.reviewing.isCancellable, isTrue);
      expect(OrderStatus.assigned.isCancellable, isTrue);

      expect(OrderStatus.accepted.isCancellable, isFalse);
      expect(OrderStatus.travelling.isCancellable, isFalse);
      expect(OrderStatus.inProgress.isCancellable, isFalse);
      expect(OrderStatus.completed.isCancellable, isFalse);
      expect(OrderStatus.cancelled.isCancellable, isFalse);
    });

    test('active states identify ongoing jobs accurately', () {
      expect(OrderStatus.requested.isActive, isTrue);
      expect(OrderStatus.reviewing.isActive, isTrue);
      expect(OrderStatus.assigned.isActive, isTrue);
      expect(OrderStatus.accepted.isActive, isTrue);
      expect(OrderStatus.travelling.isActive, isTrue);
      expect(OrderStatus.inProgress.isActive, isTrue);

      expect(OrderStatus.completed.isActive, isFalse);
      expect(OrderStatus.cancelled.isActive, isFalse);
      expect(OrderStatus.disputed.isActive, isFalse);
    });

    test('parses from raw database string reliably', () {
      expect(OrderStatus.fromString('requested'), OrderStatus.requested);
      expect(OrderStatus.fromString('travelling'), OrderStatus.travelling);
      expect(OrderStatus.fromString('completed'), OrderStatus.completed);
      expect(OrderStatus.fromString('unknown_status'), OrderStatus.requested);
    });
  });
}
