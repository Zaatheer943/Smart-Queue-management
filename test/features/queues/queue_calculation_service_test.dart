import 'package:flutter_test/flutter_test.dart';
import 'package:queuewise/features/queues/domain/services/queue_calculation_service.dart';

void main() {
  group('QueueCalculationService', () {
    group('calculatePeopleAhead', () {
      test('returns 0 when no one is ahead', () {
        final result = QueueCalculationService.calculatePeopleAhead(
          userTokenNumber: 1,
          waitingTokenNumbers: [1],
        );
        expect(result, 0);
      });

      test('returns correct count when people are ahead', () {
        final result = QueueCalculationService.calculatePeopleAhead(
          userTokenNumber: 5,
          waitingTokenNumbers: [1, 2, 3, 4, 5, 6],
        );
        expect(result, 4);
      });

      test('handles empty waiting list', () {
        final result = QueueCalculationService.calculatePeopleAhead(
          userTokenNumber: 1,
          waitingTokenNumbers: [],
        );
        expect(result, 0);
      });

      test('handles user with highest token number', () {
        final result = QueueCalculationService.calculatePeopleAhead(
          userTokenNumber: 10,
          waitingTokenNumbers: [1, 2, 3, 4, 5],
        );
        expect(result, 5);
      });
    });

    group('calculateEstimatedWait', () {
      test('returns 0 when no one is ahead', () {
        final result = QueueCalculationService.calculateEstimatedWait(
          peopleAhead: 0,
          averageServiceDuration: 5,
        );
        expect(result, 0);
      });

      test('returns 0 when average service duration is 0', () {
        final result = QueueCalculationService.calculateEstimatedWait(
          peopleAhead: 5,
          averageServiceDuration: 0,
        );
        expect(result, 0);
      });

      test('calculates correct wait time', () {
        final result = QueueCalculationService.calculateEstimatedWait(
          peopleAhead: 4,
          averageServiceDuration: 5,
        );
        expect(result, 20); // 4 * 5 = 20 minutes
      });

      test('handles large numbers', () {
        final result = QueueCalculationService.calculateEstimatedWait(
          peopleAhead: 100,
          averageServiceDuration: 3,
        );
        expect(result, 300); // 100 * 3 = 300 minutes
      });
    });

    group('calculateServiceDuration', () {
      test('calculates duration in minutes', () {
        final calledAt = DateTime(2024, 1, 1, 10, 0);
        final servedAt = DateTime(2024, 1, 1, 10, 5);
        
        final result = QueueCalculationService.calculateServiceDuration(
          calledAt: calledAt,
          servedAt: servedAt,
        );
        expect(result, 5);
      });

      test('handles duration less than a minute', () {
        final calledAt = DateTime(2024, 1, 1, 10, 0, 0);
        final servedAt = DateTime(2024, 1, 1, 10, 0, 30);
        
        final result = QueueCalculationService.calculateServiceDuration(
          calledAt: calledAt,
          servedAt: servedAt,
        );
        expect(result, 0); // Less than 1 minute
      });

      test('handles duration over an hour', () {
        final calledAt = DateTime(2024, 1, 1, 10, 0);
        final servedAt = DateTime(2024, 1, 1, 11, 30);
        
        final result = QueueCalculationService.calculateServiceDuration(
          calledAt: calledAt,
          servedAt: servedAt,
        );
        expect(result, 90); // 1 hour 30 minutes = 90 minutes
      });
    });

    group('calculateRollingAverage', () {
      test('returns new duration when no samples', () {
        final result = QueueCalculationService.calculateRollingAverage(
          currentAverage: 0,
          newDuration: 5,
          sampleCount: 0,
        );
        expect(result, 5);
      });

      test('calculates rolling average correctly', () {
        final result = QueueCalculationService.calculateRollingAverage(
          currentAverage: 5,
          newDuration: 7,
          sampleCount: 10,
        );
        expect(result, 5); // (5*10 + 7) / 11 = 57/11 = 5.18 -> 5
      });

      test('handles single sample', () {
        final result = QueueCalculationService.calculateRollingAverage(
          currentAverage: 5,
          newDuration: 10,
          sampleCount: 1,
        );
        expect(result, 7); // (5*1 + 10) / 2 = 7.5 -> 7
      });
    });

    group('formatTokenNumber', () {
      test('formats token number with default prefix', () {
        final result = QueueCalculationService.formatTokenNumber(23);
        expect(result, 'A-023');
      });

      test('formats token number with custom prefix', () {
        final result = QueueCalculationService.formatTokenNumber(45, prefix: 'B');
        expect(result, 'B-045');
      });

      test('pads single digit numbers', () {
        final result = QueueCalculationService.formatTokenNumber(5);
        expect(result, 'A-005');
      });

      test('handles large numbers', () {
        final result = QueueCalculationService.formatTokenNumber(999);
        expect(result, 'A-999');
      });
    });

    group('isValidStatusTransition', () {
      test('allows waiting to called', () {
        final result = QueueCalculationService.isValidStatusTransition(
          'waiting',
          'called',
        );
        expect(result, true);
      });

      test('allows waiting to cancelled', () {
        final result = QueueCalculationService.isValidStatusTransition(
          'waiting',
          'cancelled',
        );
        expect(result, true);
      });

      test('does not allow waiting to served', () {
        final result = QueueCalculationService.isValidStatusTransition(
          'waiting',
          'served',
        );
        expect(result, false);
      });

      test('allows called to serving', () {
        final result = QueueCalculationService.isValidStatusTransition(
          'called',
          'serving',
        );
        expect(result, true);
      });

      test('allows called to no_show', () {
        final result = QueueCalculationService.isValidStatusTransition(
          'called',
          'no_show',
        );
        expect(result, true);
      });

      test('does not allow transitions from terminal states', () {
        final result1 = QueueCalculationService.isValidStatusTransition(
          'served',
          'waiting',
        );
        final result2 = QueueCalculationService.isValidStatusTransition(
          'cancelled',
          'waiting',
        );
        final result3 = QueueCalculationService.isValidStatusTransition(
          'no_show',
          'waiting',
        );
        
        expect(result1, false);
        expect(result2, false);
        expect(result3, false);
      });

      test('handles invalid current status', () {
        final result = QueueCalculationService.isValidStatusTransition(
          'invalid',
          'called',
        );
        expect(result, false);
      });
    });
  });
}
