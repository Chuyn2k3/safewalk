import 'dart:async';
import 'package:flutter/material.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:geolocator/geolocator.dart';
import 'package:safewalk/widgets/radar_view.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:permission_handler/permission_handler.dart';

import '../services/location_service.dart';
import '../services/motion_service.dart';
import '../services/fake_api_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  // ========================
  // SERVICES
  // ========================
  final LocationService _locationService = LocationService();
  final MotionService _motionService = MotionService();
  final FakeAPIService _apiService = FakeAPIService();

  // ========================
  // INPUT CONTROLLERS
  // ========================
  final TextEditingController _latController = TextEditingController();
  final TextEditingController _lngController = TextEditingController();

  // ========================
  // STATE
  // ========================
  bool _isInsideZone = false;
  bool _isMoving = true;
  bool _isScreenOn = true;
  bool _subscriptionValid = false;
  bool _screenOnTooLong = false;

  Position? _currentPosition;

  // Zone center (for display)
  double? _zoneLat;
  double? _zoneLng;
  double? _distanceToZone; // meters

  // ========================
  // TIMERS
  // ========================
  Timer? _monitorTimer;
  Timer? _screenOnTimer;

  // ========================
  // WARNING
  // ========================
  OverlaySupportEntry? _warningEntry;
  bool _bannerShown = false;

  // ========================
  // INIT
  // ========================
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initApp();
  }

  // ========================
  // APP LIFECYCLE (SCREEN ON/OFF - DEMO)
  // ========================
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _isScreenOn = state == AppLifecycleState.resumed;

    if (!_isScreenOn) {
      _clearWarning();
    }
  }

  // ========================
  // APP INIT
  // ========================
  Future<void> _initApp() async {
    final permission = await Permission.location.request();
    if (!permission.isGranted) return;

    _subscriptionValid = await _apiService.checkCompanySubscription("renault");
    if (!_subscriptionValid) return;

    // Motion monitoring
    _motionService.startMonitoring((moving) {
      setState(() => _isMoving = true);
    });

    // Current location (for display only)
    _currentPosition = await _locationService.getCurrentLocation();

    // Default zone = current position
    _locationService.setZoneCenter(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
    );

    setState(() {
      _zoneLat = _currentPosition!.latitude;
      _zoneLng = _currentPosition!.longitude;
    });

    // Main monitoring loop
    _monitorTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => _monitorLogic(),
    );
  }

  // ========================
  // CORE LOGIC (MATCH FLOWCHART)
  // ========================
  Future<void> _monitorLogic() async {
    try {
      final inside = await _locationService.isUserInsideZone();
      final current = await _locationService.getCurrentLocation();

      setState(() {
        _isInsideZone = inside;
        _currentPosition = current;
        if (_zoneLat != null && _zoneLng != null) {
          _distanceToZone = Geolocator.distanceBetween(
            current.latitude,
            current.longitude,
            _zoneLat!,
            _zoneLng!,
          );
        }
      });

      // ❌ NOT IN ZONE
      if (!_isInsideZone) {
        _clearWarning();
        return;
      }

      // ❌ NOT MOVING
      if (!_isMoving) {
        _clearWarning();
        return;
      }

      // ❌ SCREEN OFF (APP BACKGROUND)
      if (!_isScreenOn) {
        _clearWarning();
        return;
      }

      // ✅ ALL CONDITIONS TRUE
      _showWarning();
      _startScreenTimer();

      if (_screenOnTooLong && _isMoving) {
        await ScreenBrightness().setScreenBrightness(0.1);
      }
    } catch (e) {
      debugPrint("❌ Monitor error: $e");
    }
  }

  // ========================
  // UPDATE ZONE FROM INPUT
  // ========================
  void _updateZoneFromInput() {
    final lat = double.tryParse(_latController.text);
    final lng = double.tryParse(_lngController.text);

    if (lat == null || lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lat/Lng không hợp lệ")),
      );
      return;
    }

    _locationService.setZoneCenter(lat, lng);

    setState(() {
      _zoneLat = lat;
      _zoneLng = lng;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("📌 Đã cập nhật vùng giám sát")),
    );
  }

  // ========================
  // WARNING BANNER
  // ========================
  void _showWarning() {
    if (_bannerShown) return;

    _warningEntry = showSimpleNotification(
      const Text(
        "⚠️ Đang di chuyển trong vùng giám sát",
        style: TextStyle(color: Colors.white),
      ),
      background: Colors.red,
      slideDismiss: false,
      duration: const Duration(seconds: 5),
    );

    _bannerShown = true;
  }

  void _clearWarning() {
    _warningEntry?.dismiss();
    _warningEntry = null;
    _bannerShown = false;

    _screenOnTimer?.cancel();
    _screenOnTimer = null;
    _screenOnTooLong = false;

    ScreenBrightness().resetScreenBrightness();
  }

  // ========================
  // SCREEN TIMER (TEST: 5 SECONDS)
  // ========================
  void _startScreenTimer() {
    if (_screenOnTimer != null) return;

    _screenOnTimer = Timer(const Duration(seconds: 5), () {
      _screenOnTooLong = true;
    });
  }

  // ========================
  // CLEAN UP
  // ========================
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _monitorTimer?.cancel();
    _screenOnTimer?.cancel();
    _warningEntry?.dismiss();
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  // ========================
  // UI
  // ========================

  @override
  Widget build(BuildContext context) {
    final lat = _currentPosition?.latitude.toStringAsFixed(6) ?? "--";
    final lng = _currentPosition?.longitude.toStringAsFixed(6) ?? "--";

    final zoneLat = _zoneLat?.toStringAsFixed(6) ?? "--";
    final zoneLng = _zoneLng?.toStringAsFixed(6) ?? "--";

    return Scaffold(
      appBar: AppBar(title: const Text("NS2W Demo")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("📍 Vị trí hiện tại: $lat , $lng"),
              const SizedBox(height: 4),
              Text(
                "🎯 Trung tâm vùng giám sát: $zoneLat , $zoneLng",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                "📏 Khoảng cách đến vùng trung tâm: $_distanceToZone m",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              Center(
                  child: MapView(
                centerLat: _zoneLat,
                centerLng: _zoneLng,
                userLat: _currentPosition?.latitude,
                userLng: _currentPosition?.longitude,
                //safetyRadiusMeters: 5,
              )),

              const SizedBox(height: 16),
              // INPUT LAT / LNG
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _latController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: "Latitude",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _lngController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: "Longitude",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _updateZoneFromInput,
                child: const Text("📌 Cập nhật vùng giám sát"),
              ),

              const Divider(height: 32),

              // DEBUG STATE
              Text("📍 Trong vùng: $_isInsideZone"),
              Text("🚶 Di chuyển: $_isMoving"),
              Text("📱 Screen ON: $_isScreenOn"),
              Text("⏱ Screen > 5s: $_screenOnTooLong"),
              Text("🔐 Subscription: $_subscriptionValid"),
            ],
          ),
        ),
      ),
    );
  }
}
