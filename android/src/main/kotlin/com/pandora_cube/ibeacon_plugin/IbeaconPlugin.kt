package com.pandora_cube.ibeacon_plugin

import android.bluetooth.BluetoothAdapter
import android.util.Log;
import android.app.Activity;
import android.content.Context;
import android.content.ServiceConnection;
import android.content.Intent;
import android.os.Handler
import android.os.Looper

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

import org.altbeacon.beacon.BeaconConsumer;
import org.altbeacon.beacon.BeaconManager;
import org.altbeacon.beacon.BeaconParser;
import org.altbeacon.beacon.MonitorNotifier;
import org.altbeacon.beacon.Region;
import org.altbeacon.beacon.Identifier;

// https://altbeacon.github.io/android-beacon-library/autobind.html
class IbeaconPlugin : FlutterPlugin, MethodCallHandler {

    private lateinit var methodChannel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private var eventSink: EventChannel.EventSink? = null

    private val uiThreadHandler = Handler(Looper.getMainLooper())

    private var beaconManager: BeaconManager? = null
    private var region: Region? = null

    companion object {
        const val IBEACON_LAYOUT = "m:2-3=0215,i:4-19,i:20-21,i:22-23,p:24-24,d:25-25"
        const val METHOD_CHANNEL_NAME = "ibeacon_plugin/methods"
        const val EVENT_CHANNEL_NAME = "ibeacon_plugin/events"

        const val SET_REGION_METHOD = "setRegion"
        const val START_MONITORING_METHOD = "startMonitoring"
        const val STOP_MONITORING_METHOD = "stopMonitoring"
        const val CHECK_BLUETOOTH_METHOD = "isBluetoothEnabled"

        const val LOG_TAG = "비콘 플러그인"
    }

    object ErrorCodes {
        const val REGION_NOT_SET = "RegionNotSetException"
        const val BLUETOOTH_NOT_ENABLED = "BluetoothNotEnabledException"
    }

    private fun isScanning(): Boolean {
        return beaconManager?.monitoredRegions?.isNotEmpty() == true
    }

    private fun isBluetoothEnabled(): Boolean {
        val bluetoothAdapter = BluetoothAdapter.getDefaultAdapter()
        return bluetoothAdapter?.isEnabled == true
    }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel = MethodChannel(binding.binaryMessenger, METHOD_CHANNEL_NAME)
        eventChannel = EventChannel(binding.binaryMessenger, EVENT_CHANNEL_NAME)

        methodChannel.setMethodCallHandler(this)
        eventChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                eventSink = events
                Log.d(LOG_TAG, "이벤트 채널 listen 시작")
            }

            override fun onCancel(arguments: Any?) {
                eventSink = null
                Log.d(LOG_TAG, "이벤트 채널 cancel")
            }
        })

        beaconManager = BeaconManager.getInstanceForApplication(binding.applicationContext).apply {
            beaconParsers.add(BeaconParser().setBeaconLayout(IBEACON_LAYOUT))
            addMonitorNotifier(object : MonitorNotifier {
                override fun didEnterRegion(region: Region?) {
                    uiThreadHandler.post {
                        eventSink?.success(true)
                    }
                }

                override fun didExitRegion(region: Region?) {
                    uiThreadHandler.post {
                        eventSink?.success(false)
                    }
                }

                override fun didDetermineStateForRegion(state: Int, region: Region?) {
                    if (state == MonitorNotifier.INSIDE) {
                        Log.d(LOG_TAG, "비콘 INSIDE")
                    } else if (state == MonitorNotifier.OUTSIDE) {
                        Log.d(LOG_TAG, "비콘 OUTSIDE")
                    }
                }
            })
            setEnableScheduledScanJobs(false)
            setBackgroundScanPeriod(0L)
            setBackgroundBetweenScanPeriod(0L)
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
        beaconManager?.apply {
            removeAllMonitorNotifiers()
        }
        beaconManager = null
        eventSink = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            SET_REGION_METHOD -> {
                val identifier = call.argument<String>("identifier")
                val uuid = call.argument<String>("uuid")
                val major = call.argument<Int>("major")
                val minor = call.argument<Int>("minor")

                region = Region(
                    identifier,
                    Identifier.parse(uuid),
                    major?.let { Identifier.fromInt(it) },
                    minor?.let { Identifier.fromInt(it) })
                result.success(null)
                Log.d(LOG_TAG, "region 설정 완료 ${region}")
            }

            START_MONITORING_METHOD -> {
                if (isScanning()) {
                    result.success(null)
                    return
                }

                val isEnabled = isBluetoothEnabled()
                if (!isEnabled) {
                    result.error(ErrorCodes.BLUETOOTH_NOT_ENABLED, "블루투스가 꺼져있습니다.", null)
                    return
                }

                if (region == null) {
                    result.error(ErrorCodes.REGION_NOT_SET, "startMonitoring을 부르기 전에 ${SET_REGION_METHOD} 을 먼저 불러야 합니다.", null)
                    return
                }

                Log.d(LOG_TAG, "비콘 모니터링 시작 ${region!!}")
                beaconManager?.startMonitoring(region!!)
                result.success(null)
            }

            STOP_MONITORING_METHOD -> {
                if (!isScanning()) {
                    result.success(null)
                    return
                }

                if (region == null) {
                    result.error(ErrorCodes.REGION_NOT_SET, "stopMonitoring을 부르기 전에 ${SET_REGION_METHOD} 을 먼저 불러야 합니다.", null)
                    return
                }

                Log.d(LOG_TAG, "비콘 모니터링 종료 ${region!!}")
                beaconManager?.stopMonitoring(region!!)
                uiThreadHandler.post {
                    eventSink?.success(false)
                }
                result.success(null)
            }

            CHECK_BLUETOOTH_METHOD -> {
                val isEnabled = isBluetoothEnabled()
                result.success(isEnabled)
                Log.d(LOG_TAG, "블루투스 활성화 상태: $isEnabled")
            }

            else -> result.notImplemented()
        }
    }
}
