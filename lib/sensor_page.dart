import 'dart:async';
import 'dart:convert' show utf8;
import 'dart:ui';

import 'package:sauna_temperature/main.dart';
import 'package:sauna_temperature/widgets_graph.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';


bool addTemperatureToGraph = true; // Used to stop multiple temperature inputs when moving the slider
bool timeOut = false; // Time out for notifications
bool temperatureBelow = true; // Used to control notifications
double notificationTemperature = 60;

// ___ NOTIFICATIONS ___
Future<void> _showNotification(temperature) async {
  const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails('your channel id', 'your channel name',
          channelDescription: 'your channel description',
          importance: Importance.max,
          priority: Priority.high,
          ticker: 'ticker');
  const NotificationDetails platformChannelSpecifics =
      NotificationDetails(android: androidPlatformChannelSpecifics);
  await flutterLocalNotificationsPlugin.show(
      0,
      'Sauna temperature just hit ' + temperature + ' °C',
      '',
      platformChannelSpecifics,
      payload: 'item x');
}

// ___ TIMER ___
void startTimer(timeOutPeriod) {
  const oneSec = Duration(seconds: 1);
  Timer.periodic(
    oneSec,
    (Timer timer) {
      if (timeOutPeriod == 0) {
        timeOut = false;
        timer.cancel();
      } else {
        timeOutPeriod--;
      }
    },
  );
}


// ___ PAGE ____
class SensorPage extends StatefulWidget {
  const SensorPage({Key? key, required this.device}) : super(key: key);
  final BluetoothDevice device;

  @override
  _SensorPageState createState() => _SensorPageState();
}

class _SensorPageState extends State<SensorPage> {
  // BLE UUIDs
  final String serviceUUID = "0000181a-0000-1000-8000-00805f9b34fb";
  final String characteristicUUID = "00002a6e-0000-1000-8000-00805f9b34fb";

  bool isReady = false;
  late Stream<List<int>> stream;
  List<double> recordedTemperatures = [];

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    _configureDidReceiveLocalNotificationSubject();
    _configureSelectNotificationSubject();

