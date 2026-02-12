abstract class BaseCommand {
  String get id;
  String get name;
  DateTime get timestamp;

  Future<void> execute();
  Future<void> undo();

  Map<String, dynamic> toJson();
}

class CommandLog {
  final String commandName;
  final DateTime timestamp;
  final bool success;
  final String? error;

  CommandLog({
    required this.commandName,
    required this.timestamp,
    required this.success,
    this.error,
  });

  @override
  String toString() =>
      "[$timestamp] $commandName - ${success ? 'OK' : 'FAIL: $error'}";
}
