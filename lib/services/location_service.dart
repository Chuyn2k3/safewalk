import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService {
  double? zoneLat;
  double? zoneLng;
  final double radiusMeters;

  LocationService({this.radiusMeters = 5});

  void setZoneCenter(double lat, double lng) {
    zoneLat = lat;
    zoneLng = lng;
  }

  Future<bool> isUserInsideZone() async {
    if (zoneLat == null || zoneLng == null) {
      throw Exception("Chưa có tọa độ vùng giám sát.");
    }

    Position userPosition = await getCurrentLocation();

    double distance = Geolocator.distanceBetween(
      userPosition.latitude,
      userPosition.longitude,
      zoneLat!,
      zoneLng!,
    );

    print("📍 Hiện tại: ${userPosition.latitude}, ${userPosition.longitude}");
    print(
        "📏 Khoảng cách đến vùng trung tâm: ${distance.toStringAsFixed(2)} m");

    return distance <= radiusMeters;
  }

  Future<Position> getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings(); // ✅ Mở cài đặt vị trí
      throw Exception("GPS đang tắt. Vui lòng bật GPS và thử lại.");
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception("Từ chối quyền truy cập vị trí.");
      }
    }

    if (permission == LocationPermission.deniedForever) {
      await openAppSettings(); // 🛠 Yêu cầu mở quyền trong cài đặt
      throw Exception(
          "Quyền vị trí bị từ chối vĩnh viễn. Hãy cấp lại trong cài đặt.");
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }
}
