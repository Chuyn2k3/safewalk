import 'package:flutter/material.dart';
//import 'package:flutter_map/flutter_map.dart';
//import 'package:latlong2/latlong.dart';
import 'dart:math' as math;
import 'package:maplibre_gl/maplibre_gl.dart';

class MapView extends StatefulWidget {
  final double? centerLat;
  final double? centerLng;
  final double? userLat;
  final double? userLng;
  final double safetyRadiusMeters;

  const MapView({
    super.key,
    required this.centerLat,
    required this.centerLng,
    required this.userLat,
    required this.userLng,
    this.safetyRadiusMeters = 5,
  });

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    _pulseAnimation = Tween<double>(begin: 0, end: 8).animate(_pulseController);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  double _calculateDistance(
      double lat1, double lng1, double lat2, double lng2) {
    const double earthRadiusKm = 6371.0;
    double dLat = _degreesToRadians(lat2 - lat1);
    double dLng = _degreesToRadians(lng2 - lng1);
    double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) *
            math.cos(_degreesToRadians(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c * 1000;
  }

  double _degreesToRadians(double degrees) {
    return degrees * math.pi / 180;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.centerLat == null || widget.centerLng == null) {
      return Container(
        height: 240,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text("Location not available"),
        ),
      );
    }

    final centerPoint = LatLng(widget.centerLat!, widget.centerLng!);
    final userPoint = (widget.userLat != null && widget.userLng != null)
        ? LatLng(widget.userLat!, widget.userLng!)
        : centerPoint;

