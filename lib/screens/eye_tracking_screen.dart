
import 'package:eyedid_flutter/events/eyedid_flutter_metrics.dart';
import 'package:eyedid_flutter/eyedid_flutter.dart';
import 'package:eyedid_flutter/eyedid_flutter_initialized_result.dart';
import 'package:eyedid_flutter/gaze_tracker_options.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Global flag to track gaze tracker initialization
class EyedidManager {
static bool isGazeTrackerInitialized = false;
}

class EyeTrackingScreen extends StatefulWidget {
const EyeTrackingScreen({super.key});

@override
State<EyeTrackingScreen> createState() => _EyeTrackingScreenState();
}

class _EyeTrackingScreenState extends State<EyeTrackingScreen> {
final _eyedidFlutterPlugin = EyedidFlutter();
static const String _licenseKey = "dev_xygmkyig9dysd7pfcd7pbcjsgecjanyjgx2ofxdm";
static const MethodChannel _channel = MethodChannel('com.example.easy_control/overlay');
bool _hasCameraPermission = false;
bool _isTracking = false;
bool _isCalibrated = false;
bool _isInitialized = false;
bool _isCheckingPermissions = false; // Prevent concurrent permission checks
String _statusMessage = "Initializing...";
double _x = 0.0, _y = 0.0;
double _smoothedX = 0.0, _smoothedY = 0.0;
TrackingState _currentTrackingState = TrackingState.faceMissing;
String _currentScreenState = "unknown";
DateTime _lastUpdate = DateTime.now();

@override
void initState() {
super.initState();
WidgetsBinding.instance.addPostFrameCallback((_) {
_showPermissionDialog();
});
}

Future<void> _showPermissionDialog() async {
if (_isCheckingPermissions) return;
setState(() {
_isCheckingPermissions = true;
});

await checkCameraPermission();
if (!_hasCameraPermission) {
if (!mounted) {
setState(() {
_isCheckingPermissions = false;
});
return;
}
showDialog(
context: context,
barrierDismissible: false,
builder: (BuildContext context) {
return AlertDialog(
title: const Text('Camera Permission'),
content: const Text(
'This app requires camera access to enable eye tracking. Do you grant permission?',
),
actions: [
TextButton(
onPressed: () {
Navigator.of(context).pop();
setState(() {
_statusMessage = 'Permission denied. Eye tracking disabled.';
_isCheckingPermissions = false;
});
},
child: const Text('Deny'),
),
TextButton(
onPressed: () async {
Navigator.of(context).pop();
await checkCameraPermission();
if (_hasCameraPermission) {
await initEyedid();
}
setState(() {
_isCheckingPermissions = false;
});
},
child: const Text('Grant'),
),
],
);
},
);
} else {
await initEyedid();
setState(() {
_isCheckingPermissions = false;
});
}
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

Future<void> initEyedid() async {
if (_hasCameraPermission && !_isInitialized && !EyedidManager.isGazeTrackerInitialized) {
try {
final options = GazeTrackerOptionsBuilder()
    .setPreset(CameraPreset.vga640x480)
    .setUseGazeFilter(true)
    .setUseBlink(false)
    .setUseUserStatus(false)
    .build();
InitializedResult initializedResult = await _eyedidFlutterPlugin.initGazeTracker(
licenseKey: _licenseKey,
options: options,
);
if (initializedResult.result) {
print("Eyedid initialized successfully");
await _eyedidFlutterPlugin.setTrackingFPS(30);
setState(() {
_isInitialized = true;
EyedidManager.isGazeTrackerInitialized = true;
_statusMessage = "Ready to start tracking";
});
listenEvents();
} else {
print("Eyedid initialization failed: ${initializedResult.message}");
setState(() {
_statusMessage = "Eyedid initialization failed: ${initializedResult.message}.";
});
}
} on PlatformException catch (e) {
print("Initialization error: ${e.message}");
setState(() {
if (e.message?.contains("already initialized") ?? false) {
_isInitialized = true;
EyedidManager.isGazeTrackerInitialized = true;
_statusMessage = "Gaze tracker already initialized. Ready to start tracking.";
listenEvents();
} else {
_statusMessage = "Initialization error: ${e.message}";
}
});
}
} else if (EyedidManager.isGazeTrackerInitialized) {
setState(() {
_isInitialized = true;
_statusMessage = "Gaze tracker already initialized. Ready to start tracking.";
});
listenEvents();
}
}

void listenEvents() {
_eyedidFlutterPlugin.getTrackingEvent().listen((event) async {
MetricsInfo info = MetricsInfo(event);
TrackingState trackingState = info.gazeInfo.trackingState;
ScreenState screenState = info.gazeInfo.screenState;
double x = info.gazeInfo.gaze.x;
double y = info.gazeInfo.gaze.y;

const double alpha = 0.4;
_smoothedX = alpha * x + (1 - alpha) * _smoothedX;
_smoothedY = alpha * y + (1 - alpha) * _smoothedY;

setState(() {
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

if (trackingState == TrackingState.success && _isTracking) {
_isCalibrated = true;
_statusMessage = "Tracking eyes successfully";
} else if (trackingState == TrackingState.gazeNotFound) {
_statusMessage = "Gaze not detected. Ensure your eyes are visible.";
if (_isTracking) {
_isCalibrated = false;
}
} else if (trackingState == TrackingState.faceMissing) {
_statusMessage = "Face not detected. Please position your face in view.";
if (_isTracking) {
_isCalibrated = false;
}
}
});

if (_isTracking && DateTime.now().difference(_lastUpdate).inMilliseconds >= 34) {
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
if (_isTracking) return;
try {
bool result = await _channel.invokeMethod('startOverlay');
print("Overlay started: $result");
await _eyedidFlutterPlugin.startTracking();
setState(() {
_isTracking = true;
_statusMessage = "Tracking started";
});
} catch (e) {
print("Error starting overlay: $e");
setState(() {
_statusMessage = "Error starting overlay";
});
}
}

Future<void> stopOverlay() async {
if (!_isTracking) return;
try {
bool result = await _channel.invokeMethod('stopOverlay');
print("Overlay stopped: $result");
await _eyedidFlutterPlugin.stopTracking();
setState(() {
_isTracking = false;
_isCalibrated = false;
_statusMessage = "Tracking stopped";
});
} catch (e) {
print("Error stopping overlay: $e");
setState(() {
_statusMessage = "Error stopping overlay";
});
}
}

@override
void dispose() {
if (_isTracking) {
_eyedidFlutterPlugin.stopTracking();
}
// Uncomment if EyedidFlutter supports releaseGazeTracker
// _eyedidFlutterPlugin.releaseGazeTracker();
super.dispose();
}

@override
Widget build(BuildContext context) {
return Scaffold(
appBar: AppBar(
title: const Text('Eye Tracking'),
backgroundColor: Colors.blueAccent,
),
body: Center(
child: Padding(
padding: const EdgeInsets.all(24.0),
child: Column(
mainAxisAlignment: MainAxisAlignment.center,
children: [
Text(
_statusMessage,
style: const TextStyle(fontSize: 18, color: Colors.black),
textAlign: TextAlign.center,
),
const SizedBox(height: 20),
Row(
mainAxisAlignment: MainAxisAlignment.center,
children: [
const Text(
'Eye Tracking:',
style: TextStyle(fontSize: 18),
),
const SizedBox(width: 10),
Switch(
value: _isTracking,
onChanged: _hasCameraPermission && _isInitialized
? (value) async {
if (value) {
await startOverlay();
} else {
await stopOverlay();
}
}
    : null,
activeColor: Colors.blueAccent,
),
],
),
const SizedBox(height: 20),
Text(
'Gaze: (${_x.toStringAsFixed(1)}, ${_y.toStringAsFixed(1)})',
style: const TextStyle(fontSize: 16),
),
const SizedBox(height: 20),
ElevatedButton(
onPressed: () {
Navigator.pop(context);
},
style: ElevatedButton.styleFrom(
padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
backgroundColor: Colors.blueAccent,
),
child: const Text('Back to Home', style: TextStyle(fontSize: 16)),
),
],
),
),
),
);
}
}
