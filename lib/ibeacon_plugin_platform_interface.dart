import 'package:ibeacon_plugin/beacon_monitoring_state.dart';
import 'package:ibeacon_plugin/region.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'ibeacon_plugin_method_channel.dart';

abstract class IbeaconPluginPlatform extends PlatformInterface {
  IbeaconPluginPlatform() : super(token: _token);

  static final Object _token = Object();

  static IbeaconPluginPlatform _instance = MethodChannelIbeaconPlugin();
  static IbeaconPluginPlatform get instance => _instance;

  static set instance(IbeaconPluginPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<void> setRegion(Region region);

  Future<void> startMonitoring();

  Future<void> stopMonitoring();

  Stream<BeaconMonitoringState> getMonitoringStream();

  Future<bool> isBluetoothEnabled();
}
