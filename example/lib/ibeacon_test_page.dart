import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ibeacon_plugin/beacon_monitoring_state.dart';
import 'package:ibeacon_plugin/ibeacon_plugin.dart';
import 'package:ibeacon_plugin/region.dart';

class BeaconTest extends StatefulWidget {
  const BeaconTest({super.key});

  @override
  State<BeaconTest> createState() => _BeaconTestState();
}

class _BeaconTestState extends State<BeaconTest> {
  String setRegionText = "";
  String startMonitoringText = "";
  String stopMonitoringText = "";
  String broadCastStreamText = "test";
  final ibeacon = IbeaconPlugin();

  late StreamSubscription<BeaconMonitoringState> becaonListener;

  @override
  void initState() {
    super.initState();
    becaonListener = ibeacon.monitoringStream.listen((event) {
      setState(() {
        if (event == BeaconMonitoringState.inside) {
          broadCastStreamText = "inside";
        } else {
          broadCastStreamText = "outside";
        }
      });
    });
  }

  @override
  void dispose() {
    becaonListener.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
          appBar: AppBar(
            title: const Text('Plugin example app'),
          ),
          body: Column(
            children: [
              ElevatedButton(
                  onPressed: () async => ibeacon
                      .setRegion(Region(
                        identifier: "Pcube+",
                        uuid: "E2C56DB5-DFFB-48D2-B060-D0F5A71096E0",
                        major: 40011,
                        minor: 32023,
                      ))
                      .then((value) => setState(() => setRegionText = "성공"))
                      .catchError(
                          (error) => setState(() => setRegionText = error)),
                  child: const Text("setRegion")),
              Text(setRegionText),
              ElevatedButton(
                  onPressed: () async => ibeacon
                      .startMonitoring()
                      .then(
                          (value) => setState(() => startMonitoringText = "성공"))
                      .catchError((error) =>
                          setState(() => startMonitoringText = error)),
                  child: const Text("startMonitoring")),
              Text(startMonitoringText),
              ElevatedButton(
                  onPressed: () async => ibeacon
                      .stopMonitoring()
                      .then(
                          (value) => setState(() => stopMonitoringText = "성공"))
                      .catchError((error) =>
                          setState(() => stopMonitoringText = error)),
                  child: const Text("stopMonitoring")),
              Text(stopMonitoringText),
              Text(broadCastStreamText),
            ],
          )),
    );
  }
}
