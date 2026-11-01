import 'dart:convert';

enum CallStatus {
  incoming,
  connected,
  ended,
  rejected,
}

enum UrgencyLevel {
  low,
  medium,
  high,
}

class CallTurn {
  final String speaker; // 'caller' or 'assistant'
  final String text;
  final DateTime timestamp;
  final String? audioPath;

  CallTurn({
    required this.speaker,
    required this.text,
    required this.timestamp,
    this.audioPath,
  });

  Map<String, dynamic> toMap() => {
        'speaker': speaker,
        'text': text,
        'timestamp': timestamp.toIso8601String(),
        'audioPath': audioPath,
      };

  factory CallTurn.fromMap(Map<String, dynamic> map) => CallTurn(
        speaker: map['speaker'] as String,
        text: map['text'] as String,
        timestamp: DateTime.parse(map['timestamp'] as String),
        audioPath: map['audioPath'] as String?,
      );
}

class CallSession {
  final String id;
  final String callerName;
  final String callerNumber;
  final DateTime startTime;
  DateTime? endTime;
  CallStatus status;
  final List<CallTurn> turns;
  String? summary;
  List<String> actionItems;
  UrgencyLevel urgency;
  String language;

  CallSession({
    required this.id,
    required this.callerName,
    required this.callerNumber,
    required this.startTime,
    this.endTime,
    this.status = CallStatus.incoming,
    List<CallTurn>? turns,
    this.summary,
    List<String>? actionItems,
    this.urgency = UrgencyLevel.medium,
    this.language = 'kn_IN', // Kannada default
  })  : turns = turns ?? [],
        actionItems = actionItems ?? [];

  int get durationSeconds {
    final end = endTime ?? DateTime.now();
    return end.difference(startTime).inSeconds;
  }

  String get formattedDuration {
    final d = durationSeconds;
    final m = d ~/ 60;
    final s = d % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'callerName': callerName,
        'callerNumber': callerNumber,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime?.toIso8601String(),
        'status': status.name,
        'turns': turns.map((t) => t.toMap()).toList(),
        'summary': summary,
        'actionItems': actionItems,
        'urgency': urgency.name,
        'language': language,
      };

  factory CallSession.fromMap(Map<String, dynamic> map) => CallSession(
        id: map['id'] as String,
        callerName: map['callerName'] as String,
        callerNumber: map['callerNumber'] as String,
        startTime: DateTime.parse(map['startTime'] as String),
        endTime: map['endTime'] != null ? DateTime.parse(map['endTime'] as String) : null,
        status: CallStatus.values.firstWhere(
          (e) => e.name == map['status'],
          orElse: () => CallStatus.ended,
        ),
        turns: (map['turns'] as List<dynamic>?)
                ?.map((e) => CallTurn.fromMap(e as Map<String, dynamic>))
                .toList() ??
            [],
        summary: map['summary'] as String?,
        actionItems: (map['actionItems'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
        urgency: UrgencyLevel.values.firstWhere(
          (e) => e.name == map['urgency'],
          orElse: () => UrgencyLevel.medium,
        ),
        language: map['language'] as String? ?? 'kn_IN',
      );

  String toJson() => jsonEncode(toMap());
  factory CallSession.fromJson(String source) => CallSession.fromMap(jsonDecode(source) as Map<String, dynamic>);
}
