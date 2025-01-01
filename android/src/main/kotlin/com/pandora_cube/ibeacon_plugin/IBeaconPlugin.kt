package com.pandora_cube.ibeacon_plugin

import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.util.Log
import android.os.Handler
import android.os.Looper

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler

import org.altbeacon.beacon.BeaconManager
import org.altbeacon.beacon.BeaconParser
import org.altbeacon.beacon.MonitorNotifier
import org.altbeacon.beacon.Region
import org.altbeacon.beacon.Identifier

// https://altbeacon.github.io/android-beacon-library/autobind.html
class IBeaconPlugin : FlutterPlugin, MethodCallHandler {

    private lateinit var methodChannel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private lateinit var bluetoothManager: BluetoothManager
    private var eventSink: EventChannel.EventSink? = null

    private val uiThreadHandler = Handler(Looper.getMainLooper())

    private var beaconManager: BeaconManager? = null
    private var region: Region? = null

    companion object {
        const val I_BEACON_LAYOUT = "m:2-3=0215,i:4-19,i:20-21,i:22-23,p:24-24,d:25-25"
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
        return bluetoothManager.adapter.isEnabled
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

        val filter = IntentFilter(BluetoothAdapter.ACTION_STATE_CHANGED)
        binding.applicationContext.registerReceiver(bluetoothStateReceiver, filter)

        bluetoothManager = binding.applicationContext.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager

        beaconManager = BeaconManager.getInstanceForApplication(binding.applicationContext).apply {
            beaconParsers.add(BeaconParser().setBeaconLayout(I_BEACON_LAYOUT))
            addMonitorNotifier(object : MonitorNotifier {
                override fun didEnterRegion(region: Region?) {
                    uiThreadHandler.post {
                        eventSink?.success(true)
                    }
                    Log.d(LOG_TAG, "비콘 INSIDE")
                }

                override fun didExitRegion(region: Region?) {
                    val isEnabled = isBluetoothEnabled()
                    if (!isEnabled) {
                        this@IBeaconPlugin.region?.let {
                            Log.d(LOG_TAG, "비콘 모니터링 종료 $it")
                            beaconManager?.stopMonitoring(it)
                        }
                    }

                    uiThreadHandler.post {
                        eventSink?.success(false)
                    }
                    Log.d(LOG_TAG, "비콘 OUTSIDE")
                }

                override fun didDetermineStateForRegion(state: Int, region: Region?) {}
            })
            setEnableScheduledScanJobs(false)
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
        beaconManager?.apply {
            removeAllMonitorNotifiers()
        }
        beaconManager = null
        binding.applicationContext.unregisterReceiver(bluetoothStateReceiver)
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
                Log.d(LOG_TAG, "region 설정 완료 $region")
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

                Log.d(LOG_TAG, "비콘 모니터링 시작 $region")
                beaconManager?.startMonitoring(region!!)
                result.success(null)
            }

            STOP_MONITORING_METHOD -> {
                if (!isScanning()) {
                    result.success(null)
                    return
                }

                if (region == null) {
                    result.error(ErrorCodes.REGION_NOT_SET, "stopMonitoring을 부르기 전에 $SET_REGION_METHOD 을 먼저 불러야 합니다.", null)
                    return
                }

                stopBeaconMonitoring()
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

    private fun stopBeaconMonitoring() {
        region?.let {
            Log.d(LOG_TAG, "비콘 모니터링 종료 $it")
            beaconManager?.stopMonitoring(it)
        }

        uiThreadHandler.post {
            eventSink?.success(false)
        }
    }

    private val bluetoothStateReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            if (intent.action == BluetoothAdapter.ACTION_STATE_CHANGED) {
                val state = intent.getIntExtra(BluetoothAdapter.EXTRA_STATE, BluetoothAdapter.ERROR)
                when (state) {
                    BluetoothAdapter.STATE_OFF -> {
                        Log.d(LOG_TAG, "블루투스가 비활성화되었습니다.")
                        stopBeaconMonitoring()
                    }
                    BluetoothAdapter.STATE_ON -> {
                        Log.d(LOG_TAG, "블루투스가 활성화되었습니다.")
                    }
                }
            }
        }
    }
}
