import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:eyedid_flutter/eyedid_flutter.dart';
import 'package:eyedid_flutter/gaze_tracker_options.dart';
import 'package:eyedid_flutter/eyedid_flutter_initialized_result.dart';
import 'package:eyedid_flutter/events/eyedid_flutter_metrics.dart';

import 'package:permission_handler/permission_handler.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _eyedidFlutterPlugin = EyedidFlutter();
  static const String _licenseKey = "dev_ksoope3xnjczb23pijyn4j3b07qq5hxalrwhlh0z";
  static const MethodChannel _channel = MethodChannel('com.example.easy_control/overlay');
  double _x = 0.0, _y = 0.0;

  double _smoothedX = 0.0, _smoothedY = 0.0;
  bool _hasCameraPermission = false;
  bool _isCalibrated = false;
  bool _isTracking = false;
  String _statusMessage = "Initializing...";
  TrackingState _currentTrackingState = TrackingState.faceMissing;
  String _currentScreenState = "unknown";
  DateTime _lastUpdate = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      initEyedid();
      _requestPermission();
    });
  }

  Future<void> checkCameraPermission() async {
    _hasCameraPermission = await _eyedidFlutterPlugin.checkCameraPermission();
    if (!_hasCameraPermission) {
      _hasCameraPermission = await _eyedidFlutterPlugin.requestCameraPermission();
    }
    if (!mounted) return;
    setState(() {
      _statusMessage = _hasCameraPermission ? "Camera permission granted" : "Camera permission denied";
    });
  }

  // For Voice Recognition:
  Future<void> _requestPermission() async {
    var status = await Permission.microphone.request();
    if (!status.isGranted) {
      print('Microphone permission denied');
    }
  }
  // ----------------------------------------------------

  Future<void> initEyedid() async {
    await checkCameraPermission();
    if (_hasCameraPermission) {
      try {
        final options = GazeTrackerOptionsBuilder()
            .setPreset(CameraPreset.vga640x480)
            .setUseGazeFilter(true)  //false
            .setUseBlink(false)
            .setUseUserStatus(false)
            //.setMaxConcurrency(2)
            .build();
        InitializedResult initializedResult = await _eyedidFlutterPlugin.initGazeTracker(
            licenseKey: _licenseKey, options: options);
        if (initializedResult.result) {
          print("Eyedid initialized successfully");
          await _eyedidFlutterPlugin.setTrackingFPS(30);
          setState(() {
            _statusMessage = "Starting tracking...";
          });
          listenEvents();
          await _eyedidFlutterPlugin.startTracking();
          await startOverlay();
        } else {
          print("Eyedid initialization failed");
          setState(() {
            _statusMessage = "Eyedid initialization failed";
          });
        }
      } on PlatformException catch (e) {
        print("Initialization error: ${e.message}");
        setState(() {
          _statusMessage = "Initialization error: ${e.message}";
        });
      }
    }
  }

  void listenEvents() {
    _eyedidFlutterPlugin.getTrackingEvent().listen((event) async {
      MetricsInfo info = MetricsInfo(event);
      TrackingState trackingState = info.gazeInfo.trackingState;
      ScreenState screenState = info.gazeInfo.screenState;
      double x = info.gazeInfo.gaze.x;
      double y = info.gazeInfo.gaze.y;

      /*Try out switching between fixation and succade*/
      // var fixationX = info.gazeInfo.fixation.fixationX;
      // var fixationY = info.gazeInfo.fixation.fixationY;
      // if (info.gazeInfo.trackingState == TrackingState.success) {
      //   double x = info.gazeInfo.gaze.x;
      //   double y = info.gazeInfo.gaze.y;
      // }
      // else {
      //   double x = -1001;
      //   double y = -1001;
      // }


      const double alpha = 0.4;  //0.9    Maybe the dot keeps insanely going to edges because of this?!
      _smoothedX = alpha * x + (1 - alpha) * _smoothedX;
      _smoothedY = alpha * y + (1 - alpha) * _smoothedY;
       //_smoothedX = x;
       //_smoothedY = y;

      setState(() {
        // if(info.gazeInfo.eyemovementState == EyemovementState.fixation) {
        //   _x = info.gazeInfo.fixation.x;
        //   _y = info.gazeInfo.fixation.y;
        // }
        // else {
        //   _x = _smoothedX;
        //   _y = _smoothedY;
        // }
        _x = _smoothedX;
        _y = _smoothedY;
        _currentTrackingState = trackingState;

        if (screenState == ScreenState.insideOfScreen) {
          _currentScreenState = "inside";
        } else if (screenState == ScreenState.outsideOfScreen) {
          _currentScreenState = "out";
        } else {
          _currentScreenState = "unknown";
        }

        if (trackingState == TrackingState.success) {
          _isTracking = true;
          _isCalibrated = true;
          _statusMessage = "Tracking eyes successfully";
        } else if (trackingState == TrackingState.gazeNotFound) {
          _statusMessage = "Gaze not detected. Ensure your eyes are visible.";
          _isTracking = false;
          _isCalibrated = false;
        } else if (trackingState == TrackingState.faceMissing) {
          _statusMessage = "Face not detected. Please position your face in view.";
          _isTracking = false;
          _isCalibrated = false;
        }
      });

      // try {
      //   await _channel.invokeMethod('updateGaze', {
      //     'x': _smoothedX,
      //     'y': _smoothedY,
      //     'isCalibrated': _isCalibrated && trackingState == TrackingState.success,
      //   });
      //   print("Gaze coordinates: ($_x, $_y), Smoothed: ($_smoothedX, $_smoothedY), Calibrated: $_isCalibrated, State: $trackingState");
      // } catch (e) {
      //   print("MethodChannel error: $e");
      // }
// hd: 394 865
      if (DateTime.now().difference(_lastUpdate).inMilliseconds >= 34) {
        try {
          await _channel.invokeMethod('updateGaze', {
            'x': _x,
            'y': _y,
            'isCalibrated': _isCalibrated && trackingState == TrackingState.success,
            'screenState': _currentScreenState,
          });
          _lastUpdate = DateTime.now();
        } catch (e) {
          print("MethodChannel error: $e");
        }
      }
    });
  }

  Future<void> startOverlay() async {
    try {
      bool result = await _channel.invokeMethod('startOverlay');
      print("Overlay started: $result");
    } catch (e) {
      print("Error starting overlay: $e");
    }
  }

  Future<void> stopOverlay() async {
    try {
      bool result = await _channel.invokeMethod('stopOverlay');
      print("Overlay stopped: $result");
      setState(() {
        _statusMessage = "Overlay stopped. Restarting tracking...";
      });
      await _eyedidFlutterPlugin.stopTracking();
      await _eyedidFlutterPlugin.startTracking();
      await startOverlay();
    } catch (e) {
      print("Error stopping overlay: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            Align(
              alignment: Alignment.center,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  _statusMessage,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isTracking)
                    ElevatedButton(
                      onPressed: stopOverlay,
                      child: const Text('Stop Overlay'),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}