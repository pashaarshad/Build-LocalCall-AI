import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class TelephonyNativeService {
  static const MethodChannel _channel = MethodChannel('com.localcallai.call_assistant/telephony');

  Function(String number, int ringCount)? onIncomingCallRinging;
  Function(String number)? onIncomingCallAnswered;
  VoidCallback? onCallEnded;

  TelephonyNativeService() {
    _channel.setMethodCallHandler(_handleNativeCall);
  }

  Future<dynamic> _handleNativeCall(MethodCall call) async {
    debugPrint('Native Telephony event: ${call.method}');
    switch (call.method) {
      case 'onIncomingCallRinging':
        final map = call.arguments as Map<dynamic, dynamic>?;
        final number = map?['number'] as String? ?? 'Unknown Caller';
        final ringCount = map?['ringCount'] as int? ?? 1;
        onIncomingCallRinging?.call(number, ringCount);
        break;

      case 'onIncomingCallAnswered':
        final map = call.arguments as Map<dynamic, dynamic>?;
        final number = map?['number'] as String? ?? 'Unknown Caller';
        onIncomingCallAnswered?.call(number);
        break;

      case 'onCallEnded':
        onCallEnded?.call();
        break;
    }
  }

  Future<void> setAttendantActive(bool isActive) async {
    try {
      await _channel.invokeMethod('setAttendantActive', {'isActive': isActive});
    } catch (e) {
      debugPrint('Error setting attendant active native: $e');
    }
  }

  Future<void> setRingsThreshold(int threshold) async {
    try {
      await _channel.invokeMethod('setRingsThreshold', {'threshold': threshold});
    } catch (e) {
      debugPrint('Error setting ring threshold native: $e');
    }
  }
}
