import 'package:eyedid_flutter/events/eyedid_flutter_metrics.dart';
import 'package:eyedid_flutter/eyedid_flutter.dart';
import 'package:eyedid_flutter/eyedid_flutter_initialized_result.dart';
import 'package:eyedid_flutter/gaze_tracker_options.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/settings_service.dart';

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
  static const String _licenseKey =
      "dev_1vctvvvl7f3wvdl3xdkoz3u02eka5pte5dnbvmdl";
  static const MethodChannel _channel = MethodChannel(
    'com.example.easy_control/overlay',
  );
  bool _hasCameraPermission = false;
  bool _isTracking = false;
  bool _isCalibrated = false;
  bool _isInitialized = false;
  bool _isCheckingPermissions = false;
  String _statusMessage = "Initializing...";
  double _smoothedX = 0.0, _smoothedY = 0.0;
  double _lastValidX = 0.0, _lastValidY = 0.0;
  TrackingState _currentTrackingState = TrackingState.faceMissing;
  String _currentScreenState = "unknown";
  DateTime _lastUpdate = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkAndInit());
  }

  Future<void> _checkAndInit() async {
    if (_isCheckingPermissions) return;
    setState(() => _isCheckingPermissions = true);

    _hasCameraPermission =
        await _eyedidFlutterPlugin.checkCameraPermission() ||
        await _eyedidFlutterPlugin.requestCameraPermission();

    if (_hasCameraPermission) {
      await _initEyedid();
    } else {
      setState(() => _statusMessage = "Camera permission denied");
    }
    setState(() => _isCheckingPermissions = false);
  }

  Future<void> _initEyedid() async {
    if (!_hasCameraPermission ||
        _isInitialized ||
        EyedidManager.isGazeTrackerInitialized) {
      if (EyedidManager.isGazeTrackerInitialized) {
        setState(() {
          _isInitialized = true;
          _statusMessage = "Ready to start tracking";
        });
        _listenEvents();
      }
      return;
    }

    try {
      final options =
          GazeTrackerOptionsBuilder()
              .setPreset(CameraPreset.vga640x480)
              .setUseGazeFilter(true)
              .setUseBlink(false)
              .setUseUserStatus(false)
              .build();
      InitializedResult result = await _eyedidFlutterPlugin.initGazeTracker(
        licenseKey: _licenseKey,
        options: options,
      );
      if (result.result) {
        await _eyedidFlutterPlugin.setTrackingFPS(30);
        setState(() {
          _isInitialized = true;
          EyedidManager.isGazeTrackerInitialized = true;
          _statusMessage = "Ready to start tracking";
        });
        _listenEvents();
      } else {
        setState(
          () => _statusMessage = "Initialization failed: ${result.message}",
        );
      }
    } catch (e) {
      setState(() => _statusMessage = "Initialization error: $e");
    }
  }

  void _listenEvents() {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    _eyedidFlutterPlugin.getTrackingEvent().listen((event) async {
      MetricsInfo info = MetricsInfo(event);
      TrackingState trackingState = info.gazeInfo.trackingState;
      ScreenState screenState = info.gazeInfo.screenState;
      double x = info.gazeInfo.gaze.x;
      double y = info.gazeInfo.gaze.y;

      if (trackingState == TrackingState.success) {
        const double alpha = 0.4;
        _smoothedX = alpha * x + (1 - alpha) * _smoothedX;
        _smoothedY = alpha * y + (1 - alpha) * _smoothedY;
        _lastValidX = _smoothedX;
        _lastValidY = _smoothedY;
      }

      setState(() {
        _currentTrackingState = trackingState;
        _currentScreenState =
            screenState == ScreenState.insideOfScreen
                ? "inside"
                : screenState == ScreenState.outsideOfScreen
                ? "out"
                : "unknown";
        if (trackingState == TrackingState.success && _isTracking) {
          _isCalibrated = true;
          _statusMessage = settings.translate('Tracking eyes successfully');
        } else if (trackingState == TrackingState.gazeNotFound) {
          _statusMessage = settings.translate('Gaze not detected');
          if (_isTracking) _isCalibrated = false;
        } else if (trackingState == TrackingState.faceMissing) {
          _statusMessage = settings.translate('Face not detected');
          if (_isTracking) _isCalibrated = false;
        }
      });

      if (_isTracking &&
          DateTime.now().difference(_lastUpdate).inMilliseconds >= 34) {
        try {
          await _channel.invokeMethod('updateGaze', {
            'x':
                trackingState == TrackingState.success
                    ? _smoothedX
                    : _lastValidX,
            'y':
                trackingState == TrackingState.success
                    ? _smoothedY
                    : _lastValidY,
            'isCalibrated':
                _isCalibrated && trackingState == TrackingState.success,
            'screenState': _currentScreenState,
          });
          _lastUpdate = DateTime.now();
        } catch (e) {
          print("MethodChannel error: $e");
        }
      }
    });
  }

  Future<void> _startOverlay() async {
    if (_isTracking) return;
    try {
      await _channel.invokeMethod('startOverlay');
      await _eyedidFlutterPlugin.startTracking();
      setState(() {
        _isTracking = true;
        _statusMessage = "Tracking started";
      });
    } catch (e) {
      setState(() => _statusMessage = "Error starting overlay: $e");
    }
  }

  Future<void> _stopOverlay() async {
    if (!_isTracking) return;
    try {
      await _channel.invokeMethod('stopOverlay');
      await _eyedidFlutterPlugin.stopTracking();
      setState(() {
        _isTracking = false;
        _isCalibrated = false;
        _statusMessage = "Tracking stopped";
      });
    } catch (e) {
      setState(() => _statusMessage = "Error stopping overlay: $e");
    }
  }

  @override
  void dispose() {
    // Don't stop tracking when disposing the screen
    // This allows the overlay to continue running when navigating away
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          settings.translate('Eye Tracking'),
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          semanticsLabel: settings.translate('Eye Tracking'),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            settings.translate('Status'),
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  _isTracking
                                      ? Colors.green.withOpacity(0.2)
                                      : Colors.red.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _isTracking
                                  ? settings.translate('Active')
                                  : settings.translate('Inactive'),
                              style: TextStyle(
                                color: _isTracking ? Colors.green : Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _statusMessage,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.textTheme.bodyLarge?.color?.withOpacity(
                            0.7,
                          ),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Text(
                        settings.translate('Gaze Position'),
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildCoordinateDisplay(
                            'X',
                            _smoothedX.toStringAsFixed(1),
                            theme,
                          ),
                          _buildCoordinateDisplay(
                            'Y',
                            _smoothedY.toStringAsFixed(1),
                            theme,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          settings.translate('Controls'),
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed:
                                _hasCameraPermission && _isInitialized
                                    ? (_isTracking
                                        ? _stopOverlay
                                        : _startOverlay)
                                    : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  _isTracking ? Colors.red : Colors.green,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 4,
                            ),
                            child: Text(
                              _isTracking
                                  ? settings.translate('Stop Tracking')
                                  : settings.translate('Start Tracking'),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCoordinateDisplay(String label, String value, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: theme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.primaryColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
