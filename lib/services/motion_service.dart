import 'dart:async';
import 'dart:math' as math;
import 'package:sensors_plus/sensors_plus.dart';

class MotionService {
  /// ===== TUNING =====
  final double accelStartThreshold = 0.8; // bắt đầu chuyển động
  final double accelStopThreshold = 0.4; // dừng chuyển động

  final double gyroStartThreshold = 0.6;
  final double gyroStopThreshold = 0.3;

  final Duration debounceDuration = const Duration(seconds: 2);
  final double smoothingFactor = 0.2; // EMA

  /// ===== STATE =====
  bool isMoving = false;
  DateTime? _lastStateChange;

  double _smoothedAccel = 0;
  double _smoothedGyro = 0;

  StreamSubscription? _accelSub;
  StreamSubscription? _gyroSub;

  void startMonitoring(Function(bool) onChange) {
    _accelSub = accelerometerEvents.listen(_onAccel);
    _gyroSub = gyroscopeEvents.listen(_onGyro);

    Timer.periodic(const Duration(milliseconds: 300), (_) {
      _evaluateMotion(onChange);
    });
  }

  void stop() {
    _accelSub?.cancel();
    _gyroSub?.cancel();
  }

  // ================= INTERNAL =================

  void _onAccel(AccelerometerEvent e) {
    final magnitude = math.sqrt(e.x * e.x + e.y * e.y + e.z * e.z);
    final delta = (magnitude - 9.8).abs();

    _smoothedAccel =
        smoothingFactor * delta + (1 - smoothingFactor) * _smoothedAccel;
  }

  void _onGyro(GyroscopeEvent e) {
    final magnitude = math.sqrt(e.x * e.x + e.y * e.y + e.z * e.z);

    _smoothedGyro =
        smoothingFactor * magnitude + (1 - smoothingFactor) * _smoothedGyro;
  }

  void _evaluateMotion(Function(bool) onChange) {
    final now = DateTime.now();

    final shouldStartMoving = _smoothedAccel > accelStartThreshold ||
        _smoothedGyro > gyroStartThreshold;

    final shouldStopMoving = _smoothedAccel < accelStopThreshold &&
        _smoothedGyro < gyroStopThreshold;

    bool nextState = isMoving;

    if (!isMoving && shouldStartMoving) {
      nextState = true;
    } else if (isMoving && shouldStopMoving) {
      nextState = false;
    }

    if (nextState != isMoving) {
      if (_lastStateChange == null ||
          now.difference(_lastStateChange!) >= debounceDuration) {
        isMoving = nextState;
        _lastStateChange = now;
        onChange(isMoving);
      }
    }
  }
}
