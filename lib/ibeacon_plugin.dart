import 'beacon_monitoring_state.dart';
import 'ibeacon_plugin_platform_interface.dart';
import 'region.dart';

class IBeaconPlugin {
  Future<void> setRegion(Region region) =>
      IBeaconPluginPlatform.instance.setRegion(region);

  Future<void> startMonitoring() =>
      IBeaconPluginPlatform.instance.startMonitoring();

  Future<void> stopMonitoring() =>
      IBeaconPluginPlatform.instance.stopMonitoring();

  Stream<BeaconMonitoringState> get monitoringStream =>
      IBeaconPluginPlatform.instance.getMonitoringStream();

  Future<bool> get isBluetoothEnabled =>
      IBeaconPluginPlatform.instance.isBluetoothEnabled();
}
