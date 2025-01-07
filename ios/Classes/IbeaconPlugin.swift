import UIKit
import CoreLocation
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
            createRegion(identifier: identifier, uuid: uuid, major: major, minor: minor)
            result(nil)

        case "startMonitoring":
            guard let region = region else {
                result(FlutterError(code: Constants.regionNotSetError, message: "startMonitoring을 부르기 전에 setRegion을 먼저 호출해야 합니다.", details: nil))
                return
            }

            if CLLocationManager.authorizationStatus() != .authorizedAlways {
                locationManager.requestAlwaysAuthorization()
            }

            print("\(Constants.logTag): 비콘 모니터링 시작 \(region.identifier)")
            locationManager.startMonitoring(for: region)
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
            let isBluetoothEnabled = CLLocationManager.isMonitoringAvailable(for: CLBeaconRegion.self)
            result(isBluetoothEnabled)
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

    public func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        postEvent(true)
        print("\(Constants.logTag): 비콘 INSIDE \(region.identifier)")
    }

    public func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        postEvent(false)
        print("\(Constants.logTag): 비콘 OUTSIDE \(region.identifier)")
    }
}
