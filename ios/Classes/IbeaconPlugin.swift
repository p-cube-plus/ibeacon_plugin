import UIKit
import CoreLocation
import CoreBluetooth
import Flutter

public class IBeaconPlugin: NSObject, FlutterPlugin, CLLocationManagerDelegate, FlutterStreamHandler {
    private var methodChannel: FlutterMethodChannel!
    private var eventChannel: FlutterEventChannel!
    private var eventSink: FlutterEventSink?
    private var locationManager: CLLocationManager!
    private var region: CLBeaconRegion?

    private enum Constants {
        static let methodChannelName = "ibeacon_plugin/methods"
        static let eventChannelName = "ibeacon_plugin/events"
        static let logTag = "비콘 플러그인"
        static let bluetoothNotEnabledError = "BluetoothNotEnabledException"
        static let regionNotSetError = "RegionNotSetException"
    }

    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = IBeaconPlugin()
        instance.methodChannel = FlutterMethodChannel(name: Constants.methodChannelName, binaryMessenger: registrar.messenger())
        instance.eventChannel = FlutterEventChannel(name: Constants.eventChannelName, binaryMessenger: registrar.messenger())
        
        registrar.addMethodCallDelegate(instance, channel: instance.methodChannel)
        instance.eventChannel.setStreamHandler(instance)
        
        instance.locationManager = CLLocationManager()
        instance.locationManager.delegate = instance
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "setRegion":
            guard let args = call.arguments as? [String: Any],
                  let identifier = args["identifier"] as? String,
                  let uuid = args["uuid"] as? String else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Arguments missing", details: nil))
                return
            }

            let major = args["major"] as? NSNumber
            let minor = args["minor"] as? NSNumber
            
            if #available(iOS 13.0, *) {
                createRegion(identifier: identifier, uuid: uuid, major: major, minor: minor)
            }
            result(nil)

        case "startMonitoring":
            guard let region = region else {
                result(FlutterError(code: Constants.regionNotSetError, message: "startMonitoring을 부르기 전에 setRegion을 먼저 호출해야 합니다.", details: nil))
                return
            }

            let authStatus = CLLocationManager.authorizationStatus()
            if authStatus == .notDetermined {
                locationManager.requestWhenInUseAuthorization()
                result(FlutterError(code: "PERMISSION_NOT_GRANTED", message: "위치 권한이 아직 부여되지 않았습니다. 권한 승인 후 다시 시도하세요.", details: nil))
                return
            }

            if authStatus != .authorizedWhenInUse {
                result(FlutterError(code: "PERMISSION_DENIED", message: "위치 권한이 필요합니다.", details: nil))
                return
            }

            if CLLocationManager.authorizationStatus() != .authorizedWhenInUse {
                locationManager.requestWhenInUseAuthorization()
            }

            print("\(Constants.logTag): 비콘 모니터링 시작 \(region.identifier)")
            locationManager.startMonitoring(for: region)
            locationManager.requestState(for: region)

            result(nil)

        case "stopMonitoring":
            guard let region = region else {
                result(FlutterError(code: Constants.regionNotSetError, message: "stopMonitoring을 부르기 전에 setRegion을 먼저 호출해야 합니다.", details: nil))
                return
            }

            print("\(Constants.logTag): 비콘 모니터링 종료 \(region.identifier)")
            locationManager.stopMonitoring(for: region)
            postEvent(false)
            result(nil)

        case "isBluetoothEnabled":
            let centralManager = CBCentralManager(delegate: nil, queue: nil)
            let isBluetoothEnabled = (centralManager.state == .poweredOn)
            print("\(Constants.logTag): 블루투스 활성화 상태: \(isBluetoothEnabled)")

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        eventSink = events
        print("\(Constants.logTag): 이벤트 채널 listen 시작")
        return nil
    }

    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        eventSink = nil
        print("\(Constants.logTag): 이벤트 채널 cancel")
        return nil
    }
    
    @available (iOS 13.0, *)
    private func createRegion(identifier: String, uuid: String, major: NSNumber?, minor: NSNumber?) {
        let beaconUUID = UUID(uuidString: uuid)!
        region = CLBeaconRegion(uuid: beaconUUID, major: major?.uint16Value ?? 0, minor: minor?.uint16Value ?? 0, identifier: identifier)
        region?.notifyOnEntry = true
        region?.notifyOnExit = true
        print("\(Constants.logTag): region 설정 완료 \(region!.identifier)")
    }

    private func postEvent(_ state: Bool) {
        DispatchQueue.main.async {
            self.eventSink?(state)
        }
    }

    public func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion) {
        print("\(Constants.logTag): 비콘 모니터링 시작됨 \(region.identifier)")
        manager.requestState(for: region)  // 현재 상태 요청
    }

    public func locationManager(_ manager: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion) {
        if state == .inside {
            print("\(Constants.logTag): 이미 비콘 영역 안에 있음 \(region.identifier)")
            postEvent(true)
        } else {
            print("\(Constants.logTag): 비콘 영역 밖에 있음 \(region.identifier)")
            postEvent(false)
        }
    }
}