    final distanceToCenter = (widget.userLat != null && widget.userLng != null)
        ? _calculateDistance(widget.centerLat!, widget.centerLng!,
            widget.userLat!, widget.userLng!)
        : 0;
    final isInsideZone = distanceToCenter <= widget.safetyRadiusMeters;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 240,
        child: Stack(
          children: [
            MaplibreMap(
              styleString:
                  "https://api.maptiler.com/maps/buildings/style.json?key=fNM0meTZ9uLAKHdN0E3k",
              initialCameraPosition: CameraPosition(
                target: LatLng(widget.centerLat!, widget.centerLng!),
                zoom: 17.5,
              ),
              //onMapCreated: _onMapCreated,
              myLocationEnabled: false,
              //myLocationTrackingMode: MyLocationTrackingMode.None,
            ),
            // FlutterMap(
            //   options: MapOptions(
            //     center: centerPoint,
            //     zoom: 18.5,
            //     maxZoom: 19,
            //     minZoom: 5,
            //   ),
            //   children: [
            //     // TileLayer(
            //     //   urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            //     //   userAgentPackageName: 'com.example.safewalk',
            //     // ),
            //     MaplibreMap(
            //       styleString:
            //           "https://api.maptiler.com/maps/buildings/style.json?key=fNM0meTZ9uLAKHdN0E3k",
            //       initialCameraPosition: CameraPosition(
            //         target: LatLng(center.latitude, center.longitude),
            //         zoom: 17.5,
            //       ),
            //       //onMapCreated: _onMapCreated,
            //       myLocationEnabled: false,
            //       //myLocationTrackingMode: MyLocationTrackingMode.None,
            //     ),

            //     // CircleLayer(
            //     //   circles: [
            //     //     // Outer warning zone (light, large)
            //     //     CircleMarker(
            //     //       point: centerPoint,
            //     //       radius: widget.safetyRadiusMeters + 3,
            //     //       useRadiusInMeter: true,
            //     //       color: Colors.orange.withOpacity(0.1),
            //     //       borderStrokeWidth: 1,
            //     //       borderColor: Colors.orange.withOpacity(0.5),
            //     //     ),
            //     //     // Safety zone fill (vibrant, semi-transparent)
            //     //     CircleMarker(
            //     //       point: centerPoint,
            //     //       radius: widget.safetyRadiusMeters,
            //     //       useRadiusInMeter: true,
            //     //       color: Colors.green.withOpacity(0.25),
            //     //       borderStrokeWidth: 3.5,
            //     //       borderColor: Colors.green[400]!,
            //     //     ),
            //     //   ],
            //     // ),
            //     // MarkerLayer(
            //     //   markers: [
            //     //     Marker(
            //     //       point: centerPoint,
            //     //       width: 60,
            //     //       height: 60,
            //     //       builder: (context) => Stack(
            //     //         alignment: Alignment.center,
            //     //         children: [
            //     //           // Pulse ring animation
            //     //           AnimatedBuilder(
            //     //             animation: _pulseAnimation,
            //     //             builder: (context, child) {
            //     //               return Container(
            //     //                 width: 60 + _pulseAnimation.value * 2,
            //     //                 height: 60 + _pulseAnimation.value * 2,
            //     //                 decoration: BoxDecoration(
            //     //                   shape: BoxShape.circle,
            //     //                   border: Border.all(
            //     //                     color: Colors.red.withOpacity(
            //     //                         0.3 - _pulseAnimation.value / 60),
            //     //                     width: 1.5,
            //     //                   ),
            //     //                 ),
            //     //               );
            //     //             },
            //     //           ),
            //     //           // Main marker
            //     //           Container(
            //     //             width: 60,
            //     //             height: 60,
            //     //             decoration: BoxDecoration(
            //     //               color: Colors.red,
            //     //               shape: BoxShape.circle,
            //     //               border: Border.all(
            //     //                 color: Colors.white,
            //     //                 width: 3,
            //     //               ),
            //     //               boxShadow: [
            //     //                 BoxShadow(
            //     //                   color: Colors.red.withOpacity(0.8),
            //     //                   blurRadius: 16,
            //     //                   spreadRadius: 4,
            //     //                 ),
            //     //               ],
            //     //             ),
            //     //             child: const Icon(
            //     //               Icons.location_on,
            //     //               color: Colors.white,
            //     //               size: 32,
            //     //             ),
            //     //           ),
            //     //         ],
            //     //       ),
            //     //     ),
            //     //     if (widget.userLat != null && widget.userLng != null)
            //     //       Marker(
            //     //         point: userPoint,
            //     //         width: 20,
            //     //         height: 20,
            //     //         builder: (context) => Container(
            //     //           decoration: BoxDecoration(
            //     //             color: Colors.blue,
            //     //             shape: BoxShape.circle,
            //     //             border: Border.all(
            //     //               color: Colors.white,
            //     //               width: 2.5,
            //     //             ),
            //     //             boxShadow: [
            //     //               BoxShadow(
            //     //                 color: Colors.blue.withOpacity(0.7),
            //     //                 blurRadius: 12,
            //     //                 spreadRadius: 2,
            //     //               ),
            //     //             ],
            //     //           ),
            //     //           child: const Icon(
            //     //             Icons.my_location,
            //     //             color: Colors.white,
            //     //             size: 12,
            //     //           ),
            //     //         ),
            //     //       ),
            //     //   ],
            //     // ),
            //   ],
            // ),
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isInsideZone
                      ? Colors.red.shade600
                      : Colors.green.shade600,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (isInsideZone
                              ? Colors.red.shade600
                              : Colors.green.shade600)
                          .withOpacity(0.6),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isInsideZone ? Icons.check_circle : Icons.warning_amber,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isInsideZone ? 'SAFE' : 'ALERT',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.25),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'DISTANCE TO ZONE',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '${distanceToCenter.toStringAsFixed(1)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'm',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
// import 'package:flutter/material.dart';
// import 'package:flutter_map/flutter_map.dart';
// import 'package:latlong2/latlong.dart';
// import 'dart:math' as math;

// class MapView extends StatelessWidget {
//   final double? centerLat;
//   final double? centerLng;
//   final double? userLat;
//   final double? userLng;
//   final double areaSquareMeters;

//   const MapView({
//     super.key,
//     required this.centerLat,
//     required this.centerLng,
//     required this.userLat,
//     required this.userLng,
//     this.areaSquareMeters = 4000,
//   });

//   // Tính độ dài 1 cạnh của hình vuông từ diện tích
//   double _getSideLengthInMeters(double area) {
//     return math.sqrt(area);
//   }

//   // Dịch mét sang độ (latitude & longitude)
//   double _metersToLat(double meters) => meters / 111320;
//   double _metersToLng(double meters, double latitude) =>
//       meters / (111320 * math.cos(latitude * math.pi / 180));

//   @override
//   Widget build(BuildContext context) {
//     if (centerLat == null || centerLng == null) {
//       return Container(
//         height: 240,
//         decoration: BoxDecoration(
//           color: Colors.grey[300],
//           borderRadius: BorderRadius.circular(12),
//         ),
//         child: const Center(
//           child: Text("Location not available"),
//         ),
//       );
//     }

//     final sideLengthMeters = _getSideLengthInMeters(areaSquareMeters);
//     final halfSide = sideLengthMeters / 2;

//     final deltaLat = _metersToLat(halfSide);
//     final deltaLng = _metersToLng(halfSide, centerLat!);

//     final topLeft = LatLng(centerLat! + deltaLat, centerLng! - deltaLng);
//     final topRight = LatLng(centerLat! + deltaLat, centerLng! + deltaLng);
//     final bottomRight = LatLng(centerLat! - deltaLat, centerLng! + deltaLng);
//     final bottomLeft = LatLng(centerLat! - deltaLat, centerLng! - deltaLng);

//     final polygonPoints = [topLeft, topRight, bottomRight, bottomLeft];

//     final userPoint = (userLat != null && userLng != null)
//         ? LatLng(userLat!, userLng!)
//         : LatLng(centerLat!, centerLng!);

//     return ClipRRect(
//       borderRadius: BorderRadius.circular(12),
//       child: SizedBox(
//         height: 300,
//         child: FlutterMap(
//           options: MapOptions(
//             center: LatLng(centerLat!, centerLng!),
//             zoom: 18,
//             maxZoom: 19,
//             minZoom: 10,
//           ),
//           children: [
//             TileLayer(
//               urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
//               userAgentPackageName: 'com.example.safewalk',
//             ),
//             PolygonLayer(
//               polygons: [
//                 Polygon(
//                   points: polygonPoints,
//                   color: Colors.blue.withOpacity(0.2),
//                   borderColor: Colors.blueAccent,
//                   borderStrokeWidth: 2,
//                   isFilled: true,
//                 ),
//               ],
//             ),
//             MarkerLayer(
//               markers: [
//                 // Marker hiển thị diện tích vùng
//                 Marker(
//                   point: LatLng(centerLat!, centerLng!),
//                   width: 100,
//                   height: 40,
//                   builder: (_) => Container(
//                     width: 60,
//                     height: 60,
//                     decoration: BoxDecoration(
//                       color: Colors.red,
//                       shape: BoxShape.circle,
//                       border: Border.all(
//                         color: Colors.white,
//                         width: 3,
//                       ),
//                       boxShadow: [
//                         BoxShadow(
//                           color: Colors.red.withOpacity(0.8),
//                           blurRadius: 16,
//                           spreadRadius: 4,
//                         ),
//                       ],
//                     ),
//                     child: const Icon(
//                       Icons.my_location,
//                       color: Colors.white,
//                       size: 32,
//                     ),
//                   ),
//                   // Container(
//                   //   alignment: Alignment.center,
//                   //   padding: const EdgeInsets.symmetric(
//                   //       horizontal: 10, vertical: 6),
//                   //   decoration: BoxDecoration(
//                   //     color: Colors.orange,
//                   //     borderRadius: BorderRadius.circular(8),
//                   //     boxShadow: [
//                   //       BoxShadow(
//                   //         color: Colors.black.withOpacity(0.3),
//                   //         blurRadius: 6,
//                   //       ),
//                   //     ],
//                   //   ),
//                   //   child: Text(
//                   //     '${areaSquareMeters.toStringAsFixed(0)} m²',
//                   //     style: const TextStyle(
//                   //       color: Colors.white,
//                   //       fontWeight: FontWeight.bold,
//                   //       fontSize: 13,
//                   //     ),
//                   //   ),
//                   // ),
//                 ),
//                 // User position marker
//                 if (userLat != null && userLng != null)
//                   Marker(
//                     point: userPoint,
//                     width: 30,
//                     height: 30,
//                     builder: (_) => Container(
//                       decoration: BoxDecoration(
//                         color: Colors.green,
//                         shape: BoxShape.circle,
//                         border: Border.all(color: Colors.white, width: 2),
//                         boxShadow: [
//                           BoxShadow(
//                             color: Colors.green.withOpacity(0.6),
//                             blurRadius: 6,
//                             spreadRadius: 1,
//                           ),
//                         ],
//                       ),
//                       child: const Icon(
//                         Icons.person_pin_circle,
//                         color: Colors.white,
//                         size: 18,
//                       ),
//                     ),
//                   ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
