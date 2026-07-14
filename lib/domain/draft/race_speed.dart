/// How long the animated portion of The Race lasts (the countdown is separate).
enum RaceSpeed {
  lightning('lightning', 'Lightning', 5),
  fast('fast', 'Fast', 10),
  medium('medium', 'Medium', 20),
  slow('slow', 'Slow', 45),
  tortoise('tortoise', 'Tortoise', 60);

  const RaceSpeed(this.code, this.label, this.seconds);

  final String code;
  final String label;
  final int seconds;

  Duration get duration => Duration(seconds: seconds);

  static RaceSpeed fromCode(String? code) => values.firstWhere(
    (speed) => speed.code == code,
    orElse: () => RaceSpeed.medium,
  );
}
