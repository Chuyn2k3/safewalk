// import 'dart:convert';
// import 'dart:math' as math;
//
// import 'package:flutter/material.dart';
//
// class MapView extends StatefulWidget {
//   final double? centerLat;
//   final double? centerLng;
//   final double? userLat;
//   final double? userLng;
//   final double safetyRadiusMeters;
//
//   const MapView({
//     super.key,
//     required this.centerLat,
//     required this.centerLng,
//     required this.userLat,
//     required this.userLng,
//     this.safetyRadiusMeters = 5,
//   });
//
//   @override
//   State<MapView> createState() => _MapViewState();
// }
//
// class _MapViewState extends State<MapView> with SingleTickerProviderStateMixin {
//   late final AnimationController _pulseController;
//   late final Animation<double> _pulseAnimation;
//
//   // NOTE: Không hardcode token trong production. Dùng .env / remote config / CI secret.
//   static const String _mapboxToken = "YOUR_MAPBOX_TOKEN";
//
//   // Zoom phải khớp với URL static map để projection đúng.
//   static const double _staticZoom = 18.5;
//
//   // Nếu bạn thấy marker user bị lệch so với nền ảnh, thử đổi tileSize sang 512.
//   static const double _tileSize = 256.0;
//
//   @override
//   void initState() {
//     super.initState();
//     _pulseController = AnimationController(
//       duration: const Duration(milliseconds: 1500),
//       vsync: this,
//     )..repeat();
//     _pulseAnimation = Tween<double>(begin: 0, end: 8).animate(_pulseController);
//   }
//
//   @override
//   void dispose() {
//     _pulseController.dispose();
//     super.dispose();
//   }
//
//   // ---------------------------
//   // Distance helpers
//   // ---------------------------
//   double _degToRad(double degrees) => degrees * math.pi / 180.0;
//
//   double _calculateDistanceMeters(
//       double lat1, double lon1, double lat2, double lon2) {
//     const double earthRadiusKm = 6371.0;
//     final dLat = _degToRad(lat2 - lat1);
//     final dLon = _degToRad(lon2 - lon1);
//     final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
//         math.cos(_degToRad(lat1)) *
//             math.cos(_degToRad(lat2)) *
//             math.sin(dLon / 2) *
//             math.sin(dLon / 2);
//     final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
//     return earthRadiusKm * c * 1000;
//   }
//
//   // ---------------------------
//   // Geo helpers: circle polygon
//   // ---------------------------
//   Map<String, double> _destinationPoint({
//     required double lat,
//     required double lon,
//     required double bearingDeg,
//     required double distanceMeters,
//   }) {
//     const double R = 6371000.0; // meters
//     final double brng = bearingDeg * math.pi / 180.0;
//     final double lat1 = lat * math.pi / 180.0;
//     final double lon1 = lon * math.pi / 180.0;
//     final double dByR = distanceMeters / R;
//
//     final double lat2 = math.asin(
//       math.sin(lat1) * math.cos(dByR) +
//           math.cos(lat1) * math.sin(dByR) * math.cos(brng),
//     );
//
//     final double lon2 = lon1 +
//         math.atan2(
//           math.sin(brng) * math.sin(dByR) * math.cos(lat1),
//           math.cos(dByR) - math.sin(lat1) * math.sin(lat2),
//         );
//
//     return {
//       "lat": lat2 * 180.0 / math.pi,
//       "lon": lon2 * 180.0 / math.pi,
//     };
//   }
//
//   Map<String, dynamic> _buildCircleFeature({
//     required double centerLat,
//     required double centerLon,
//     required double radiusMeters,
//     int steps = 72,
//     required Map<String, dynamic> styleProps,
//   }) {
//     final List<List<double>> ring = [];
//     for (int i = 0; i <= steps; i++) {
//       final bearing = (360.0 * i) / steps;
//       final p = _destinationPoint(
//         lat: centerLat,
//         lon: centerLon,
//         bearingDeg: bearing,
//         distanceMeters: radiusMeters,
//       );
//       ring.add([p["lon"]!, p["lat"]!]); // GeoJSON order: [lon, lat]
//     }
//
//     return <String, dynamic>{
//       "type": "Feature",
//       "geometry": <String, dynamic>{
//         "type": "Polygon",
//         "coordinates": <dynamic>[ring],
//       },
//       // Important: typed map, avoid `_Map<dynamic, dynamic>` cast issues
//       "properties": <String, dynamic>{...styleProps},
//     };
//   }
//
//   String _buildMapboxStaticUrl({
//     required double centerLat,
//     required double centerLon,
//     required double radiusMeters,
//     required String mapboxToken,
//     required int width,
//     required int height,
//     double zoom = _staticZoom,
//     bool retina = true,
//   }) {
//     final outer = _buildCircleFeature(
//       centerLat: centerLat,
//       centerLon: centerLon,
//       radiusMeters: radiusMeters + 3,
//       steps: 72,
//       styleProps: <String, dynamic>{
//         "stroke": "#FFA500",
//         "stroke-width": 2,
//         "stroke-opacity": 0.6,
//         "fill": "#FFA500",
//         "fill-opacity": 0.10,
//       },
//     );
//
//     final inner = _buildCircleFeature(
//       centerLat: centerLat,
//       centerLon: centerLon,
//       radiusMeters: radiusMeters,
//       steps: 72,
//       styleProps: <String, dynamic>{
//         "stroke": "#2ECC71",
//         "stroke-width": 4,
//         "stroke-opacity": 0.9,
//         "fill": "#2ECC71",
//         "fill-opacity": 0.25,
//       },
//     );
//
//     final geojson = <String, dynamic>{
//       "type": "FeatureCollection",
//       "features": <dynamic>[outer, inner],
//     };
//
//     final encoded = Uri.encodeComponent(jsonEncode(geojson));
//     final scale = retina ? "@2x" : "";
//
//     // Endpoint mẫu:
//     // https://api.mapbox.com/styles/v1/mapbox/streets-v12/static/geojson({geojson})/{lon},{lat},{zoom}/{w}x{h}@2x?access_token=...
//     return "https://api.mapbox.com/styles/v1/mapbox/streets-v12/static/"
//         "geojson($encoded)/"
//         "$centerLon,$centerLat,$zoom/"
//         "${width}x$height$scale"
//         "?access_token=$mapboxToken";
//   }
//
//   // ---------------------------
//   // Projection: lat/lon -> pixel offset on the static image
//   // ---------------------------
//   _MercatorPoint _projectWebMercator(double lat, double lon, double zoom) {
//     final scale = _tileSize * math.pow(2.0, zoom);
//     final x = (lon + 180.0) / 360.0 * scale;
//
//     final sinLat = math.sin(lat * math.pi / 180.0);
//     final y =
//         (0.5 - math.log((1 + sinLat) / (1 - sinLat)) / (4 * math.pi)) * scale;
//
//     return _MercatorPoint(x, y);
//   }
//
//   Offset _latLngToImageOffset({
//     required double lat,
//     required double lon,
//     required double centerLat,
//     required double centerLon,
//     required double zoom,
//     required double imageWidth,
//     required double imageHeight,
//   }) {
//     final c = _projectWebMercator(centerLat, centerLon, zoom);
//     final p = _projectWebMercator(lat, lon, zoom);
//
//     final dx = (p.x - c.x) + imageWidth / 2.0;
//     final dy = (p.y - c.y) + imageHeight / 2.0;
//
//     return Offset(dx, dy);
//   }
//
//   double _clamp(double v, double min, double max) =>
//       v < min ? min : (v > max ? max : v);
//
//   // ---------------------------
//   // UI widgets
//   // ---------------------------
//   Widget _buildCenterMarker() {
//     return SizedBox(
//       width: 80,
//       height: 80,
//       child: Stack(
//         alignment: Alignment.center,
//         children: [
//           AnimatedBuilder(
//             animation: _pulseAnimation,
//             builder: (context, child) {
//               return Container(
//                 width: 60 + _pulseAnimation.value * 2,
//                 height: 60 + _pulseAnimation.value * 2,
//                 decoration: BoxDecoration(
//                   shape: BoxShape.circle,
//                   border: Border.all(
//                     color: Colors.red
//                         .withOpacity(0.3 - _pulseAnimation.value / 60),
//                     width: 1.5,
//                   ),
//                 ),
//               );
//             },
//           ),
//           Container(
//             width: 60,
//             height: 60,
//             decoration: BoxDecoration(
//               color: Colors.red,
//               shape: BoxShape.circle,
//               border: Border.all(color: Colors.white, width: 3),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.red.withOpacity(0.8),
//                   blurRadius: 16,
//                   spreadRadius: 4,
//                 ),
//               ],
//             ),
//             child: const Icon(Icons.location_on, color: Colors.white, size: 32),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildUserMarker() {
//     return Container(
//       width: 20,
//       height: 20,
//       decoration: BoxDecoration(
//         color: Colors.blue,
//         shape: BoxShape.circle,
//         border: Border.all(color: Colors.white, width: 2.5),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.blue.withOpacity(0.7),
//             blurRadius: 12,
//             spreadRadius: 2,
//           ),
//         ],
//       ),
//       child: const Icon(Icons.my_location, color: Colors.white, size: 12),
//     );
//   }
//
//   Widget _buildBadge(bool isInsideZone) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
//       decoration: BoxDecoration(
//         color: isInsideZone ? Colors.red.shade600 : Colors.green.shade600,
//         borderRadius: BorderRadius.circular(24),
//         border: Border.all(color: Colors.white, width: 2),
//         boxShadow: [
//           BoxShadow(
//             color: (isInsideZone ? Colors.red.shade600 : Colors.green.shade600)
//                 .withOpacity(0.6),
//             blurRadius: 12,
//             spreadRadius: 2,
//           ),
//         ],
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(
//             isInsideZone ? Icons.check_circle : Icons.warning_amber,
//             color: Colors.white,
//             size: 16,
//           ),
//           const SizedBox(width: 8),
//           Text(
//             isInsideZone ? 'SAFE' : 'ALERT',
//             style: const TextStyle(
//               color: Colors.white,
//               fontWeight: FontWeight.bold,
//               fontSize: 13,
//               letterSpacing: 0.5,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildDistanceBox(double distanceMeters) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
//       decoration: BoxDecoration(
//         color: Colors.black.withOpacity(0.85),
//         borderRadius: BorderRadius.circular(10),
//         border: Border.all(color: Colors.white.withOpacity(0.25), width: 1.5),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.4),
//             blurRadius: 8,
//             spreadRadius: 1,
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Text(
//             'DISTANCE TO ZONE',
//             style: TextStyle(
//               color: Colors.white.withOpacity(0.6),
//               fontSize: 10,
//               fontWeight: FontWeight.w600,
//               letterSpacing: 0.3,
//             ),
//           ),
//           const SizedBox(height: 6),
//           Row(
//             mainAxisSize: MainAxisSize.min,
//             crossAxisAlignment: CrossAxisAlignment.baseline,
//             textBaseline: TextBaseline.alphabetic,
//             children: [
//               Text(
//                 distanceMeters.toStringAsFixed(1),
//                 style: const TextStyle(
//                   color: Colors.white,
//                   fontWeight: FontWeight.bold,
//                   fontSize: 20,
//                 ),
//               ),
//               const SizedBox(width: 4),
//               Text(
//                 'm',
//                 style: TextStyle(
//                   color: Colors.white.withOpacity(0.7),
//                   fontSize: 12,
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     if (widget.centerLat == null || widget.centerLng == null) {
//       return Container(
//         height: 240,
//         decoration: BoxDecoration(
//           color: Colors.grey[300],
//           borderRadius: BorderRadius.circular(12),
//         ),
//         child: const Center(child: Text("Location not available")),
//       );
//     }
//
//     final hasUser = widget.userLat != null && widget.userLng != null;
//
//     final distanceToCenter = hasUser
//         ? _calculateDistanceMeters(
//             widget.centerLat!,
//             widget.centerLng!,
//             widget.userLat!,
//             widget.userLng!,
//           )
//         : 0.0;
//
//     final isInsideZone = distanceToCenter <= widget.safetyRadiusMeters;
//
//     return ClipRRect(
//       borderRadius: BorderRadius.circular(12),
//       child: SizedBox(
//         height: 240,
//         child: LayoutBuilder(
//           builder: (context, constraints) {
//             final w = constraints.maxWidth;
//             final h = constraints.maxHeight;
//
//             final staticUrl = _buildMapboxStaticUrl(
//               centerLat: widget.centerLat!,
//               centerLon: widget.centerLng!,
//               radiusMeters: widget.safetyRadiusMeters,
//               mapboxToken: _mapboxToken,
//               width: w.round(),
//               height: h.round(),
//               zoom: _staticZoom,
//               retina: true,
//             );
//
//             final centerOffset = Offset(w / 2, h / 2);
//
//             Offset? userOffset;
//             if (hasUser) {
//               userOffset = _latLngToImageOffset(
//                 lat: widget.userLat!,
//                 lon: widget.userLng!,
//                 centerLat: widget.centerLat!,
//                 centerLon: widget.centerLng!,
//                 zoom: _staticZoom,
//                 imageWidth: w,
//                 imageHeight: h,
//               );
//
//               // Clamp để không vẽ marker ra ngoài
//               userOffset = Offset(
//                 _clamp(userOffset.dx, 0, w),
//                 _clamp(userOffset.dy, 0, h),
//               );
//             }
//
//             return Stack(
//               children: [
//                 Positioned.fill(
//                   child: Image.network(
//                     "https://kenh14cdn.com/2018/12/13/photo-1-15446701126731239074397.png",
//                     // staticUrl,
//                     fit: BoxFit.cover,
//                     errorBuilder: (context, error, stack) => Container(
//                       color: Colors.grey[300],
//                       child:
//                           const Center(child: Text("Map image failed to load")),
//                     ),
//                   ),
//                 ),
//
//                 // Dashed line user -> center
//                 if (hasUser && userOffset != null)
//                   Positioned.fill(
//                     child: CustomPaint(
//                       painter: DashedLinePainter(
//                         from: userOffset,
//                         to: centerOffset,
//                         dashLength: 8,
//                         gapLength: 6,
//                         color: Colors.white.withOpacity(0.85),
//                         strokeWidth: 2,
//                       ),
//                     ),
//                   ),
//
//                 // User marker
//                 if (hasUser && userOffset != null)
//                   Positioned(
//                     left: userOffset.dx - 10,
//                     top: userOffset.dy - 10,
//                     child: _buildUserMarker(),
//                   ),
//
//                 // Center marker + pulse
//                 Positioned(
//                   left: centerOffset.dx - 40,
//                   top: centerOffset.dy - 40,
//                   child: _buildCenterMarker(),
//                 ),
//
//                 // Badge
//                 Positioned(
//                   top: 12,
//                   right: 12,
//                   child: _buildBadge(isInsideZone),
//                 ),
//
//                 // Distance box
//                 Positioned(
//                   bottom: 12,
//                   left: 12,
//                   child: _buildDistanceBox(distanceToCenter),
//                 ),
//               ],
//             );
//           },
//         ),
//       ),
//     );
//   }
// }
//
// // ---------------------------
// // Supporting types & painters
// // ---------------------------
// class _MercatorPoint {
//   final double x;
//   final double y;
//   const _MercatorPoint(this.x, this.y);
// }
//
// class DashedLinePainter extends CustomPainter {
//   final Offset from;
//   final Offset to;
//   final double dashLength;
//   final double gapLength;
//   final Color color;
//   final double strokeWidth;
//
//   DashedLinePainter({
//     required this.from,
//     required this.to,
//     this.dashLength = 8,
//     this.gapLength = 6,
//     this.color = Colors.white,
//     this.strokeWidth = 2,
//   });
//
//   @override
//   void paint(Canvas canvas, Size size) {
//     final paint = Paint()
//       ..color = color
//       ..strokeWidth = strokeWidth
//       ..style = PaintingStyle.stroke
//       ..strokeCap = StrokeCap.round;
//
//     final total = (to - from).distance;
//     if (total <= 0) return;
//
//     final direction = (to - from) / total;
//
//     double dist = 0;
//     while (dist < total) {
//       final start = from + direction * dist;
//       final end = from + direction * math.min(dist + dashLength, total);
//       canvas.drawLine(start, end, paint);
//       dist += dashLength + gapLength;
//     }
//   }
//
//   @override
//   bool shouldRepaint(covariant DashedLinePainter oldDelegate) {
//     return oldDelegate.from != from ||
//         oldDelegate.to != to ||
//         oldDelegate.color != color ||
//         oldDelegate.strokeWidth != strokeWidth ||
//         oldDelegate.dashLength != dashLength ||
//         oldDelegate.gapLength != gapLength;
//   }
// }
import 'dart:math' as math;

import 'package:flutter/material.dart';

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
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  // NOTE: Không hardcode key trong production. Dùng .env / remote config / CI secret.
  static const String _geoapifyKey = "686dbdc4d19943e097b35f841aa696e2";

  // Zoom của ảnh static (phải khớp với projection để user marker không lệch)
  static const double _staticZoom = 18.5;

  // WebMercator tileSize phổ biến: 256. Nếu thấy lệch, thử đổi 512.
  static const double _tileSize = 256.0;

  // Earth radius for WebMercator meters-per-pixel
  static const double _earthRadius = 6378137.0;

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

  // ---------------------------
  // Distance helpers
  // ---------------------------
  double _degToRad(double degrees) => degrees * math.pi / 180.0;

  double _calculateDistanceMeters(
      double lat1, double lon1, double lat2, double lon2) {
    const double earthRadiusKm = 6371.0;
    final dLat = _degToRad(lat2 - lat1);
    final dLon = _degToRad(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degToRad(lat1)) *
            math.cos(_degToRad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c * 1000;
  }

  // ---------------------------
  // Geoapify static map URL
  // ---------------------------
  String _buildGeoapifyStaticUrl({
    required double centerLat,
    required double centerLon,
    required int width,
    required int height,
    required double zoom,
    required String apiKey,
  }) {
    final uri = Uri.https(
      "maps.geoapify.com",
      "/v1/staticmap",
      <String, String>{
        "style": "osm-bright", // ✅ CHUẨN
        // hoặc "osm-carto"
        "width": width.toString(),
        "height": height.toString(),
        "center": "lonlat:$centerLon,$centerLat",
        "zoom": zoom.toString(),
        "apiKey": apiKey,
      },
    );
    return uri.toString();
  }

  // ---------------------------
  // Projection: lat/lon -> pixel offset on the static image (WebMercator)
  // ---------------------------
  _MercatorPoint _projectWebMercator(double lat, double lon, double zoom) {
    final scale = _tileSize * math.pow(2.0, zoom);
    final x = (lon + 180.0) / 360.0 * scale;

    final sinLat = math.sin(lat * math.pi / 180.0);
    final y =
        (0.5 - math.log((1 + sinLat) / (1 - sinLat)) / (4 * math.pi)) * scale;

    return _MercatorPoint(x, y);
  }

  Offset _latLngToImageOffset({
    required double lat,
    required double lon,
    required double centerLat,
    required double centerLon,
    required double zoom,
    required double imageWidth,
    required double imageHeight,
  }) {
    final c = _projectWebMercator(centerLat, centerLon, zoom);
    final p = _projectWebMercator(lat, lon, zoom);

    final dx = (p.x - c.x) + imageWidth / 2.0;
    final dy = (p.y - c.y) + imageHeight / 2.0;

    return Offset(dx, dy);
  }

  double _clamp(double v, double min, double max) =>
      v < min ? min : (v > max ? max : v);

  // ---------------------------
  // meters -> pixels at given zoom and latitude
  // ---------------------------
  double _metersPerPixel({
    required double lat,
    required double zoom,
  }) {
    // meters per pixel = cos(lat) * 2πR / (tileSize * 2^zoom)
    final latRad = _degToRad(lat);
    final denom = _tileSize * math.pow(2.0, zoom);
    return math.cos(latRad) * 2.0 * math.pi * _earthRadius / denom;
  }

  // ---------------------------
  // UI widgets
  // ---------------------------
  Widget _buildCenterMarker() {
    return SizedBox(
      width: 80,
      height: 80,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Container(
                width: 60 + _pulseAnimation.value * 2,
                height: 60 + _pulseAnimation.value * 2,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.red
                        .withOpacity(0.3 - _pulseAnimation.value / 60),
                    width: 1.5,
                  ),
                ),
              );
            },
          ),
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.8),
                  blurRadius: 16,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: const Icon(Icons.location_on, color: Colors.white, size: 32),
          ),
        ],
      ),
    );
  }

  Widget _buildUserMarker() {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: Colors.blue,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.7),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: const Icon(Icons.my_location, color: Colors.white, size: 12),
    );
  }

  Widget _buildBadge(bool isInsideZone) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isInsideZone ? Colors.red.shade600 : Colors.green.shade600,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: (isInsideZone ? Colors.red.shade600 : Colors.green.shade600)
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
            isInsideZone ? 'ALERT' : 'SAFE',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDistanceBox(double distanceMeters) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.85),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.25), width: 1.5),
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
                distanceMeters.toStringAsFixed(1),
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
    );
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
        child: const Center(child: Text("Location not available")),
      );
    }

    final hasUser = widget.userLat != null && widget.userLng != null;

    final distanceToCenter = hasUser
        ? _calculateDistanceMeters(
            widget.centerLat!,
            widget.centerLng!,
            widget.userLat!,
            widget.userLng!,
          )
        : 0.0;

    final isInsideZone = distanceToCenter <= widget.safetyRadiusMeters;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 240,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final h = constraints.maxHeight;

            final staticUrl = _buildGeoapifyStaticUrl(
              centerLat: widget.centerLat!,
              centerLon: widget.centerLng!,
              width: w.round(),
              height: h.round(),
              zoom: _staticZoom,
              apiKey: _geoapifyKey,
            );
            print(staticUrl);
            final centerOffset = Offset(w / 2, h / 2);

            Offset? userOffset;
            if (hasUser) {
              userOffset = _latLngToImageOffset(
                lat: widget.userLat!,
                lon: widget.userLng!,
                centerLat: widget.centerLat!,
                centerLon: widget.centerLng!,
                zoom: _staticZoom,
                imageWidth: w,
                imageHeight: h,
              );

              // Clamp để không vẽ marker ra ngoài
              userOffset = Offset(
                _clamp(userOffset.dx, 0, w),
                _clamp(userOffset.dy, 0, h),
              );
            }

            // Radius in pixels for drawing circles on top of image
            final mpp =
                _metersPerPixel(lat: widget.centerLat!, zoom: _staticZoom);
            final innerRadiusPx = widget.safetyRadiusMeters / mpp;
            final outerRadiusPx = (widget.safetyRadiusMeters + 3.0) / mpp;

            return Stack(
              children: [
                Positioned.fill(
                  child: Image.network(
                    staticUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stack) => Container(
                      color: Colors.grey[300],
                      child:
                          const Center(child: Text("Map image failed to load")),
                    ),
                  ),
                ),

                // Circles overlay (outer + inner)
                Positioned.fill(
                  child: CustomPaint(
                    painter: ZoneCirclePainter(
                      center: centerOffset,
                      innerRadiusPx: innerRadiusPx,
                      outerRadiusPx: outerRadiusPx,
                    ),
                  ),
                ),

                // Dashed line user -> center
                if (hasUser && userOffset != null)
                  Positioned.fill(
                    child: CustomPaint(
                      painter: DashedLinePainter(
                        from: userOffset,
                        to: centerOffset,
                        dashLength: 8,
                        gapLength: 6,
                        color: Colors.white.withOpacity(0.85),
                        strokeWidth: 2,
                      ),
                    ),
                  ),

                // User marker

                // Center marker + pulse
                Positioned(
                  left: centerOffset.dx - 40,
                  top: centerOffset.dy - 40,
                  child: _buildCenterMarker(),
                ),
                if (hasUser && userOffset != null)
                  Positioned(
                    left: userOffset.dx - 10,
                    top: userOffset.dy - 10,
                    child: _buildUserMarker(),
                  ),

                // Badge
                Positioned(
                  top: 12,
                  right: 12,
                  child: _buildBadge(isInsideZone),
                ),

                // Distance box
                Positioned(
                  bottom: 12,
                  left: 12,
                  child: _buildDistanceBox(distanceToCenter),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ---------------------------
// Supporting types & painters
// ---------------------------
class _MercatorPoint {
  final double x;
  final double y;
  const _MercatorPoint(this.x, this.y);
}

class ZoneCirclePainter extends CustomPainter {
  final Offset center;
  final double innerRadiusPx;
  final double outerRadiusPx;

  ZoneCirclePainter({
    required this.center,
    required this.innerRadiusPx,
    required this.outerRadiusPx,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Outer zone (orange) - fill + border
    final outerFill = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.orange.withOpacity(0.10);

    final outerStroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = Colors.orange.withOpacity(0.5);

    canvas.drawCircle(center, outerRadiusPx, outerFill);
    canvas.drawCircle(center, outerRadiusPx, outerStroke);

    // Inner zone (green) - fill + border
    final innerFill = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.green.withOpacity(0.25);

    final innerStroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..color = Colors.green.shade400;

    canvas.drawCircle(center, innerRadiusPx, innerFill);
    canvas.drawCircle(center, innerRadiusPx, innerStroke);
  }

  @override
  bool shouldRepaint(covariant ZoneCirclePainter oldDelegate) {
    return oldDelegate.center != center ||
        oldDelegate.innerRadiusPx != innerRadiusPx ||
        oldDelegate.outerRadiusPx != outerRadiusPx;
  }
}

class DashedLinePainter extends CustomPainter {
  final Offset from;
  final Offset to;
  final double dashLength;
  final double gapLength;
  final Color color;
  final double strokeWidth;

  DashedLinePainter({
    required this.from,
    required this.to,
    this.dashLength = 8,
    this.gapLength = 6,
    this.color = Colors.white,
    this.strokeWidth = 2,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final total = (to - from).distance;
    if (total <= 0) return;

    final direction = (to - from) / total;

    double dist = 0;
    while (dist < total) {
      final start = from + direction * dist;
      final end = from + direction * math.min(dist + dashLength, total);
      canvas.drawLine(start, end, paint);
      dist += dashLength + gapLength;
    }
  }

  @override
  bool shouldRepaint(covariant DashedLinePainter oldDelegate) {
    return oldDelegate.from != from ||
        oldDelegate.to != to ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.dashLength != dashLength ||
        oldDelegate.gapLength != gapLength;
  }
}