    isReady = false;
    connectToDevice();
  }

  void _requestPermissions() {
    flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
    flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  void _configureDidReceiveLocalNotificationSubject() {
    didReceiveLocalNotificationSubject.stream
        .listen((ReceivedNotification receivedNotification) async {
      await showDialog(
        context: context,
        builder: (BuildContext context) => CupertinoAlertDialog(
          title: receivedNotification.title != null
              ? Text(receivedNotification.title!)
              : null,
          content: receivedNotification.body != null
              ? Text(receivedNotification.body!)
              : null,
          actions: <Widget>[
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () async {
                Navigator.of(context, rootNavigator: true).pop();
              },
              child: const Text('Ok'),
            )
          ],
        ),
      );
    });
  }

  void _configureSelectNotificationSubject() {
    selectNotificationSubject.stream.listen((String? payload) async {
      await Navigator.pushNamed(context, '/sensorPage');
    });
  }

  @override
  void dispose() {
    didReceiveLocalNotificationSubject.close();
    selectNotificationSubject.close();
    super.dispose();
  }

  connectToDevice() async {
    Timer(const Duration(seconds: 15), () {
      if (!isReady) {
        disconnectFromDevice();
        _Pop();
      }
    });

    await widget.device.connect();
    discoverServices();
  }

  disconnectFromDevice() {
    widget.device.disconnect();
  }

  discoverServices() async {
    List<BluetoothService> services = await widget.device.discoverServices();
    for (var service in services) {
      if (service.uuid.toString() == serviceUUID) {
        for (var characteristic in service.characteristics) {
          if (characteristic.uuid.toString() == characteristicUUID) {
            characteristic.setNotifyValue(!characteristic.isNotifying);
            stream = characteristic.value;

            setState(() {
              isReady = true;
            });
          }
        }
      }
    }

    if (!isReady) {
      _Pop();
    }
  }

  Future<bool> _onWillPop() {
    return showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text('Are you sure?'),
              content:
                  const Text('Do you want to disconnect device and go back?'),
              actions: <Widget>[
                TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('No')),
                TextButton(
                    onPressed: () {
                      disconnectFromDevice();
                      Navigator.of(context).pop(true);
                    },
                    child: const Text('Yes')),
              ],
            )).then((value) => value ?? false);
  }

  // ignore: non_constant_identifier_names
  _Pop() {
    Navigator.of(context).pop(true);
  }

  String _dataParser(/* List<int> */ dataFromDevice) {
    return utf8.decode(dataFromDevice);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('ESP32-BLE Sauna'),
          backgroundColor: Colors.blueGrey[900]!,
        ),
        body: Container(
            child: !isReady
                ? const Center(
                    child: Text(
                      "Connecting...",
                      style: TextStyle(fontSize: 24, color: Colors.red),
                    ),
                  )
                : StreamBuilder<List<int>>(
                    stream: stream,
                    builder: (BuildContext context,
                        AsyncSnapshot<List<int>> snapshot) {
                      if (snapshot.hasError) {
                        return Text('Error: ${snapshot.error}');
                      }

                      if (snapshot.connectionState == ConnectionState.active) {
                        String roundedNotificationTemperature =
                            notificationTemperature.round().toString();
                        var currentTemperature = _dataParser(snapshot.data);
                        var currentTemperatureDouble =
                            double.tryParse(currentTemperature);
                        if (addTemperatureToGraph) {
                          // Don't add any value to graph if it's N/A
                          // for some reason, for example due to packet loss
                          if (currentTemperatureDouble != null) {
                            // 20 is the minimum temperature in the graph
                            if (currentTemperatureDouble >= 20) {
                              recordedTemperatures.add(currentTemperatureDouble);
                            }
                          }
                        }
                        // Turn addTemperatureToGraph true after skipping one
                        // Will turn false again if the slider is still being held down
                        addTemperatureToGraph = true;

                        if (double.tryParse(currentTemperature) != null) {
                          // Control for sending only one notification
                          if (!timeOut) {
                            // Send notification if sauna temperature is high enough
                            if (double.tryParse(currentTemperature)! >=
                                notificationTemperature) {
                              if (temperatureBelow) {
                                _showNotification(currentTemperature);
                                temperatureBelow = false;
                                timeOut = true;
                                // 10 minute timeout
                                startTimer(600);
                              }
                            }

                            // Control for sending only one notification
                            // Allow new notifications after the temperature
                            // has fallen below the desired temperature again
                            if (double.tryParse(currentTemperature)! <
                                notificationTemperature) {
                              temperatureBelow = true;
                            }
                          }
                        }

                        return Center(
                          child: Column(
                          children: <Widget>[
                            Expanded(
                              flex: 1,
                              child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    const Text('Current temperature:',
                                        style: TextStyle(fontSize: 16)),
                                    Text('$currentTemperature °C',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.deepOrange[700]!,
                                            fontSize: 55))
                                  ]),
                            ),
                            // ignore: sized_box_for_whitespace
                            Container(
                                height: 150,
                                child: Column(
                                  children: <Widget>[
                                    const Text(
                                        'Choose notification temperature:',
                                        style: TextStyle(fontSize: 14)),
                                    Text('$roundedNotificationTemperature °C',
                                        style: TextStyle(
                                            color: Colors.purpleAccent[400]!,
                                            fontSize: 18)),
                                    Slider(
                                      value: notificationTemperature,
                                      min: 20,
                                      max: 100,
                                      divisions: 80,
                                      thumbColor: Colors.deepPurple[800]!,
                                      activeColor: Colors.deepPurple[600]!,
                                      inactiveColor: Colors.blueGrey[100]!,
                                      onChanged: (double sliderValue) {
                                        setState(() {
                                          notificationTemperature = sliderValue;
                                          addTemperatureToGraph = false;
                                        });
                                      },
                                    )
                                  ],
                                )),
                            Container(
                                color: const Color(0xff232d37),
                                child: Column(children: <Widget>[
                                  const SizedBox(
                                    height: 10,
                                  ),
                                  Text(
                                    'Sauna Temperature',
                                    style: TextStyle(
                                      color: Colors.cyan[400]!,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  TemperatureLineChart(
                                      recordedTemperatures:
                                          recordedTemperatures)
                                ]))
                          ],
                        ));
                      } else {
                        return const Center(
                          child: Text("Connecting...",
                          style: TextStyle(fontSize: 24, color: Colors.red),
                        ));
                      }
                    },
                  )),
      ),
    );
  }
}
