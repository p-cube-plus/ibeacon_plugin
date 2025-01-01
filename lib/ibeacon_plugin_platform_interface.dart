import 'package:ibeacon_plugin/beacon_monitoring_state.dart';
import 'package:ibeacon_plugin/region.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'ibeacon_plugin_method_channel.dart';

abstract class IBeaconPluginPlatform extends PlatformInterface {
  IBeaconPluginPlatform() : super(token: _token);

  static final Object _token = Object();

  static IBeaconPluginPlatform _instance = MethodChannelIBeaconPlugin();
  static IBeaconPluginPlatform get instance => _instance;

  static set instance(IBeaconPluginPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<void> setRegion(Region region);

  Future<void> startMonitoring();

  Future<void> stopMonitoring();

  Stream<BeaconMonitoringState> getMonitoringStream();

  Future<bool> isBluetoothEnabled();
}
