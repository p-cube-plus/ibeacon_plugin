import 'package:ibeacon_plugin/beacon_monitoring_state.dart';
import 'package:ibeacon_plugin/region.dart';

import 'ibeacon_plugin_platform_interface.dart';

class IbeaconPlugin {
  Future<void> setRegion(Region region) =>
      IbeaconPluginPlatform.instance.setRegion(region);

  Future<void> startMonitoring() =>
      IbeaconPluginPlatform.instance.startMonitoring();

  Future<void> stopMonitoring() =>
      IbeaconPluginPlatform.instance.stopMonitoring();

  Stream<BeaconMonitoringState> get monitoringStream =>
      IbeaconPluginPlatform.instance.getMonitoringStream();
}
