import 'package:flutter/services.dart';

sealed class IbeaconPluginException implements Exception {}

class RegionNotSetException implements IbeaconPluginException {
  @override
  String toString() => "Region이 설정되지 않았습니다.";
}

class BluetoothNotEnabledException implements IbeaconPluginException {
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
