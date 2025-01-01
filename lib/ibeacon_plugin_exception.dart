import 'package:flutter/services.dart';

sealed class IBeaconPluginException implements Exception {}

class RegionNotSetException implements IBeaconPluginException {
  @override
  String toString() => "Region이 설정되지 않았습니다.";
}

class BluetoothNotEnabledException implements IBeaconPluginException {
  @override
  String toString() => "블루투스가 꺼져있습니다.";
}

extension PlatformExceptionExtension on PlatformException {
  void throwCustomException() {
    throw switch (code) {
      "RegionNotSetException" => RegionNotSetException(),
      "BluetoothNotEnabledException" => BluetoothNotEnabledException(),
      _ => this,
    };
  }
}
