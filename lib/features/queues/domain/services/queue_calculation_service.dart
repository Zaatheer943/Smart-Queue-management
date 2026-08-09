/// Queue calculation service for position and waiting time calculations
class QueueCalculationService {
  QueueCalculationService._();

  /// Calculate people ahead based on token number and waiting tokens
  static int calculatePeopleAhead({
    required int userTokenNumber,
    required List<int> waitingTokenNumbers,
  }) {
    return waitingTokenNumbers
        .where((tokenNumber) => tokenNumber < userTokenNumber)
        .length;
  }

  /// Calculate estimated waiting time
  static int calculateEstimatedWait({
    required int peopleAhead,
    required int averageServiceDuration,
  }) {
    if (peopleAhead <= 0) return 0;
    if (averageServiceDuration <= 0) return 0;
    return peopleAhead * averageServiceDuration;
  }

  /// Calculate service duration
  static int calculateServiceDuration({
    required DateTime calledAt,
    required DateTime servedAt,
  }) {
    final duration = servedAt.difference(calledAt);
    return duration.inMinutes;
  }

  /// Calculate rolling average service duration
  static int calculateRollingAverage({
    required int currentAverage,
    required int newDuration,
    required int sampleCount,
  }) {
    if (sampleCount <= 0) return newDuration;
    return ((currentAverage * sampleCount) + newDuration) ~/ (sampleCount + 1);
  }

  /// Format token number with prefix (e.g., A-023)
  static String formatTokenNumber(int tokenNumber, {String prefix = 'A'}) {
    return '$prefix-${tokenNumber.toString().padLeft(3, '0')}';
  }

  /// Validate token status transition
  static bool isValidStatusTransition(String currentStatus, String newStatus) {
    final validTransitions = {
      'waiting': ['called', 'cancelled'],
      'called': ['serving', 'no_show', 'cancelled'],
      'serving': ['served', 'cancelled'],
      'served': [], // Terminal state
      'cancelled': [], // Terminal state
      'no_show': [], // Terminal state
    };

    return validTransitions[currentStatus]?.contains(newStatus) ?? false;
  }
}
