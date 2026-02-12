import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'base_command.dart';

final commandProcessorProvider = Provider((ref) => CommandProcessor());

class CommandProcessor {
  final List<CommandLog> _logs = [];
  final List<BaseCommand> _history = [];

  List<CommandLog> get logs => List.unmodifiable(_logs);

  Future<void> process(BaseCommand command) async {
    try {
      // For debugging/logging
      _log('[Command] Executed: ${command.runtimeType}');
      await command.execute();
      _history.add(command);
      _logs.add(
        CommandLog(
          commandName: command.name,
          timestamp: DateTime.now(),
          success: true,
        ),
      );
    } catch (e, stack) {
      _log("Command Failed: $e\n$stack");
      _logs.add(
        CommandLog(
          commandName: command.name,
          timestamp: DateTime.now(),
          success: false,
          error: e.toString(),
        ),
      );
      rethrow;
    }
  }

  void _log(String message) {
    debugPrint("[CommandProcessor] $message");
  }
}
