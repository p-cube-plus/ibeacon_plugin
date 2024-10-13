import UIKit
import CoreLocation
import Flutter

public class IbeaconPlugin: NSObject, FlutterPlugin, CLLocationManagerDelegate {
    private var channel: FlutterMethodChannel!
    private var eventChannel: FlutterEventChannel!
    private var eventSink: FlutterEventSink?
    private let locationManager = CLLocationManager()
    private var region: CLBeaconRegion?

    private enum Constants {
        static let methodChannelName = "ibeacon_plugin/methods"
        static let eventChannelName = "ibeacon_plugin/events"
        static let logTag = "비콘 플러그인"
    }

    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = IbeaconPlugin()
        instance.channel = FlutterMethodChannel(name: Constants.methodChannelName, binaryMessenger: registrar.messenger())
        instance.eventChannel = FlutterEventChannel(name: Constants.eventChannelName, binaryMessenger: registrar.messenger())
        
        registrar.addMethodCallDelegate(instance, channel: instance.channel)
        instance.eventChannel.setStreamHandler(instance)
        
        instance.locationManager.delegate = instance
    }

    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) {
        eventSink = events
        print("\(Constants.logTag): 이벤트 채널 listen 시작")
    }

    public func onCancel(withArguments arguments: Any?) {
        eventSink = nil
        print("\(Constants.logTag): 이벤트 채널 cancel")
    }

    private func createRegion(identifier: String, uuid: String, major: NSNumber?, minor: NSNumber?) {
        let beaconUUID = UUID(uuidString: uuid)!
        region = CLBeaconRegion(proximityUUID: beaconUUID, major: major?.uint16Value, minor: minor?.uint16Value, identifier: identifier)
        locationManager.startMonitoring(for: region!)
        print("\(Constants.logTag): region 설정 완료 \(region?.identifier ?? "")")
    }

    private func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        eventSink?("true")
        print("\(Constants.logTag): 비콘 (inside) \(region.identifier)")
    }

    private func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        eventSink?("false")
        print("\(Constants.logTag): 비콘 (outside) \(region.identifier)")
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "setRegion":
            guard let args = call.arguments as? [String: Any],
                  let identifier = args["identifier"] as? String,
                  let uuid = args["uuid"] as? String,
                  let major = args["major"] as? NSNumber,
                  let minor = args["minor"] as? NSNumber else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Arguments missing", details: nil))
                return
            }
            createRegion(identifier: identifier, uuid: uuid, major: major, minor: minor)
            result(nil)

        case "startMonitoring":
            guard let region = region else {
                result(FlutterError(code: Constants.logTag, message: "startMonitoring을 부르기 전에 setRegion을 먼저 불러야 합니다.", details: nil))
                return
            }
            print("\(Constants.logTag): 비콘 모니터링 시작 \(region.identifier)")
            locationManager.startMonitoring(for: region)
            result(nil)

        case "stopMonitoring":
            guard let region = region else {
                result(FlutterError(code: Constants.logTag, message: "stopMonitoring을 부르기 전에 setRegion을 먼저 불러야 합니다.", details: nil))
                return
            }
            print("\(Constants.logTag): 비콘 모니터링 종료")
            locationManager.stopMonitoring(for: region)
            eventSink?("false")
            result(nil)

        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
