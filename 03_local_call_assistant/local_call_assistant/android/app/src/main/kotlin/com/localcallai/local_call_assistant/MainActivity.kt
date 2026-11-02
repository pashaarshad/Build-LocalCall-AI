package com.localcallai.local_call_assistant

import android.content.Context
import android.content.Intent
import android.media.AudioManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.telecom.TelecomManager
import android.telephony.TelephonyManager
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.localcallai.call_assistant/telephony"
    private var methodChannel: MethodChannel? = null

    companion object {
        private const val TAG = "LocalCallMainActivity"
        var instance: MainActivity? = null
        var isAttendantActive: Boolean = true
        var ringsThreshold: Int = 3
        private var ringCounter: Int = 0
        private var autoAnswerHandler: Handler? = null
        private var autoAnswerRunnable: Runnable? = null
        private var currentRingingNumber: String? = null

        fun onPhoneStateChanged(context: Context, state: String?, incomingNumber: String?) {
            Log.d(TAG, "Phone State: $state, Number: $incomingNumber, AttendantActive: $isAttendantActive")

            when (state) {
                TelephonyManager.EXTRA_STATE_RINGING -> {
                    currentRingingNumber = incomingNumber ?: "Unknown Caller"
                    ringCounter++
                    Log.d(TAG, "Ring detected: $ringCounter/$ringsThreshold")

                    instance?.runOnUiThread {
                        instance?.methodChannel?.invokeMethod("onIncomingCallRinging", mapOf(
                            "number" to currentRingingNumber,
                            "ringCount" to ringCounter
                        ))
                    }

                    // Start auto-answer timer on 1st ring (each ring cadence is ~3 seconds, 3 rings = ~8.5 seconds)
                    if (ringCounter == 1 && isAttendantActive) {
                        autoAnswerHandler?.removeCallbacksAndMessages(null)
                        autoAnswerHandler = Handler(Looper.getMainLooper())
                        autoAnswerRunnable = Runnable {
                            Log.d(TAG, "3 rings completed without user intervention. Auto-answering call...")
                            answerCall(context)
                        }
                        // 8500 ms represents ~3 full rings
                        autoAnswerHandler?.postDelayed(autoAnswerRunnable!!, 8500)
                    }
                }

                TelephonyManager.EXTRA_STATE_OFFHOOK -> {
                    Log.d(TAG, "Call answered (OFFHOOK)")
                    autoAnswerHandler?.removeCallbacksAndMessages(null)
                    ringCounter = 0
                }

                TelephonyManager.EXTRA_STATE_IDLE -> {
                    Log.d(TAG, "Call ended or missed (IDLE)")
                    autoAnswerHandler?.removeCallbacksAndMessages(null)
                    ringCounter = 0
                    currentRingingNumber = null

                    instance?.runOnUiThread {
                        instance?.methodChannel?.invokeMethod("onCallEnded", null)
                    }
                }
            }
        }

        private fun answerCall(context: Context) {
            try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    val telecomManager = context.getSystemService(Context.TELECOM_SERVICE) as? TelecomManager
                    if (telecomManager != null) {
                        telecomManager.acceptRingingCall()
                        Log.d(TAG, "acceptRingingCall called successfully")

                        // Enable speakerphone so AI voice and microphone interact clearly
                        val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as? AudioManager
                        audioManager?.mode = AudioManager.MODE_IN_COMMUNICATION
                        audioManager?.isSpeakerphoneOn = true

                        // Bring app to foreground
                        val intent = Intent(context, MainActivity::class.java).apply {
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_REORDER_TO_FRONT)
                            putExtra("caller_number", currentRingingNumber)
                            putExtra("auto_answered", true)
                        }
                        context.startActivity(intent)

                        // Notify Flutter
                        instance?.runOnUiThread {
                            instance?.methodChannel?.invokeMethod("onIncomingCallAnswered", mapOf(
                                "number" to (currentRingingNumber ?: "Unknown Caller")
                            ))
                        }
                    }
                }
            } catch (e: SecurityException) {
                Log.e(TAG, "SecurityException answering call: ${e.message}")
            } catch (e: Exception) {
                Log.e(TAG, "Error answering call: ${e.message}")
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        instance = this
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)

        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "setAttendantActive" -> {
                    isAttendantActive = call.argument<Boolean>("isActive") ?: true
                    result.success(true)
                }
                "setRingsThreshold" -> {
                    ringsThreshold = call.argument<Int>("threshold") ?: 3
                    result.success(true)
                }
                "triggerManualAnswer" -> {
                    answerCall(this)
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onDestroy() {
        instance = null
        super.onDestroy()
    }
}
