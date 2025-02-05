# ibeacon_plugin
ibeacon을 monitoring하기 위한 dart 플러그인

- AOS: altbeacon 라이브러리 사용
- iOS: CoreBluetooth 및 CoreLocation 사용


#### 플러그인 비콘 동작에 대해
- Monitoring: 범위 내에 비콘이 있는지 없는지만 판단한다.
- Ranging: 범위 내에 있을 경우, 기기 사이의 거리를 실시간으로 얻어온다.

해당 플러그인은 Monitoring 만 고려하고 있습니다.

# 플러그인 사용법

### 권한 추가 (AOS)

아래 경로에 permission 추가.

app\src\main\AndroidManifest.xml
```
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
    <uses-permission android:name="android.permission.BLUETOOTH"/>
    <uses-permission android:name="android.permission.BLUETOOTH_ADMIN"/>
    <uses-permission android:name="android.permission.BLUETOOTH_SCAN"/>
    <uses-permission android:name="android.permission.BLUETOOTH_CONNECT"/>
```

### 권한 추가 (iOS)

아래 경로에 permission 추가.

Runner\Info.plist
```
	<key>NSLocationWhenInUseUsageDescription</key>
	<string>이 앱은 비콘 모니터링을 위해 위치 접근 권한이 필요합니다.</string>
	<key>NSBluetoothAlwaysUsageDescription</key>
	<string>이 앱은 비콘 모니터링을 위해 블루투스 사용 권한이 필요합니다.</string>
```

### 함수 종류
- setRegion: 비콘의 id (비콘 이름), uuid, major, minor를 설정하는 함수.
- startMonitoring: 모니터링을 시작하는 함수. setRegion이 불리지 않았다면 Exception 발생.
- stopMonitoring: 모니터링을 중지하는 함수. setRegion이 불리지 않았다면 Exception 발생.
- monitoringStream: 모니터링 중인 상황을 stream으로 반환. (inside, outside 상태값 판단 가능)

추가적인 자세한 활용은 example\lib\ibeacon_test_page.dart 참고


# 유지보수에 대해

AOS: altbeacon 라이브러리에 큰 변화가 있다면, kotlin, JDK, gradle 버전을 알맞게 가장 최신으로 변경.

iOS: CoreLocation 에 변화가 있다면 알맞게 최신으로 변경.

권한 관련: AOS나 iOS 모두 SDK 버전이 올라가면 권한 관련 정책이 바뀔 수 있으므로 max SDK, compile SDK 수정 시 확인 필요

flutter: 거의 필요 없지만 프로젝트 sdk, flutter 버전 변경 시 함께 올리는 것 추천

