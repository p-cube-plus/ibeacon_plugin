import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:ibeacon_plugin/beacon_monitoring_state.dart';
import 'package:ibeacon_plugin/region.dart';

import 'ibeacon_plugin_platform_interface.dart';

class MethodChannelIbeaconPlugin extends IbeaconPluginPlatform {
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
    );
  }

  @override
  Future<void> startMonitoring() async {
    await methodChannel.invokeMethod('startMonitoring');
  }

  @override
  Future<void> stopMonitoring() async {
    await methodChannel.invokeMethod('stopMonitoring');
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
}
