import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:ibeacon_plugin/beacon_monitoring_state.dart';
import 'package:ibeacon_plugin/ibeacon_plugin_exception.dart';
import 'package:ibeacon_plugin/region.dart';

import 'ibeacon_plugin_platform_interface.dart';

class MethodChannelIBeaconPlugin extends IBeaconPluginPlatform {
  @visibleForTesting
  final methodChannel = const MethodChannel('ibeacon_plugin/methods');
  @visibleForTesting
  final eventChannel = const EventChannel('ibeacon_plugin/events');

  @override
  Future<void> setRegion(Region region) async {
    await methodChannel.invokeMethod(
      'setRegion',
      {
        'identifier': region.identifier,
        'uuid': region.uuid,
        'major': region.major,
        'minor': region.minor,
      },
    ).catchError((e) {
      (e as PlatformException).throwCustomException();
    });
  }

  @override
  Future<void> startMonitoring() async {
    return methodChannel.invokeMethod('startMonitoring').catchError((e) {
      (e as PlatformException).throwCustomException();
    });
  }

  @override
  Future<void> stopMonitoring() {
    return methodChannel.invokeMethod('stopMonitoring').catchError((e) {
      (e as PlatformException).throwCustomException();
    });
  }

  @override
  Stream<BeaconMonitoringState> getMonitoringStream() {
    return eventChannel.receiveBroadcastStream().map((event) {
      final isInside = event as bool;
      return isInside
          ? BeaconMonitoringState.inside
          : BeaconMonitoringState.outside;
    });
  }

  @override
  Future<bool> isBluetoothEnabled() async {
    try {
      final isBluetoothEnabled =
          await methodChannel.invokeMethod<bool>('isBluetoothEnabled');
      return isBluetoothEnabled ?? false;
    } on PlatformException catch (e) {
      e.throwCustomException();
    }
    return false;
  }
}
