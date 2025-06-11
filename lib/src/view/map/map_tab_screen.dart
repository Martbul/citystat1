// import 'package:fast_immutable_collections/fast_immutable_collections.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:citystat1/src/model/account/account_repository.dart';
// import 'package:citystat1/src/model/auth/auth_session.dart';
// import 'package:citystat1/src/network/connectivity.dart';
// import 'package:citystat1/src/styles/lichess_icons.dart';
// import 'package:citystat1/src/styles/styles.dart';
// import 'package:citystat1/src/utils/focus_detector.dart';
// import 'package:citystat1/src/utils/l10n_context.dart';
// import 'package:citystat1/src/utils/screen.dart';
// import 'package:citystat1/src/widgets/buttons.dart';
// import 'package:citystat1/src/widgets/feedback.dart';
// import 'package:citystat1/src/widgets/misc.dart';
// import 'package:citystat1/src/widgets/platform.dart';

// // Mock data models
// class VisitedStreet {
//   final String id;
//   final String name;
//   final List<LatLng> coordinates;
//   final DateTime firstVisited;
//   final DateTime lastVisited;
//   final int visitCount;
//   final double completionPercentage;

//   const VisitedStreet({
//     required this.id,
//     required this.name,
//     required this.coordinates,
//     required this.firstVisited,
//     required this.lastVisited,
//     required this.visitCount,
//     required this.completionPercentage,
//   });
// }

// class LatLng {
//   final double latitude;
//   final double longitude;

//   const LatLng(this.latitude, this.longitude);
// }

// class MapBounds {
//   final LatLng southwest;
//   final LatLng northeast;

//   const MapBounds({required this.southwest, required this.northeast});
// }

// // Mock providers
// final visitedStreetsProvider = Provider<AsyncValue<IList<VisitedStreet>>>((ref) {
//   return AsyncValue.data(_mockVisitedStreets);
// });

// final streetStatsProvider = Provider<Map<String, dynamic>>((ref) {
//   final streets = _mockVisitedStreets;
//   return {
//     'totalStreets': streets.length,
//     'totalDistance': 45.2, // km
//     'completedStreets': streets.where((s) => s.completionPercentage == 100).length,
//     'explorationPercentage': 23.4,
//   };
// });

// // Mock data
// final _mockVisitedStreets = IList([
//   VisitedStreet(
//     id: '1',
//     name: 'Main Street',
//     coordinates: [
//       const LatLng(42.3601, -71.0589),
//       const LatLng(42.3605, -71.0580),
//       const LatLng(42.3610, -71.0570),
//     ],
//     firstVisited: DateTime.now().subtract(const Duration(days: 30)),
//     lastVisited: DateTime.now().subtract(const Duration(days: 2)),
//     visitCount: 12,
//     completionPercentage: 85.0,
//   ),
//   VisitedStreet(
//     id: '2',
//     name: 'Oak Avenue',
//     coordinates: [
//       const LatLng(42.3595, -71.0595),
//       const LatLng(42.3590, -71.0590),
//       const LatLng(42.3585, -71.0585),
//     ],
//     firstVisited: DateTime.now().subtract(const Duration(days: 15)),
//     lastVisited: DateTime.now().subtract(const Duration(days: 1)),
//     visitCount: 8,
//     completionPercentage: 100.0,
//   ),
//   VisitedStreet(
//     id: '3',
//     name: 'Pine Road',
//     coordinates: [
//       const LatLng(42.3615, -71.0575),
//       const LatLng(42.3620, -71.0565),
//       const LatLng(42.3625, -71.0555),
//     ],
//     firstVisited: DateTime.now().subtract(const Duration(days: 7)),
//     lastVisited: DateTime.now(),
//     visitCount: 3,
//     completionPercentage: 45.0,
//   ),
// ]);

// class MapTabScreen extends ConsumerStatefulWidget {
//   const MapTabScreen({super.key});

//   static Route<dynamic> buildRoute(BuildContext context) {
//     return PageRouteBuilder(
//       pageBuilder: (context, animation, _) => const MapTabScreen(),
//       transitionsBuilder: (context, animation, secondaryAnimation, child) {
//         return SlideTransition(
//           position: animation.drive(
//             Tween(begin: const Offset(1.0, 0.0), end: Offset.zero),
//           ),
//           child: child,
//         );
//       },
//     );
//   }

//   @override
//   ConsumerState<MapTabScreen> createState() => _StreetTrackingScreenState();
// }

// class _StreetTrackingScreenState extends ConsumerState<MapTabScreen> {
//   final _refreshKey = GlobalKey<RefreshIndicatorState>();
//   bool _showStreetList = false;

//   @override
//   Widget build(BuildContext context) {
//     final connectivity = ref.watch(connectivityChangesProvider);
//     final session = ref.watch(authSessionProvider);
//     final visitedStreets = ref.watch(visitedStreetsProvider);
//     final stats = ref.watch(streetStatsProvider);
//     final isTablet = isTabletOrLarger(context);

//     return connectivity.when(
//       skipLoadingOnReload: true,
//       data: (status) {
//         return FocusDetector(
//           onFocusRegained: () {
//             if (context.mounted && status.isOnline) {
//               _refreshData();
//             }
//           },
//           child: PlatformScaffold(
//             appBar: PlatformAppBar(
//               title: const Text('Street Explorer'),
//               actions: [
//                 IconButton(
//                   icon: Icon(_showStreetList ? Icons.map : Icons.list),
//                   onPressed: () {
//                     setState(() {
//                       _showStreetList = !_showStreetList;
//                     });
//                   },
//                 ),
//               ],
//             ),
//             body: RefreshIndicator.adaptive(
//               key: _refreshKey,
//               onRefresh: _refreshData,
//               child: _showStreetList
//                   ? _buildStreetList(visitedStreets, stats)
//                   : _buildMapView(visitedStreets, stats, isTablet),
//             ),
//           ),
//         );
//       },
//       error: (_, __) => const CenterLoadingIndicator(),
//       loading: () => const CenterLoadingIndicator(),
//     );
//   }

//   Widget _buildMapView(
//     AsyncValue<IList<VisitedStreet>> visitedStreets,
//     Map<String, dynamic> stats,
//     bool isTablet,
//   ) {
//     return visitedStreets.when(
//       data: (streets) => Column(
//         children: [
//           _StatsHeader(stats: stats),
//           Expanded(
//             child: isTablet
//                 ? Row(
//                     children: [
//                       Expanded(flex: 2, child: _MapWidget(streets: streets)),
//                       Expanded(child: _StreetSidebar(streets: streets)),
//                     ],
//                   )
//                 : _MapWidget(streets: streets),
//           ),
//         ],
//       ),
//       loading: () => const CenterLoadingIndicator(),
//       error: (error, _) => Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             const Icon(Icons.error_outline, size: 48),
//             const SizedBox(height: 16),
//             Text('Failed to load street data: $error'),
//             const SizedBox(height: 16),
//             FilledButton(
//               onPressed: _refreshData,
//               child: const Text('Retry'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildStreetList(
//     AsyncValue<IList<VisitedStreet>> visitedStreets,
//     Map<String, dynamic> stats,
//   ) {
//     return visitedStreets.when(
//       data: (streets) => Column(
//         children: [
//           _StatsHeader(stats: stats),
//           Expanded(
//             child: ListView.builder(
//               padding: Styles.bodySectionPadding,
//               itemCount: streets.length,
//               itemBuilder: (context, index) {
//                 return _StreetListTile(street: streets[index]);
//               },
//             ),
//           ),
//         ],
//       ),
//       loading: () => const CenterLoadingIndicator(),
//       error: (error, _) => Center(
//         child: Text('Error: $error'),
//       ),
//     );
//   }

//   Future<void> _refreshData() async {
//     // Simulate network refresh
//     await Future.delayed(const Duration(milliseconds: 500));
//   }
// }

// class _StatsHeader extends StatelessWidget {
//   const _StatsHeader({required this.stats});

//   final Map<String, dynamic> stats;

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: Styles.bodySectionPadding,
//       decoration: BoxDecoration(
//         color: Theme.of(context).colorScheme.surfaceContainerLow,
//         border: Border(
//           bottom: BorderSide(
//             color: Theme.of(context).dividerColor,
//             width: 0.5,
//           ),
//         ),
//       ),
//       child: Row(
//         children: [
//           Expanded(
//             child: _StatCard(
//               icon: Icons.route,
//               value: '${stats['totalStreets']}',
//               label: 'Streets Visited',
//             ),
//           ),
//           const SizedBox(width: 12),
//           Expanded(
//             child: _StatCard(
//               icon: Icons.straighten,
//               value: '${stats['totalDistance']} km',
//               label: 'Distance Covered',
//             ),
//           ),
//           const SizedBox(width: 12),
//           Expanded(
//             child: _StatCard(
//               icon: Icons.explore,
//               value: '${stats['explorationPercentage']}%',
//               label: 'City Explored',
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _StatCard extends StatelessWidget {
//   const _StatCard({
//     required this.icon,
//     required this.value,
//     required this.label,
//   });

//   final IconData icon;
//   final String value;
//   final String label;

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         Icon(
//           icon,
//           size: 24,
//           color: Theme.of(context).colorScheme.primary,
//         ),
//         const SizedBox(height: 4),
//         Text(
//           value,
//           style: Theme.of(context).textTheme.titleMedium?.copyWith(
//                 fontWeight: FontWeight.bold,
//               ),
//         ),
//         Text(
//           label,
//           style: Theme.of(context).textTheme.bodySmall,
//           textAlign: TextAlign.center,
//         ),
//       ],
//     );
//   }
// }

// class _MapWidget extends StatelessWidget {
//   const _MapWidget({required this.streets});

//   final IList<VisitedStreet> streets;

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       margin: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.1),
//             blurRadius: 8,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: ClipRRect(
//         borderRadius: BorderRadius.circular(12),
//         child: Stack(
//           children: [
//             // Map background
//             Container(
//               color: Theme.of(context).colorScheme.surfaceContainerHigh,
//               child: CustomPaint(
//                 painter: _MapPainter(streets: streets),
//                 size: Size.infinite,
//               ),
//             ),
//             // Map controls
//             Positioned(
//               top: 16,
//               right: 16,
//               child: Column(
//                 children: [
//                   _MapButton(
//                     icon: Icons.add,
//                     onPressed: () {},
//                   ),
//                   const SizedBox(height: 8),
//                   _MapButton(
//                     icon: Icons.remove,
//                     onPressed: () {},
//                   ),
//                   const SizedBox(height: 8),
//                   _MapButton(
//                     icon: Icons.my_location,
//                     onPressed: () {},
//                   ),
//                 ],
//               ),
//             ),
//             // Legend
//             Positioned(
//               bottom: 16,
//               left: 16,
//               child: _MapLegend(),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class _MapButton extends StatelessWidget {
//   const _MapButton({
//     required this.icon,
//     required this.onPressed,
//   });

//   final IconData icon;
//   final VoidCallback onPressed;

//   @override
//   Widget build(BuildContext context) {
//     return Material(
//       color: Theme.of(context).colorScheme.surface,
//       borderRadius: BorderRadius.circular(8),
//       elevation: 2,
//       child: InkWell(
//         onTap: onPressed,
//         borderRadius: BorderRadius.circular(8),
//         child: Container(
//           width: 40,
//           height: 40,
//           child: Icon(
//             icon,
//             size: 20,
//             color: Theme.of(context).colorScheme.onSurface,
//           ),
//         ),
//       ),
//     );
//   }
// }

// class _MapLegend extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: Theme.of(context).colorScheme.surface.withOpacity(0.9),
//         borderRadius: BorderRadius.circular(8),
//         border: Border.all(
//           color: Theme.of(context).dividerColor,
//           width: 0.5,
//         ),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           _LegendItem(
//             color: Colors.green,
//             label: 'Fully Explored',
//           ),
//           const SizedBox(height: 4),
//           _LegendItem(
//             color: Colors.orange,
//             label: 'Partially Explored',
//           ),
//           const SizedBox(height: 4),
//           _LegendItem(
//             color: Colors.grey.shade300,
//             label: 'Unexplored',
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _LegendItem extends StatelessWidget {
//   const _LegendItem({
//     required this.color,
//     required this.label,
//   });

//   final Color color;
//   final String label;

//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         Container(
//           width: 12,
//           height: 3,
//           decoration: BoxDecoration(
//             color: color,
//             borderRadius: BorderRadius.circular(1.5),
//           ),
//         ),
//         const SizedBox(width: 8),
//         Text(
//           label,
//           style: Theme.of(context).textTheme.bodySmall,
//         ),
//       ],
//     );
//   }
// }

// class _MapPainter extends CustomPainter {
//   final IList<VisitedStreet> streets;

//   _MapPainter({required this.streets});

//   @override
//   void paint(Canvas canvas, Size size) {
//     // Draw grid background
//     final gridPaint = Paint()
//       ..color = Colors.grey.withOpacity(0.2)
//       ..strokeWidth = 0.5;

//     for (int i = 0; i <= 20; i++) {
//       final x = (size.width / 20) * i;
//       canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
//     }

//     for (int i = 0; i <= 20; i++) {
//       final y = (size.height / 20) * i;
//       canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
//     }

//     // Draw streets
//     for (final street in streets) {
//       final paint = Paint()
//         ..strokeWidth = 4
//         ..strokeCap = StrokeCap.round;

//       // Color based on completion percentage
//       if (street.completionPercentage == 100) {
//         paint.color = Colors.green;
//       } else if (street.completionPercentage > 50) {
//         paint.color = Colors.orange;
//       } else {
//         paint.color = Colors.red.withOpacity(0.7);
//       }

//       // Convert coordinates to screen coordinates (mock implementation)
//       final points = street.coordinates.map((coord) {
//         final x = ((coord.longitude + 71.0589) * 1000000) % size.width;
//         final y = ((coord.latitude - 42.3601) * 1000000) % size.height;
//         return Offset(x, y);
//       }).toList();

//       // Draw street segments
//       for (int i = 0; i < points.length - 1; i++) {
//         canvas.drawLine(points[i], points[i + 1], paint);
//       }

//       // Draw completion indicator
//       if (points.isNotEmpty) {
//         final indicatorPaint = Paint()
//           ..color = paint.color
//           ..style = PaintingStyle.fill;

//         canvas.drawCircle(points.first, 6, indicatorPaint);
        
//         // White border
//         final borderPaint = Paint()
//           ..color = Colors.white
//           ..style = PaintingStyle.stroke
//           ..strokeWidth = 2;
        
//         canvas.drawCircle(points.first, 6, borderPaint);
//       }
//     }
//   }

//   @override
//   bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
// }

// class _StreetSidebar extends StatelessWidget {
//   const _StreetSidebar({required this.streets});

//   final IList<VisitedStreet> streets;

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         border: Border(
//           left: BorderSide(
//             color: Theme.of(context).dividerColor,
//             width: 0.5,
//           ),
//         ),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             'Recent Activity',
//             style: Theme.of(context).textTheme.titleMedium?.copyWith(
//                   fontWeight: FontWeight.bold,
//                 ),
//           ),
//           const SizedBox(height: 16),
//           Expanded(
//             child: ListView.builder(
//               itemCount: streets.length,
//               itemBuilder: (context, index) {
//                 return _StreetListTile(
//                   street: streets[index],
//                   compact: true,
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _StreetListTile extends StatelessWidget {
//   const _StreetListTile({
//     required this.street,
//     this.compact = false,
//   });

//   final VisitedStreet street;
//   final bool compact;

//   @override
//   Widget build(BuildContext context) {
//     final completionColor = street.completionPercentage == 100
//         ? Colors.green
//         : street.completionPercentage > 50
//             ? Colors.orange
//             : Colors.red;

//     return Card(
//       margin: EdgeInsets.only(bottom: compact ? 8 : 12),
//       child: Padding(
//         padding: EdgeInsets.all(compact ? 12 : 16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Container(
//                   width: 12,
//                   height: 12,
//                   decoration: BoxDecoration(
//                     color: completionColor,
//                     shape: BoxShape.circle,
//                   ),
//                 ),
//                 const SizedBox(width: 8),
//                 Expanded(
//                   child: Text(
//                     street.name,
//                     style: Theme.of(context).textTheme.titleSmall?.copyWith(
//                           fontWeight: FontWeight.w600,
//                         ),
//                   ),
//                 ),
//                 Text(
//                   '${street.completionPercentage.toInt()}%',
//                   style: Theme.of(context).textTheme.bodySmall?.copyWith(
//                         color: completionColor,
//                         fontWeight: FontWeight.w600,
//                       ),
//                 ),
//               ],
//             ),
//             if (!compact) ...[
//               const SizedBox(height: 8),
//               LinearProgressIndicator(
//                 value: street.completionPercentage / 100,
//                 backgroundColor: Colors.grey.shade200,
//                 valueColor: AlwaysStoppedAnimation<Color>(completionColor),
//               ),
//               const SizedBox(height: 8),
//               Row(
//                 children: [
//                   Icon(
//                     Icons.access_time,
//                     size: 14,
//                     color: Theme.of(context).colorScheme.onSurfaceVariant,
//                   ),
//                   const SizedBox(width: 4),
//                   Text(
//                     '${street.visitCount} visits',
//                     style: Theme.of(context).textTheme.bodySmall,
//                   ),
//                   const Spacer(),
//                   Text(
//                     _formatLastVisited(street.lastVisited),
//                     style: Theme.of(context).textTheme.bodySmall,
//                   ),
//                 ],
//               ),
//             ],
//           ],
//         ),
//       ),
//     );
//   }

//   String _formatLastVisited(DateTime date) {
//     final now = DateTime.now();
//     final difference = now.difference(date);

//     if (difference.inDays == 0) {
//       return 'Today';
//     } else if (difference.inDays == 1) {
//       return 'Yesterday';
//     } else if (difference.inDays < 7) {
//       return '${difference.inDays}d ago';
//     } else {
//       return '${(difference.inDays / 7).floor()}w ago';
//     }
//   }
// }

// // import 'package:flutter/material.dart';
// // import 'package:flutter_map/flutter_map.dart';
// // import 'package:latlong2/latlong.dart';

// // class MapTabScreen extends StatefulWidget {
// //   const MapTabScreen({super.key});

// //   @override
// //   State<MapTabScreen> createState() => _MapVisitedStreetsScreenState();
// // }

// // class _MapVisitedStreetsScreenState extends State<MapTabScreen> {
// //   // 🔹 Mock: fake walked street (segment of a street)
// //   final List<LatLng> mockVisitedPath = [
// //     LatLng(37.7749, -122.4194),
// //     LatLng(37.7750, -122.4193),
// //     LatLng(37.7751, -122.4192),
// //     LatLng(37.7752, -122.4191),
// //     LatLng(37.7753, -122.7190),
// //   ];

// //   late final MapController _mapController;

// //   @override
// //   void initState() {
// //     super.initState();
// //     _mapController = MapController();

// //     // Optional: skip real location tracking for mock
// //     // _startLocationTracking();

// //     // Center the map on the mock path
// //     WidgetsBinding.instance.addPostFrameCallback((_) {
// //       if (mockVisitedPath.isNotEmpty) {
// //         _mapController.move(mockVisitedPath.last, 17); // zoom in a bit
// //       }
// //     });
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       appBar: AppBar(title: const Text("Visited Streets Map (Mock)")),
// //       body: FlutterMap(
// //         mapController: _mapController,
// //         options: MapOptions(
// //           center: mockVisitedPath.isNotEmpty ? mockVisitedPath.first : LatLng(0, 0),
// //           zoom: 15,
// //         ),
// //         children: [
// //           TileLayer(
// //             urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
// //             userAgentPackageName: 'com.example.app',
// //           ),
// //           PolylineLayer(
// //             polylines: [
// //               Polyline(
// //                 points: mockVisitedPath,
// //                 color: Colors.redAccent,
// //                 strokeWidth: 4.0,
// //               ),
// //             ],
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// // }



// import 'package:fast_immutable_collections/fast_immutable_collections.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:citystat1/src/model/account/account_repository.dart';
// import 'package:citystat1/src/model/auth/auth_session.dart';
// import 'package:citystat1/src/network/connectivity.dart';
// import 'package:citystat1/src/styles/lichess_icons.dart';
// import 'package:citystat1/src/styles/styles.dart';
// import 'package:citystat1/src/utils/focus_detector.dart';
// import 'package:citystat1/src/utils/l10n_context.dart';
// import 'package:citystat1/src/utils/screen.dart';
// import 'package:citystat1/src/widgets/buttons.dart';
// import 'package:citystat1/src/widgets/feedback.dart';
// import 'package:citystat1/src/widgets/misc.dart';
// import 'package:citystat1/src/widgets/platform.dart';

// // Mock data models
// class VisitedStreet {
//   final String id;
//   final String name;
//   final List<LatLng> coordinates;
//   final DateTime firstVisited;
//   final DateTime lastVisited;
//   final int visitCount;
//   final double completionPercentage;

//   const VisitedStreet({
//     required this.id,
//     required this.name,
//     required this.coordinates,
//     required this.firstVisited,
//     required this.lastVisited,
//     required this.visitCount,
//     required this.completionPercentage,
//   });
// }

// class LatLng {
//   final double latitude;
//   final double longitude;

//   const LatLng(this.latitude, this.longitude);
// }

// class MapBounds {
//   final LatLng southwest;
//   final LatLng northeast;

//   const MapBounds({required this.southwest, required this.northeast});
// }

// // Mock providers with realistic Boston coordinates
// final visitedStreetsProvider = Provider<AsyncValue<IList<VisitedStreet>>>((ref) {
//   return AsyncValue.data(_mockVisitedStreets);
// });

// final streetStatsProvider = Provider<Map<String, dynamic>>((ref) {
//   final streets = _mockVisitedStreets;
//   return {
//     'totalStreets': streets.length,
//     'totalDistance': 45.2, // km
//     'completedStreets': streets.where((s) => s.completionPercentage == 100).length,
//     'explorationPercentage': 23.4,
//   };
// });

// // Mock data with realistic Boston street coordinates
// final _mockVisitedStreets = IList([
//   VisitedStreet(
//     id: '1',
//     name: 'Newbury Street',
//     coordinates: [
//       const LatLng(42.3496, -71.0851),
//       const LatLng(42.3496, -71.0825),
//       const LatLng(42.3496, -71.0800),
//       const LatLng(42.3496, -71.0775),
//     ],
//     firstVisited: DateTime.now().subtract(const Duration(days: 30)),
//     lastVisited: DateTime.now().subtract(const Duration(days: 2)),
//     visitCount: 12,
//     completionPercentage: 85.0,
//   ),
//   VisitedStreet(
//     id: '2',
//     name: 'Beacon Street',
//     coordinates: [
//       const LatLng(42.3504, -71.0851),
//       const LatLng(42.3504, -71.0825),
//       const LatLng(42.3504, -71.0800),
//       const LatLng(42.3504, -71.0775),
//     ],
//     firstVisited: DateTime.now().subtract(const Duration(days: 15)),
//     lastVisited: DateTime.now().subtract(const Duration(days: 1)),
//     visitCount: 8,
//     completionPercentage: 100.0,
//   ),
//   VisitedStreet(
//     id: '3',
//     name: 'Commonwealth Avenue',
//     coordinates: [
//       const LatLng(42.3512, -71.0851),
//       const LatLng(42.3512, -71.0825),
//       const LatLng(42.3512, -71.0800),
//       const LatLng(42.3512, -71.0775),
//     ],
//     firstVisited: DateTime.now().subtract(const Duration(days: 7)),
//     lastVisited: DateTime.now(),
//     visitCount: 3,
//     completionPercentage: 45.0,
//   ),
//   VisitedStreet(
//     id: '4',
//     name: 'Boylston Street',
//     coordinates: [
//       const LatLng(42.3488, -71.0851),
//       const LatLng(42.3488, -71.0825),
//       const LatLng(42.3488, -71.0800),
//       const LatLng(42.3488, -71.0775),
//     ],
//     firstVisited: DateTime.now().subtract(const Duration(days: 20)),
//     lastVisited: DateTime.now().subtract(const Duration(days: 3)),
//     visitCount: 15,
//     completionPercentage: 92.0,
//   ),
//   VisitedStreet(
//     id: '5',
//     name: 'Marlborough Street',
//     coordinates: [
//       const LatLng(42.3500, -71.0851),
//       const LatLng(42.3500, -71.0825),
//       const LatLng(42.3500, -71.0800),
//       const LatLng(42.3500, -71.0775),
//     ],
//     firstVisited: DateTime.now().subtract(const Duration(days: 5)),
//     lastVisited: DateTime.now().subtract(const Duration(hours: 6)),
//     visitCount: 4,
//     completionPercentage: 67.0,
//   ),
// ]);

// class MapTabScreen extends ConsumerStatefulWidget {
//   const MapTabScreen({super.key});

//   static Route<dynamic> buildRoute(BuildContext context) {
//     return PageRouteBuilder(
//       pageBuilder: (context, animation, _) => const MapTabScreen(),
//       transitionsBuilder: (context, animation, secondaryAnimation, child) {
//         return SlideTransition(
//           position: animation.drive(
//             Tween(begin: const Offset(1.0, 0.0), end: Offset.zero),
//           ),
//           child: child,
//         );
//       },
//     );
//   }

//   @override
//   ConsumerState<MapTabScreen> createState() => _StreetTrackingScreenState();
// }

// class _StreetTrackingScreenState extends ConsumerState<MapTabScreen> {
//   final _refreshKey = GlobalKey<RefreshIndicatorState>();
//   bool _showStreetList = false;

//   @override
//   Widget build(BuildContext context) {
//     final connectivity = ref.watch(connectivityChangesProvider);
//     final session = ref.watch(authSessionProvider);
//     final visitedStreets = ref.watch(visitedStreetsProvider);
//     final stats = ref.watch(streetStatsProvider);
//     final isTablet = isTabletOrLarger(context);

//     return connectivity.when(
//       skipLoadingOnReload: true,
//       data: (status) {
//         return FocusDetector(
//           onFocusRegained: () {
//             if (context.mounted && status.isOnline) {
//               _refreshData();
//             }
//           },
//           child: PlatformScaffold(
//             appBar: PlatformAppBar(
//               title: const Text('Street Explorer'),
//               actions: [
//                 IconButton(
//                   icon: Icon(_showStreetList ? Icons.map : Icons.list),
//                   onPressed: () {
//                     setState(() {
//                       _showStreetList = !_showStreetList;
//                     });
//                   },
//                 ),
//               ],
//             ),
//             body: RefreshIndicator.adaptive(
//               key: _refreshKey,
//               onRefresh: _refreshData,
//               child: _showStreetList
//                   ? _buildStreetList(visitedStreets, stats)
//                   : _buildMapView(visitedStreets, stats, isTablet),
//             ),
//           ),
//         );
//       },
//       error: (_, __) => const CenterLoadingIndicator(),
//       loading: () => const CenterLoadingIndicator(),
//     );
//   }

//   Widget _buildMapView(
//     AsyncValue<IList<VisitedStreet>> visitedStreets,
//     Map<String, dynamic> stats,
//     bool isTablet,
//   ) {
//     return visitedStreets.when(
//       data: (streets) => Column(
//         children: [
//           _StatsHeader(stats: stats),
//           Expanded(
//             child: isTablet
//                 ? Row(
//                     children: [
//                       Expanded(flex: 2, child: _OpenStreetMapWidget(streets: streets)),
//                       Expanded(child: _StreetSidebar(streets: streets)),
//                     ],
//                   )
//                 : _OpenStreetMapWidget(streets: streets),
//           ),
//         ],
//       ),
//       loading: () => const CenterLoadingIndicator(),
//       error: (error, _) => Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             const Icon(Icons.error_outline, size: 48),
//             const SizedBox(height: 16),
//             Text('Failed to load street data: $error'),
//             const SizedBox(height: 16),
//             FilledButton(
//               onPressed: _refreshData,
//               child: const Text('Retry'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildStreetList(
//     AsyncValue<IList<VisitedStreet>> visitedStreets,
//     Map<String, dynamic> stats,
//   ) {
//     return visitedStreets.when(
//       data: (streets) => Column(
//         children: [
//           _StatsHeader(stats: stats),
//           Expanded(
//             child: ListView.builder(
//               padding: Styles.bodySectionPadding,
//               itemCount: streets.length,
//               itemBuilder: (context, index) {
//                 return _StreetListTile(street: streets[index]);
//               },
//             ),
//           ),
//         ],
//       ),
//       loading: () => const CenterLoadingIndicator(),
//       error: (error, _) => Center(
//         child: Text('Error: $error'),
//       ),
//     );
//   }

//   Future<void> _refreshData() async {
//     // Simulate network refresh
//     await Future.delayed(const Duration(milliseconds: 500));
//   }
// }

// class _StatsHeader extends StatelessWidget {
//   const _StatsHeader({required this.stats});

//   final Map<String, dynamic> stats;

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: Styles.bodySectionPadding,
//       decoration: BoxDecoration(
//         color: Theme.of(context).colorScheme.surfaceContainerLow,
//         border: Border(
//           bottom: BorderSide(
//             color: Theme.of(context).dividerColor,
//             width: 0.5,
//           ),
//         ),
//       ),
//       child: Row(
//         children: [
//           Expanded(
//             child: _StatCard(
//               icon: Icons.route,
//               value: '${stats['totalStreets']}',
//               label: 'Streets Visited',
//             ),
//           ),
//           const SizedBox(width: 12),
//           Expanded(
//             child: _StatCard(
//               icon: Icons.straighten,
//               value: '${stats['totalDistance']} km',
//               label: 'Distance Covered',
//             ),
//           ),
//           const SizedBox(width: 12),
//           Expanded(
//             child: _StatCard(
//               icon: Icons.explore,
//               value: '${stats['explorationPercentage']}%',
//               label: 'City Explored',
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _StatCard extends StatelessWidget {
//   const _StatCard({
//     required this.icon,
//     required this.value,
//     required this.label,
//   });

//   final IconData icon;
//   final String value;
//   final String label;

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         Icon(
//           icon,
//           size: 24,
//           color: Theme.of(context).colorScheme.primary,
//         ),
//         const SizedBox(height: 4),
//         Text(
//           value,
//           style: Theme.of(context).textTheme.titleMedium?.copyWith(
//                 fontWeight: FontWeight.bold,
//               ),
//         ),
//         Text(
//           label,
//           style: Theme.of(context).textTheme.bodySmall,
//           textAlign: TextAlign.center,
//         ),
//       ],
//     );
//   }
// }

// class _OpenStreetMapWidget extends StatefulWidget {
//   const _OpenStreetMapWidget({required this.streets});

//   final IList<VisitedStreet> streets;

//   @override
//   State<_OpenStreetMapWidget> createState() => _OpenStreetMapWidgetState();
// }

// class _OpenStreetMapWidgetState extends State<_OpenStreetMapWidget> {
//   double _zoomLevel = 15.0;
//   LatLng _center = const LatLng(42.3500, -71.0825); // Boston Back Bay
  
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       margin: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.1),
//             blurRadius: 8,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: ClipRRect(
//         borderRadius: BorderRadius.circular(12),
//         child: Stack(
//           children: [
//             // OpenStreetMap tiles using HTML iframe
//             Container(
//               width: double.infinity,
//               height: double.infinity,
//               child: FutureBuilder<Widget>(
//                 future: _buildMapWidget(),
//                 builder: (context, snapshot) {
//                   if (snapshot.hasData) {
//                     return snapshot.data!;
//                   }
//                   return Container(
//                     color: Colors.grey.shade200,
//                     child: const Center(
//                       child: CircularProgressIndicator(),
//                     ),
//                   );
//                 },
//               ),
//             ),
//             // Map controls
//             Positioned(
//               top: 16,
//               right: 16,
//               child: Column(
//                 children: [
//                   _MapButton(
//                     icon: Icons.add,
//                     onPressed: () {
//                       setState(() {
//                         _zoomLevel = (_zoomLevel + 1).clamp(1.0, 18.0);
//                       });
//                     },
//                   ),
//                   const SizedBox(height: 8),
//                   _MapButton(
//                     icon: Icons.remove,
//                     onPressed: () {
//                       setState(() {
//                         _zoomLevel = (_zoomLevel - 1).clamp(1.0, 18.0);
//                       });
//                     },
//                   ),
//                   const SizedBox(height: 8),
//                   _MapButton(
//                     icon: Icons.my_location,
//                     onPressed: () {
//                       setState(() {
//                         _center = const LatLng(42.3500, -71.0825);
//                         _zoomLevel = 15.0;
//                       });
//                     },
//                   ),
//                 ],
//               ),
//             ),
//             // Legend
//             Positioned(
//               bottom: 16,
//               left: 16,
//               child: _MapLegend(),
//             ),
//             // Street name overlay
//             Positioned(
//               top: 16,
//               left: 16,
//               child: _StreetInfoCard(streets: widget.streets),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Future<Widget> _buildMapWidget() async {
//     // Build HTML for OpenStreetMap with Leaflet
//     final html = '''
// <!DOCTYPE html>
// <html>
// <head>
//     <meta charset="utf-8" />
//     <meta name="viewport" content="width=device-width, initial-scale=1.0">
//     <title>Street Map</title>
//     <link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css" />
//     <style>
//         body { margin: 0; padding: 0; }
//         #map { height: 100vh; width: 100vw; }
//         .street-popup {
//             font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
//             padding: 8px 12px;
//             border-radius: 8px;
//             background: white;
//             box-shadow: 0 2px 8px rgba(0,0,0,0.15);
//         }
//         .street-name {
//             font-weight: 600;
//             font-size: 14px;
//             margin-bottom: 4px;
//         }
//         .street-progress {
//             font-size: 12px;
//             color: #666;
//         }
//     </style>
// </head>
// <body>
//     <div id="map"></div>
//     <script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>
//     <script>
//         // Initialize map centered on Boston Back Bay
//         var map = L.map('map').setView([42.3500, -71.0825], ${_zoomLevel.toInt()});
        
//         // Add OpenStreetMap tiles
//         L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
//             maxZoom: 19,
//             attribution: '© OpenStreetMap contributors'
//         }).addTo(map);
        
//         // Street data with professional styling
//         var streets = ${_generateStreetGeoJSON()};
        
//         // Function to get color based on completion
//         function getColor(completion) {
//             return completion >= 100 ? '#22c55e' :  // Green
//                    completion >= 80  ? '#3b82f6' :  // Blue  
//                    completion >= 60  ? '#f59e0b' :  // Orange
//                    completion >= 40  ? '#ef4444' :  // Red
//                                        '#9ca3af';   // Gray
//         }
        
//         // Function to get width based on completion
//         function getWidth(completion) {
//             return completion >= 80 ? 6 : 4;
//         }
        
//         // Add streets to map
//         streets.forEach(function(street) {
//             var polyline = L.polyline(street.coordinates, {
//                 color: getColor(street.completion),
//                 weight: getWidth(street.completion),
//                 opacity: 0.9,
//                 smoothFactor: 1
//             }).addTo(map);
            
//             // Add interactive popup
//             polyline.bindPopup(\`
//                 <div class="street-popup">
//                     <div class="street-name">\${street.name}</div>
//                     <div class="street-progress">\${street.completion}% explored • \${street.visits} visits</div>
//                 </div>
//             \`);
            
//             // Add glow effect on hover
//             polyline.on('mouseover', function(e) {
//                 this.setStyle({
//                     weight: getWidth(street.completion) + 2,
//                     opacity: 1.0
//                 });
//             });
            
//             polyline.on('mouseout', function(e) {
//                 this.setStyle({
//                     weight: getWidth(street.completion),
//                     opacity: 0.9
//                 });
//             });
//         });
        
//         // Fit map to show all streets
//         if (streets.length > 0) {
//             var group = new L.featureGroup(map._layers);
//             if (Object.keys(group._layers).length > 0) {
//                 map.fitBounds(group.getBounds().pad(0.1));
//             }
//         }
//     </script>
// </body>
// </html>
//     ''';

//     // For Flutter web, we can use HtmlElementView
//     // For mobile, we'll show a styled placeholder
//     return Container(
//       color: Colors.grey.shade100,
//       child: Stack(
//         children: [
//           // Background pattern to simulate map
//           CustomPaint(
//             painter: _MapBackgroundPainter(),
//             size: Size.infinite,
//           ),
//           // Professional street overlay
//           CustomPaint(
//             painter: _ProfessionalStreetPainter(
//               streets: widget.streets,
//               zoomLevel: _zoomLevel,
//               center: _center,
//             ),
//             size: Size.infinite,
//           ),
//         ],
//       ),
//     );
//   }

//   String _generateStreetGeoJSON() {
//     final streetData = widget.streets.map((street) {
//       final coords = street.coordinates.map((coord) => '[${coord.latitude}, ${coord.longitude}]').join(',');
//       return '''
//         {
//           "name": "${street.name}",
//           "coordinates": [$coords],
//           "completion": ${street.completionPercentage},
//           "visits": ${street.visitCount}
//         }
//       ''';
//     }).join(',');
    
//     return '[$streetData]';
//   }
// }

// class _MapBackgroundPainter extends CustomPainter {
//   @override
//   void paint(Canvas canvas, Size size) {
//     final paint = Paint()
//       ..color = const Color(0xFFF5F5F5)
//       ..style = PaintingStyle.fill;
    
//     canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
    
//     // Draw subtle street grid pattern
//     final gridPaint = Paint()
//       ..color = Colors.white
//       ..strokeWidth = 1;
    
//     // Vertical lines
//     for (int i = 0; i < 20; i++) {
//       final x = (size.width / 20) * i;
//       canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
//     }
    
//     // Horizontal lines
//     for (int i = 0; i < 20; i++) {
//       final y = (size.height / 20) * i;
//       canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
//     }
    
//     // Add some building-like rectangles
//     final buildingPaint = Paint()
//       ..color = Colors.white
//       ..style = PaintingStyle.fill;
    
//     final random = [0.2, 0.7, 0.3, 0.8, 0.5, 0.9, 0.1, 0.6];
//     for (int i = 0; i < 8; i++) {
//       final x = size.width * random[i];
//       final y = size.height * random[(i + 3) % 8];
//       final width = 40.0 + (random[(i + 1) % 8] * 60);
//       final height = 30.0 + (random[(i + 2) % 8] * 50);
      
//       canvas.drawRRect(
//         RRect.fromRectAndRadius(
//           Rect.fromLTWH(x, y, width, height),
//           const Radius.circular(4),
//         ),
//         buildingPaint,
//       );
//     }
//   }

//   @override
//   bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
// }

// class _ProfessionalStreetPainter extends CustomPainter {
//   final IList<VisitedStreet> streets;
//   final double zoomLevel;
//   final LatLng center;

//   _ProfessionalStreetPainter({
//     required this.streets,
//     required this.zoomLevel,
//     required this.center,
//   });

//   @override
//   void paint(Canvas canvas, Size size) {
//     for (final street in streets) {
//       _drawStreet(canvas, size, street);
//     }
//   }

//   void _drawStreet(Canvas canvas, Size size, VisitedStreet street) {
//     // Convert lat/lng to screen coordinates
//     final points = street.coordinates.map((coord) {
//       final x = ((coord.longitude - center.longitude) * 10000 * zoomLevel) + size.width / 2;
//       final y = ((center.latitude - coord.latitude) * 10000 * zoomLevel) + size.height / 2;
//       return Offset(x, y);
//     }).toList();

//     if (points.length < 2) return;

//     // Determine colors based on completion
//     Color streetColor;
//     double strokeWidth;
    
//     if (street.completionPercentage >= 100) {
//       streetColor = const Color(0xFF22C55E); // Green
//       strokeWidth = 6.0;
//     } else if (street.completionPercentage >= 80) {
//       streetColor = const Color(0xFF3B82F6); // Blue
//       strokeWidth = 5.0;
//     } else if (street.completionPercentage >= 60) {
//       streetColor = const Color(0xFFF59E0B); // Orange
//       strokeWidth = 4.5;
//     } else if (street.completionPercentage >= 40) {
//       streetColor = const Color(0xFFEF4444); // Red
//       strokeWidth = 4.0;
//     } else {
//       streetColor = const Color(0xFF9CA3AF); // Gray
//       strokeWidth = 3.5;
//     }

//     // Draw shadow/glow effect
//     final shadowPaint = Paint()
//       ..color = streetColor.withOpacity(0.3)
//       ..strokeWidth = strokeWidth + 2
//       ..strokeCap = StrokeCap.round
//       ..strokeJoin = StrokeJoin.round
//       ..style = PaintingStyle.stroke;

//     final path = Path();
//     path.moveTo(points[0].dx, points[0].dy);
//     for (int i = 1; i < points.length; i++) {
//       path.lineTo(points[i].dx, points[i].dy);
//     }

//     canvas.drawPath(path, shadowPaint);

//     // Draw main street line
//     final streetPaint = Paint()
//       ..color = streetColor
//       ..strokeWidth = strokeWidth
//       ..strokeCap = StrokeCap.round
//       ..strokeJoin = StrokeJoin.round
//       ..style = PaintingStyle.stroke;

//     canvas.drawPath(path, streetPaint);

//     // Add completion indicators at start and end
//     _drawCompletionIndicator(canvas, points.first, street.completionPercentage, streetColor);
//     if (points.length > 1) {
//       _drawCompletionIndicator(canvas, points.last, street.completionPercentage, streetColor);
//     }
//   }

//   void _drawCompletionIndicator(Canvas canvas, Offset position, double completion, Color color) {
//     // Outer circle (white background)
//     final outerPaint = Paint()
//       ..color = Colors.white
//       ..style = PaintingStyle.fill;
    
//     canvas.drawCircle(position, 8, outerPaint);
    
//     // Inner circle (colored)
//     final innerPaint = Paint()
//       ..color = color
//       ..style = PaintingStyle.fill;
    
//     canvas.drawCircle(position, 6, innerPaint);
    
//     // Completion ring
//     if (completion < 100) {
//       final ringPaint = Paint()
//         ..color = Colors.white
//         ..strokeWidth = 2
//         ..style = PaintingStyle.stroke;
      
//       final sweepAngle = (completion / 100) * 2 * 3.14159;
//       canvas.drawArc(
//         Rect.fromCircle(center: position, radius: 6),
//         -3.14159 / 2, // Start from top
//         sweepAngle,
//         false,
//         ringPaint,
//       );
//     }
//   }

//   @override
//   bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
// }

// class _MapButton extends StatelessWidget {
//   const _MapButton({
//     required this.icon,
//     required this.onPressed,
//   });

//   final IconData icon;
//   final VoidCallback onPressed;

//   @override
//   Widget build(BuildContext context) {
//     return Material(
//       color: Theme.of(context).colorScheme.surface,
//       borderRadius: BorderRadius.circular(8),
//       elevation: 2,
//       child: InkWell(
//         onTap: onPressed,
//         borderRadius: BorderRadius.circular(8),
//         child: Container(
//           width: 40,
//           height: 40,
//           child: Icon(
//             icon,
//             size: 20,
//             color: Theme.of(context).colorScheme.onSurface,
//           ),
//         ),
//       ),
//     );
//   }
// }

// class _MapLegend extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: Theme.of(context).colorScheme.surface.withOpacity(0.95),
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.1),
//             blurRadius: 8,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Text(
//             'Exploration Level',
//             style: Theme.of(context).textTheme.labelMedium?.copyWith(
//                   fontWeight: FontWeight.w600,
//                 ),
//           ),
//           const SizedBox(height: 8),
//           _LegendItem(color: const Color(0xFF22C55E), label: 'Complete (100%)'),
//           const SizedBox(height: 4),
//           _LegendItem(color: const Color(0xFF3B82F6), label: 'High (80-99%)'),
//           const SizedBox(height: 4),
//           _LegendItem(color: const Color(0xFFF59E0B), label: 'Medium (60-79%)'),
//           const SizedBox(height: 4),
//           _LegendItem(color: const Color(0xFFEF4444), label: 'Low (40-59%)'),
//           const SizedBox(height: 4),
//           _LegendItem(color: const Color(0xFF9CA3AF), label: 'Minimal (<40%)'),
//         ],
//       ),
//     );
//   }
// }

// class _LegendItem extends StatelessWidget {
//   const _LegendItem({
//     required this.color,
//     required this.label,
//   });

//   final Color color;
//   final String label;

//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         Container(
//           width: 16,
//           height: 4,
//           decoration: BoxDecoration(
//             color: color,
//             borderRadius: BorderRadius.circular(2),
//           ),
//         ),
//         const SizedBox(width: 8),
//         Text(
//           label,
//           style: Theme.of(context).textTheme.bodySmall,
//         ),
//       ],
//     );
//   }
// }

// class _StreetInfoCard extends StatelessWidget {
//   const _StreetInfoCard({required this.streets});

//   final IList<VisitedStreet> streets;

//   @override
//   Widget build(BuildContext context) {
//     final recentStreet = streets.isNotEmpty 
//         ? streets.reduce((a, b) => a.lastVisited.isAfter(b.lastVisited) ? a : b)
//         : null;

//     if (recentStreet == null) return const SizedBox.shrink();

//     return Container(
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: Theme.of(context).colorScheme.surface.withOpacity(0.95),
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.1),
//             blurRadius: 8,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Text(
//             'Recently Visited',
//             style: Theme.of(context).textTheme.labelMedium?.copyWith(
//                   fontWeight: FontWeight.w600,
//                 ),
//           ),
//           const SizedBox(height: 4),
//           Text(
//             recentStreet.name,
//             style: Theme.of(context).textTheme.titleSmall?.copyWith(
//                   fontWeight: FontWeight.bold,
//                 ),
//           ),
//           Text(
//             '${recentStreet.completionPercentage.toInt()}% explored',
//             style: Theme.of(context).textTheme.bodySmall?.copyWith(
//                   color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
//                 ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _StreetSidebar extends StatelessWidget {
//   const _StreetSidebar({required this.streets});

//   final IList<VisitedStreet> streets;

//   @override
//   Widget build(BuildContext context) {
//     // Sort streets by completion percentage descending
//     final sortedStreets = streets.toList()
//       ..sort((a, b) => b.completionPercentage.compareTo(a.completionPercentage));

//     return Container(
//       decoration: BoxDecoration(
//         color: Theme.of(context).colorScheme.surfaceContainerLow,
//         border: Border(
//           left: BorderSide(
//             color: Theme.of(context).dividerColor,
//             width: 0.5,
//           ),
//         ),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Padding(
//             padding: const EdgeInsets.all(16),
//             child: Text(
//               'Street Progress',
//               style: Theme.of(context).textTheme.titleMedium?.copyWith(
//                     fontWeight: FontWeight.bold,
//                   ),
//             ),
//           ),
//           Expanded(
//             child: ListView.builder(
//               padding: const EdgeInsets.symmetric(horizontal: 16),
//               itemCount: sortedStreets.length,
//               itemBuilder: (context, index) {
//                 return _CompactStreetTile(street: sortedStreets[index]);
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _CompactStreetTile extends StatelessWidget {
//   const _CompactStreetTile({required this.street});

//   final VisitedStreet street;

//   @override
//   Widget build(BuildContext context) {
//     Color progressColor;
//     if (street.completionPercentage >= 100) {
//       progressColor = const Color(0xFF22C55E);
//     } else if (street.completionPercentage >= 80) {
//       progressColor = const Color(0xFF3B82F6);
//     } else if (street.completionPercentage >= 60) {
//       progressColor = const Color(0xFFF59E0B);
//     } else if (street.completionPercentage >= 40) {
//       progressColor = const Color(0xFFEF4444);
//     } else {
//       progressColor = const Color(0xFF9CA3AF);
//     }

//     return Container(
//       margin: const EdgeInsets.only(bottom: 12),
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: Theme.of(context).colorScheme.surface,
//         borderRadius: BorderRadius.circular(8),
//         border: Border.all(
//           color: Theme.of(context).dividerColor.withOpacity(0.5),
//         ),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Expanded(
//                 child: Text(
//                   street.name,
//                   style: Theme.of(context).textTheme.bodyMedium?.copyWith(
//                         fontWeight: FontWeight.w600,
//                       ),
//                   maxLines: 1,
//                   overflow: TextOverflow.ellipsis,
//                 ),
//               ),
//               Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
//                 decoration: BoxDecoration(
//                   color: progressColor.withOpacity(0.1),
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: Text(
//                   '${street.completionPercentage.toInt()}%',
//                   style: Theme.of(context).textTheme.labelSmall?.copyWith(
//                         color: progressColor,
//                         fontWeight: FontWeight.w600,
//                       ),
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 8),
//           // Progress bar
//           Container(
//             height: 4,
//             decoration: BoxDecoration(
//               color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
//               borderRadius: BorderRadius.circular(2),
//             ),
//             child: FractionallySizedBox(
//               alignment: Alignment.centerLeft,
//               widthFactor: street.completionPercentage / 100,
//               child: Container(
//                 decoration: BoxDecoration(
//                   color: progressColor,
//                   borderRadius: BorderRadius.circular(2),
//                 ),
//               ),
//             ),
//           ),
//           const SizedBox(height: 6),
//           Row(
//             children: [
//               Icon(
//                 Icons.visibility_off_rounded,
//                 size: 14,
//                 color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
//               ),
//               const SizedBox(width: 4),
//               Text(
//                 '${street.visitCount} visits',
//                 style: Theme.of(context).textTheme.bodySmall?.copyWith(
//                       color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
//                     ),
//               ),
//               const Spacer(),
//               Text(
//                 _formatRelativeTime(street.lastVisited),
//                 style: Theme.of(context).textTheme.bodySmall?.copyWith(
//                       color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
//                     ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   String _formatRelativeTime(DateTime dateTime) {
//     final now = DateTime.now();
//     final difference = now.difference(dateTime);

//     if (difference.inDays > 0) {
//       return '${difference.inDays}d ago';
//     } else if (difference.inHours > 0) {
//       return '${difference.inHours}h ago';
//     } else if (difference.inMinutes > 0) {
//       return '${difference.inMinutes}m ago';
//     } else {
//       return 'Just now';
//     }
//   }
// }

// class _StreetListTile extends StatelessWidget {
//   const _StreetListTile({required this.street});

//   final VisitedStreet street;

//   @override
//   Widget build(BuildContext context) {
//     Color progressColor;
//     IconData statusIcon;
    
//     if (street.completionPercentage >= 100) {
//       progressColor = const Color(0xFF22C55E);
//       statusIcon = Icons.check_circle;
//     } else if (street.completionPercentage >= 80) {
//       progressColor = const Color(0xFF3B82F6);
//       statusIcon = Icons.trending_up;
//     } else if (street.completionPercentage >= 60) {
//       progressColor = const Color(0xFFF59E0B);
//       statusIcon = Icons.trending_neutral;
//     } else if (street.completionPercentage >= 40) {
//       progressColor = const Color(0xFFEF4444);
//       statusIcon = Icons.trending_down;
//     } else {
//       progressColor = const Color(0xFF9CA3AF);
//       statusIcon = Icons.radio_button_unchecked;
//     }

//     return Card(
//       margin: const EdgeInsets.only(bottom: 12),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Icon(
//                   statusIcon,
//                   color: progressColor,
//                   size: 24,
//                 ),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         street.name,
//                         style: Theme.of(context).textTheme.titleMedium?.copyWith(
//                               fontWeight: FontWeight.bold,
//                             ),
//                       ),
//                       const SizedBox(height: 2),
//                       Text(
//                         '${street.completionPercentage.toInt()}% explored',
//                         style: Theme.of(context).textTheme.bodyMedium?.copyWith(
//                               color: progressColor,
//                               fontWeight: FontWeight.w600,
//                             ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 Column(
//                   crossAxisAlignment: CrossAxisAlignment.end,
//                   children: [
//                     Text(
//                       '${street.visitCount}',
//                       style: Theme.of(context).textTheme.titleLarge?.copyWith(
//                             fontWeight: FontWeight.bold,
//                             color: Theme.of(context).colorScheme.primary,
//                           ),
//                     ),
//                     Text(
//                       'visits',
//                       style: Theme.of(context).textTheme.bodySmall,
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//             const SizedBox(height: 12),
//             // Progress bar
//             Container(
//               height: 6,
//               decoration: BoxDecoration(
//                 color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
//                 borderRadius: BorderRadius.circular(3),
//               ),
//               child: FractionallySizedBox(
//                 alignment: Alignment.centerLeft,
//                 widthFactor: street.completionPercentage / 100,
//                 child: Container(
//                   decoration: BoxDecoration(
//                     color: progressColor,
//                     borderRadius: BorderRadius.circular(3),
//                   ),
//                 ),
//               ),
//             ),
//             const SizedBox(height: 12),
//             Row(
//               children: [
//                 Icon(
//                   Icons.calendar_today,
//                   size: 16,
//                   color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
//                 ),
//                 const SizedBox(width: 6),
//                 Text(
//                   'First visited: ${_formatDate(street.firstVisited)}',
//                   style: Theme.of(context).textTheme.bodySmall?.copyWith(
//                         color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
//                       ),
//                 ),
//                 const Spacer(),
//                 Icon(
//                   Icons.access_time,
//                   size: 16,
//                   color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
//                 ),
//                 const SizedBox(width: 6),
//                 Text(
//                   'Last: ${_formatRelativeTime(street.lastVisited)}',
//                   style: Theme.of(context).textTheme.bodySmall?.copyWith(
//                         color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
//                       ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   String _formatDate(DateTime dateTime) {
//     final months = [
//       'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
//       'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
//     ];
//     return '${months[dateTime.month - 1]} ${dateTime.day}';
//   }

//   String _formatRelativeTime(DateTime dateTime) {
//     final now = DateTime.now();
//     final difference = now.difference(dateTime);

//     if (difference.inDays > 0) {
//       return '${difference.inDays}d ago';
//     } else if (difference.inHours > 0) {
//       return '${difference.inHours}h ago';
//     } else if (difference.inMinutes > 0) {
//       return '${difference.inMinutes}m ago';
//     } else {
//       return 'Just now';
//     }
//   }
// }







// import 'package:citystat1/src/styles/styles.dart';
// import 'package:citystat1/src/widgets/feedback.dart';
// import 'package:citystat1/src/widgets/platform.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:fast_immutable_collections/fast_immutable_collections.dart';

// // Mock data models (unchanged from your original)
// class VisitedStreet {
//   final String id;
//   final String name;
//   final List<LatLng> coordinates;
//   final DateTime firstVisited;
//   final DateTime lastVisited;
//   final int visitCount;
//   final double completionPercentage;

//   const VisitedStreet({
//     required this.id,
//     required this.name,
//     required this.coordinates,
//     required this.firstVisited,
//     required this.lastVisited,
//     required this.visitCount,
//     required this.completionPercentage,
//   });
// }

// // Mock providers (unchanged from your original)
// final visitedStreetsProvider = Provider<AsyncValue<IList<VisitedStreet>>>((ref) {
//   return AsyncValue.data(_mockVisitedStreets);
// });

// final streetStatsProvider = Provider<Map<String, dynamic>>((ref) {
//   final streets = _mockVisitedStreets;
//   return {
//     'totalStreets': streets.length,
//     'totalDistance': 45.2, // km
//     'completedStreets': streets.where((s) => s.completionPercentage == 100).length,
//     'explorationPercentage': 23.4,
//   };
// });

// // Mock data with realistic Boston street coordinates (unchanged)
// final _mockVisitedStreets = IList([
//   VisitedStreet(
//     id: '1',
//     name: 'Newbury Street',
//     coordinates: [
//       const LatLng(42.3496, -71.0851),
//       const LatLng(42.3496, -71.0825),
//       const LatLng(42.3496, -71.0800),
//       const LatLng(42.3496, -71.0775),
//     ],
//     firstVisited: DateTime.now().subtract(const Duration(days: 30)),
//     lastVisited: DateTime.now().subtract(const Duration(days: 2)),
//     visitCount: 12,
//     completionPercentage: 85.0,
//   ),
//   VisitedStreet(
//     id: '2',
//     name: 'Beacon Street',
//     coordinates: [
//       const LatLng(42.3504, -71.0851),
//       const LatLng(42.3504, -71.0825),
//       const LatLng(42.3504, -71.0800),
//       const LatLng(42.3504, -71.0775),
//     ],
//     firstVisited: DateTime.now().subtract(const Duration(days: 15)),
//     lastVisited: DateTime.now().subtract(const Duration(days: 1)),
//     visitCount: 8,
//     completionPercentage: 100.0,
//   ),
//   VisitedStreet(
//     id: '3',
//     name: 'Commonwealth Avenue',
//     coordinates: [
//       const LatLng(42.3512, -71.0851),
//       const LatLng(42.3512, -71.0825),
//       const LatLng(42.3512, -71.0800),
//       const LatLng(42.3512, -71.0775),
//     ],
//     firstVisited: DateTime.now().subtract(const Duration(days: 7)),
//     lastVisited: DateTime.now(),
//     visitCount: 3,
//     completionPercentage: 45.0,
//   ),
//   VisitedStreet(
//     id: '4',
//     name: 'Boylston Street',
//     coordinates: [
//       const LatLng(42.3488, -71.0851),
//       const LatLng(42.3488, -71.0825),
//       const LatLng(42.3488, -71.0800),
//       const LatLng(42.3488, -71.0775),
//     ],
//     firstVisited: DateTime.now().subtract(const Duration(days: 20)),
//     lastVisited: DateTime.now().subtract(const Duration(days: 3)),
//     visitCount: 15,
//     completionPercentage: 92.0,
//   ),
//   VisitedStreet(
//     id: '5',
//     name: 'Marlborough Street',
//     coordinates: [
//       const LatLng(42.3500, -71.0851),
//       const LatLng(42.3500, -71.0825),
//       const LatLng(42.3500, -71.0800),
//       const LatLng(42.3500, -71.0775),
//     ],
//     firstVisited: DateTime.now().subtract(const Duration(days: 5)),
//     lastVisited: DateTime.now().subtract(const Duration(hours: 6)),
//     visitCount: 4,
//     completionPercentage: 67.0,
//   ),
// ]);

// class MapTabScreen extends ConsumerStatefulWidget {
//   const MapTabScreen({super.key});

//   @override
//   ConsumerState<MapTabScreen> createState() => _StreetTrackingScreenState();
// }

// class _StreetTrackingScreenState extends ConsumerState<MapTabScreen> {
//   final _refreshKey = GlobalKey<RefreshIndicatorState>();
//   bool _showStreetList = false;

//   @override
//   Widget build(BuildContext context) {
//     final visitedStreets = ref.watch(visitedStreetsProvider);
//     final stats = ref.watch(streetStatsProvider);
//     final isTablet = MediaQuery.of(context).size.width >= 600;

//     return PlatformScaffold(
//       appBar: PlatformAppBar(
//         title: const Text('Street Explorer'),
//         actions: [
//           IconButton(
//             icon: Icon(_showStreetList ? Icons.map : Icons.list),
//             onPressed: () {
//               setState(() {
//                 _showStreetList = !_showStreetList;
//               });
//             },
//           ),
//         ],
//       ),
//       body: RefreshIndicator.adaptive(
//         key: _refreshKey,
//         onRefresh: _refreshData,
//         child: _showStreetList
//             ? _buildStreetList(visitedStreets, stats)
//             : _buildMapView(visitedStreets, stats, isTablet),
//       ),
//     );
//   }

//   Widget _buildMapView(
//     AsyncValue<IList<VisitedStreet>> visitedStreets,
//     Map<String, dynamic> stats,
//     bool isTablet,
//   ) {
//     return visitedStreets.when(
//       data: (streets) => Column(
//         children: [
//           _StatsHeader(stats: stats),
//           Expanded(
//             child: isTablet
//                 ? Row(
//                     children: [
//                       Expanded(flex: 2, child: _GoogleMapWidget(streets: streets)),
//                       Expanded(child: _StreetSidebar(streets: streets)),
//                     ],
//                   )
//                 : _GoogleMapWidget(streets: streets),
//           ),
//         ],
//       ),
//       loading: () => const CenterLoadingIndicator(),
//       error: (error, _) => Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             const Icon(Icons.error_outline, size: 48),
//             const SizedBox(height: 16),
//             Text('Failed to load street data: $error'),
//             const SizedBox(height: 16),
//             FilledButton(
//               onPressed: _refreshData,
//               child: const Text('Retry'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildStreetList(
//     AsyncValue<IList<VisitedStreet>> visitedStreets,
//     Map<String, dynamic> stats,
//   ) {
//     return visitedStreets.when(
//       data: (streets) => Column(
//         children: [
//           _StatsHeader(stats: stats),
//           Expanded(
//             child: ListView.builder(
//               padding: const EdgeInsets.all(16),
//               itemCount: streets.length,
//               itemBuilder: (context, index) {
//                 return _StreetListTile(street: streets[index]);
//               },
//             ),
//           ),
//         ],
//       ),
//       loading: () => const CenterLoadingIndicator(),
//       error: (error, _) => Center(
//         child: Text('Error: $error'),
//       ),
//     );
//   }

//   Future<void> _refreshData() async {
//     // Simulate network refresh
//     await Future.delayed(const Duration(milliseconds: 500));
//   }
// }

// class _GoogleMapWidget extends StatefulWidget {
//   final IList<VisitedStreet> streets;

//   const _GoogleMapWidget({required this.streets});

//   @override
//   State<_GoogleMapWidget> createState() => _GoogleMapWidgetState();
// }

// class _GoogleMapWidgetState extends State<_GoogleMapWidget> {
//   late GoogleMapController _mapController;
//   final CameraPosition _initialPosition = const CameraPosition(
//     target: LatLng(42.3500, -71.0825), // Boston Back Bay
//     zoom: 15,
//   );
//   final Set<Polyline> _polylines = {};
//   final Set<Marker> _markers = {};
//   BitmapDescriptor? _completedIcon;
//   BitmapDescriptor? _partialIcon;

//   @override
//   void initState() {
//     super.initState();
//     _loadCustomIcons();
//   }

//   Future<void> _loadCustomIcons() async {
//     _completedIcon = await BitmapDescriptor.fromAssetImage(
//       const ImageConfiguration(size: Size(24, 24)),
//       'assets/icons/completed_street.png', // You need to add these assets
//     );
//     _partialIcon = await BitmapDescriptor.fromAssetImage(
//       const ImageConfiguration(size: Size(24, 24)),
//       'assets/icons/partial_street.png', // You need to add these assets
//     );
//     if (mounted) setState(() {});
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Stack(
//       children: [
//         GoogleMap(
//           initialCameraPosition: _initialPosition,
//           onMapCreated: _onMapCreated,
//           polylines: _polylines,
//           markers: _markers,
//           myLocationEnabled: true,
//           myLocationButtonEnabled: false,
//           zoomControlsEnabled: false,
//           buildingsEnabled: true,
//           mapToolbarEnabled: false,
//           compassEnabled: true,
//           rotateGesturesEnabled: true,
//           tiltGesturesEnabled: true,
//           trafficEnabled: false,
//           indoorViewEnabled: false,
//         ),
//         Positioned(
//           bottom: 20,
//           right: 20,
//           child: FloatingActionButton(
//             onPressed: _centerMap,
//             child: const Icon(Icons.my_location),
//           ),
//         ),
//         Positioned(
//           top: 20,
//           right: 20,
//           child: Column(
//             children: [
//               FloatingActionButton.small(
//                 onPressed: _zoomIn,
//                 child: const Icon(Icons.add),
//               ),
//               const SizedBox(height: 8),
//               FloatingActionButton.small(
//                 onPressed: _zoomOut,
//                 child: const Icon(Icons.remove),
//               ),
//             ],
//           ),
//         ),
//         Positioned(
//           bottom: 20,
//           left: 20,
//           child: _MapLegend(),
//         ),
//       ],
//     );
//   }

//   void _onMapCreated(GoogleMapController controller) {
//     _mapController = controller;
//     _updateMapOverlays();
//   }

//   void _updateMapOverlays() {
//     _polylines.clear();
//     _markers.clear();

//     for (final street in widget.streets) {
//       final polylineId = PolylineId(street.id);
//       final color = _getStreetColor(street.completionPercentage);
//       final width = _getStreetWidth(street.completionPercentage);

//       _polylines.add(
//         Polyline(
//           polylineId: polylineId,
//           points: street.coordinates,
//           color: color,
//           width: width,
//           startCap: Cap.roundCap,
//           endCap: Cap.roundCap,
//           jointType: JointType.round,
//           patterns: street.completionPercentage < 100
//               ? [PatternItem.gap(10), PatternItem.dash(10)]
//               : [PatternItem.gap(10), PatternItem.dash(10)],
//           consumeTapEvents: true,
//           onTap: () => _showStreetInfo(street),
//         ),
//       );

//       // Add markers at start and end points
//       if (street.coordinates.isNotEmpty) {
//         _markers.add(
//           Marker(
//             markerId: MarkerId('${street.id}_start'),
//             position: street.coordinates.first,
//             icon: street.completionPercentage >= 100 ? _completedIcon! : _partialIcon!,
//             infoWindow: InfoWindow(
//               title: street.name,
//               snippet: '${street.completionPercentage}% explored',
//             ),
//           ),
//         );

//         if (street.coordinates.length > 1) {
//           _markers.add(
//             Marker(
//               markerId: MarkerId('${street.id}_end'),
//               position: street.coordinates.last,
//               icon: street.completionPercentage >= 100 ? _completedIcon! : _partialIcon!,
//               infoWindow: InfoWindow(
//                 title: street.name,
//                 snippet: '${street.completionPercentage}% explored',
//               ),
//             ),
//           );
//         }
//       }
//     }

//     setState(() {});
//   }

//   Color _getStreetColor(double completion) {
//     return completion >= 100 ? Colors.green :
//            completion >= 80 ? Colors.blue :
//            completion >= 60 ? Colors.orange :
//            completion >= 40 ? Colors.red :
//                               Colors.grey;
//   }

//   int _getStreetWidth(double completion) {
//     return completion >= 100 ? 6 :
//            completion >= 80 ? 5 :
//            completion >= 60 ? 4 :
//            completion >= 40 ? 3 :
//                              2;
//   }

//   void _showStreetInfo(VisitedStreet street) {
//     showModalBottomSheet(
//       context: context,
//       builder: (context) {
//         return Container(
//           padding: const EdgeInsets.all(16),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 street.name,
//                 style: Theme.of(context).textTheme.titleLarge?.copyWith(
//                       fontWeight: FontWeight.bold,
//                     ),
//               ),
//               const SizedBox(height: 8),
//               LinearProgressIndicator(
//                 value: street.completionPercentage / 100,
//                 backgroundColor: Colors.grey[200],
//                 color: _getStreetColor(street.completionPercentage),
//                 minHeight: 8,
//               ),
//               const SizedBox(height: 8),
//               Row(
//                 children: [
//                   Text(
//                     '${street.completionPercentage.toStringAsFixed(1)}% explored',
//                     style: Theme.of(context).textTheme.bodyMedium,
//                   ),
//                   const Spacer(),
//                   Text(
//                     '${street.visitCount} visits',
//                     style: Theme.of(context).textTheme.bodyMedium,
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 16),
//               Row(
//                 children: [
//                   const Icon(Icons.calendar_today, size: 16),
//                   const SizedBox(width: 8),
//                   Text(
//                     'First visited: ${_formatDate(street.firstVisited)}',
//                     style: Theme.of(context).textTheme.bodySmall,
//                   ),
//                   const Spacer(),
//                   const Icon(Icons.access_time, size: 16),
//                   const SizedBox(width: 8),
//                   Text(
//                     'Last: ${_formatRelativeTime(street.lastVisited)}',
//                     style: Theme.of(context).textTheme.bodySmall,
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 16),
//               SizedBox(
//                 width: double.infinity,
//                 child: ElevatedButton(
//                   onPressed: () {
//                     _zoomToStreet(street);
//                     Navigator.pop(context);
//                   },
//                   child: const Text('Zoom to Street'),
//                 ),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }

//   void _zoomToStreet(VisitedStreet street) {
//     if (street.coordinates.isEmpty) return;

//     final bounds = _calculateBounds(street.coordinates);
//     _mapController.animateCamera(
//       CameraUpdate.newLatLngBounds(bounds, 100),
//     );
//   }

//   LatLngBounds _calculateBounds(List<LatLng> coordinates) {
//     double? minLat, maxLat, minLng, maxLng;
    
//     for (final coord in coordinates) {
//       minLat = minLat == null ? coord.latitude : (coord.latitude < minLat ? coord.latitude : minLat);
//       maxLat = maxLat == null ? coord.latitude : (coord.latitude > maxLat ? coord.latitude : maxLat);
//       minLng = minLng == null ? coord.longitude : (coord.longitude < minLng ? coord.longitude : minLng);
//       maxLng = maxLng == null ? coord.longitude : (coord.longitude > maxLng ? coord.longitude : maxLng);
//     }

//     return LatLngBounds(
//       northeast: LatLng(maxLat ?? 0, maxLng ?? 0),
//       southwest: LatLng(minLat ?? 0, minLng ?? 0),
//     );
//   }

//   void _zoomIn() {
//     _mapController.getZoomLevel().then((zoom) {
//       _mapController.animateCamera(
//         CameraUpdate.zoomTo(zoom + 1),
//       );
//     });
//   }

//   void _zoomOut() {
//     _mapController.getZoomLevel().then((zoom) {
//       _mapController.animateCamera(
//         CameraUpdate.zoomTo(zoom - 1),
//       );
//     });
//   }

//   void _centerMap() {
//     _mapController.animateCamera(
//       CameraUpdate.newCameraPosition(_initialPosition),
//     );
//   }

//   String _formatDate(DateTime dateTime) {
//     final months = [
//       'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
//       'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
//     ];
//     return '${months[dateTime.month - 1]} ${dateTime.day}';
//   }

//   String _formatRelativeTime(DateTime dateTime) {
//     final now = DateTime.now();
//     final difference = now.difference(dateTime);

//     if (difference.inDays > 0) {
//       return '${difference.inDays}d ago';
//     } else if (difference.inHours > 0) {
//       return '${difference.inHours}h ago';
//     } else if (difference.inMinutes > 0) {
//       return '${difference.inMinutes}m ago';
//     } else {
//       return 'Just now';
//     }
//   }
// }

// // Rest of your existing widgets (_StatsHeader, _MapLegend, _StreetSidebar, _StreetListTile, etc.)
// // remain unchanged from your original code

// class _StatsHeader extends StatelessWidget {
//   const _StatsHeader({required this.stats});

//   final Map<String, dynamic> stats;

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: Styles.bodySectionPadding,
//       decoration: BoxDecoration(
//         color: Theme.of(context).colorScheme.surfaceContainerLow,
//         border: Border(
//           bottom: BorderSide(
//             color: Theme.of(context).dividerColor,
//             width: 0.5,
//           ),
//         ),
//       ),
//       child: Row(
//         children: [
//           Expanded(
//             child: _StatCard(
//               icon: Icons.route,
//               value: '${stats['totalStreets']}',
//               label: 'Streets Visited',
//             ),
//           ),
//           const SizedBox(width: 12),
//           Expanded(
//             child: _StatCard(
//               icon: Icons.straighten,
//               value: '${stats['totalDistance']} km',
//               label: 'Distance Covered',
//             ),
//           ),
//           const SizedBox(width: 12),
//           Expanded(
//             child: _StatCard(
//               icon: Icons.explore,
//               value: '${stats['explorationPercentage']}%',
//               label: 'City Explored',
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _StatCard extends StatelessWidget {
//   const _StatCard({
//     required this.icon,
//     required this.value,
//     required this.label,
//   });

//   final IconData icon;
//   final String value;
//   final String label;

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         Icon(
//           icon,
//           size: 24,
//           color: Theme.of(context).colorScheme.primary,
//         ),
//         const SizedBox(height: 4),
//         Text(
//           value,
//           style: Theme.of(context).textTheme.titleMedium?.copyWith(
//                 fontWeight: FontWeight.bold,
//               ),
//         ),
//         Text(
//           label,
//           style: Theme.of(context).textTheme.bodySmall,
//           textAlign: TextAlign.center,
//         ),
//       ],
//     );
//   }
// }

// class _StreetListTile extends StatelessWidget {
//   const _StreetListTile({required this.street});

//   final VisitedStreet street;

//   @override
//   Widget build(BuildContext context) {
//     Color progressColor;
//     IconData statusIcon;
    
//     if (street.completionPercentage >= 100) {
//       progressColor = const Color(0xFF22C55E);
//       statusIcon = Icons.check_circle;
//     } else if (street.completionPercentage >= 80) {
//       progressColor = const Color(0xFF3B82F6);
//       statusIcon = Icons.trending_up;
//     } else if (street.completionPercentage >= 60) {
//       progressColor = const Color(0xFFF59E0B);
//       statusIcon = Icons.trending_neutral;
//     } else if (street.completionPercentage >= 40) {
//       progressColor = const Color(0xFFEF4444);
//       statusIcon = Icons.trending_down;
//     } else {
//       progressColor = const Color(0xFF9CA3AF);
//       statusIcon = Icons.radio_button_unchecked;
//     }

//     return Card(
//       margin: const EdgeInsets.only(bottom: 12),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Icon(
//                   statusIcon,
//                   color: progressColor,
//                   size: 24,
//                 ),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         street.name,
//                         style: Theme.of(context).textTheme.titleMedium?.copyWith(
//                               fontWeight: FontWeight.bold,
//                             ),
//                       ),
//                       const SizedBox(height: 2),
//                       Text(
//                         '${street.completionPercentage.toInt()}% explored',
//                         style: Theme.of(context).textTheme.bodyMedium?.copyWith(
//                               color: progressColor,
//                               fontWeight: FontWeight.w600,
//                             ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 Column(
//                   crossAxisAlignment: CrossAxisAlignment.end,
//                   children: [
//                     Text(
//                       '${street.visitCount}',
//                       style: Theme.of(context).textTheme.titleLarge?.copyWith(
//                             fontWeight: FontWeight.bold,
//                             color: Theme.of(context).colorScheme.primary,
//                           ),
//                     ),
//                     Text(
//                       'visits',
//                       style: Theme.of(context).textTheme.bodySmall,
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//             const SizedBox(height: 12),
//             // Progress bar
//             Container(
//               height: 6,
//               decoration: BoxDecoration(
//                 color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
//                 borderRadius: BorderRadius.circular(3),
//               ),
//               child: FractionallySizedBox(
//                 alignment: Alignment.centerLeft,
//                 widthFactor: street.completionPercentage / 100,
//                 child: Container(
//                   decoration: BoxDecoration(
//                     color: progressColor,
//                     borderRadius: BorderRadius.circular(3),
//                   ),
//                 ),
//               ),
//             ),
//             const SizedBox(height: 12),
//             Row(
//               children: [
//                 Icon(
//                   Icons.calendar_today,
//                   size: 16,
//                   color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
//                 ),
//                 const SizedBox(width: 6),
//                 Text(
//                   'First visited: ${_formatDate(street.firstVisited)}',
//                   style: Theme.of(context).textTheme.bodySmall?.copyWith(
//                         color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
//                       ),
//                 ),
//                 const Spacer(),
//                 Icon(
//                   Icons.access_time,
//                   size: 16,
//                   color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
//                 ),
//                 const SizedBox(width: 6),
//                 Text(
//                   'Last: ${_formatRelativeTime(street.lastVisited)}',
//                   style: Theme.of(context).textTheme.bodySmall?.copyWith(
//                         color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
//                       ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   String _formatDate(DateTime dateTime) {
//     final months = [
//       'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
//       'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
//     ];
//     return '${months[dateTime.month - 1]} ${dateTime.day}';
//   }

//   String _formatRelativeTime(DateTime dateTime) {
//     final now = DateTime.now();
//     final difference = now.difference(dateTime);

//     if (difference.inDays > 0) {
//       return '${difference.inDays}d ago';
//     } else if (difference.inHours > 0) {
//       return '${difference.inHours}h ago';
//     } else if (difference.inMinutes > 0) {
//       return '${difference.inMinutes}m ago';
//     } else {
//       return 'Just now';
//     }
//   }
// }





// class _StreetSidebar extends StatelessWidget {
//   const _StreetSidebar({required this.streets});

//   final IList<VisitedStreet> streets;

//   @override
//   Widget build(BuildContext context) {
//     // Sort streets by completion percentage descending
//     final sortedStreets = streets.toList()
//       ..sort((a, b) => b.completionPercentage.compareTo(a.completionPercentage));

//     return Container(
//       decoration: BoxDecoration(
//         color: Theme.of(context).colorScheme.surfaceContainerLow,
//         border: Border(
//           left: BorderSide(
//             color: Theme.of(context).dividerColor,
//             width: 0.5,
//           ),
//         ),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Padding(
//             padding: const EdgeInsets.all(16),
//             child: Text(
//               'Street Progress',
//               style: Theme.of(context).textTheme.titleMedium?.copyWith(
//                     fontWeight: FontWeight.bold,
//                   ),
//             ),
//           ),
//           Expanded(
//             child: ListView.builder(
//               padding: const EdgeInsets.symmetric(horizontal: 16),
//               itemCount: sortedStreets.length,
//               itemBuilder: (context, index) {
//                 return _CompactStreetTile(street: sortedStreets[index]);
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }



// class _CompactStreetTile extends StatelessWidget {
//   const _CompactStreetTile({required this.street});

//   final VisitedStreet street;

//   @override
//   Widget build(BuildContext context) {
//     Color progressColor;
//     if (street.completionPercentage >= 100) {
//       progressColor = const Color(0xFF22C55E);
//     } else if (street.completionPercentage >= 80) {
//       progressColor = const Color(0xFF3B82F6);
//     } else if (street.completionPercentage >= 60) {
//       progressColor = const Color(0xFFF59E0B);
//     } else if (street.completionPercentage >= 40) {
//       progressColor = const Color(0xFFEF4444);
//     } else {
//       progressColor = const Color(0xFF9CA3AF);
//     }

//     return Container(
//       margin: const EdgeInsets.only(bottom: 12),
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: Theme.of(context).colorScheme.surface,
//         borderRadius: BorderRadius.circular(8),
//         border: Border.all(
//           color: Theme.of(context).dividerColor.withOpacity(0.5),
//         ),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Expanded(
//                 child: Text(
//                   street.name,
//                   style: Theme.of(context).textTheme.bodyMedium?.copyWith(
//                         fontWeight: FontWeight.w600,
//                       ),
//                   maxLines: 1,
//                   overflow: TextOverflow.ellipsis,
//                 ),
//               ),
//               Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
//                 decoration: BoxDecoration(
//                   color: progressColor.withOpacity(0.1),
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: Text(
//                   '${street.completionPercentage.toInt()}%',
//                   style: Theme.of(context).textTheme.labelSmall?.copyWith(
//                         color: progressColor,
//                         fontWeight: FontWeight.w600,
//                       ),
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 8),
//           // Progress bar
//           Container(
//             height: 4,
//             decoration: BoxDecoration(
//               color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
//               borderRadius: BorderRadius.circular(2),
//             ),
//             child: FractionallySizedBox(
//               alignment: Alignment.centerLeft,
//               widthFactor: street.completionPercentage / 100,
//               child: Container(
//                 decoration: BoxDecoration(
//                   color: progressColor,
//                   borderRadius: BorderRadius.circular(2),
//                 ),
//               ),
//             ),
//           ),
//           const SizedBox(height: 6),
//           Row(
//             children: [
//               Icon(
//                 Icons.visibility_off_rounded,
//                 size: 14,
//                 color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
//               ),
//               const SizedBox(width: 4),
//               Text(
//                 '${street.visitCount} visits',
//                 style: Theme.of(context).textTheme.bodySmall?.copyWith(
//                       color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
//                     ),
//               ),
//               const Spacer(),
//               Text(
//                 _formatRelativeTime(street.lastVisited),
//                 style: Theme.of(context).textTheme.bodySmall?.copyWith(
//                       color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
//                     ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   String _formatRelativeTime(DateTime dateTime) {
//     final now = DateTime.now();
//     final difference = now.difference(dateTime);

//     if (difference.inDays > 0) {
//       return '${difference.inDays}d ago';
//     } else if (difference.inHours > 0) {
//       return '${difference.inHours}h ago';
//     } else if (difference.inMinutes > 0) {
//       return '${difference.inMinutes}m ago';
//     } else {
//       return 'Just now';
//     }
//   }
// }



// class _MapLegend extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: Theme.of(context).colorScheme.surface.withOpacity(0.95),
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.1),
//             blurRadius: 8,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Text(
//             'Exploration Level',
//             style: Theme.of(context).textTheme.labelMedium?.copyWith(
//                   fontWeight: FontWeight.w600,
//                 ),
//           ),
//           const SizedBox(height: 8),
//           _LegendItem(color: const Color(0xFF22C55E), label: 'Complete (100%)'),
//           const SizedBox(height: 4),
//           _LegendItem(color: const Color(0xFF3B82F6), label: 'High (80-99%)'),
//           const SizedBox(height: 4),
//           _LegendItem(color: const Color(0xFFF59E0B), label: 'Medium (60-79%)'),
//           const SizedBox(height: 4),
//           _LegendItem(color: const Color(0xFFEF4444), label: 'Low (40-59%)'),
//           const SizedBox(height: 4),
//           _LegendItem(color: const Color(0xFF9CA3AF), label: 'Minimal (<40%)'),
//         ],
//       ),
//     );
//   }
// }

// class _LegendItem extends StatelessWidget {
//   const _LegendItem({
//     required this.color,
//     required this.label,
//   });

//   final Color color;
//   final String label;

//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         Container(
//           width: 16,
//           height: 4,
//           decoration: BoxDecoration(
//             color: color,
//             borderRadius: BorderRadius.circular(2),
//           ),
//         ),
//         const SizedBox(width: 8),
//         Text(
//           label,
//           style: Theme.of(context).textTheme.bodySmall,
//         ),
//       ],
//     );
//   }
// }


import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'dart:convert';

class MapTabScreen extends StatefulWidget {
  const MapTabScreen({super.key});

  @override
  State<MapTabScreen> createState() => _ORSRouteMapState();
}

class _ORSRouteMapState extends State<MapTabScreen> {
  List<LatLng> routePoints = [];

  @override
  void initState() {
    super.initState();
    fetchRoute();
  }

  Future<void> fetchRoute() async {
    const orsApiKey = '5b3ce3597851110001cf6248a403e50017c24073b3aae9f8e0719a85'; // Replace with your ORS key
    final start = [13.388860, 52.517037]; // Berlin
    final end = [13.397634, 52.529407];   // Nearby point in Berlin

    final body = {
      "coordinates": [start, end]
    };

    final response = await http.post(
      Uri.parse('https://api.openrouteservice.org/v2/directions/foot-walking/geojson'),
      headers: {
        'Authorization': orsApiKey,
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
final List<dynamic> coordsDynamic = data['features'][0]['geometry']['coordinates'] as List<dynamic>;

final List<LatLng> coords = coordsDynamic.map<LatLng>((dynamic c) {
  final List<dynamic> point = c as List<dynamic>;
  return LatLng(point[1] as double, point[0] as double);
}).toList();

setState(() {
  routePoints = coords;
});
;
    } else {
      debugPrint('Error: ${response.body}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("ORS Colored Route")),
      body: FlutterMap(
        options: MapOptions(
          center: routePoints.isNotEmpty ? routePoints[0] : LatLng(52.517037, 13.388860),
          zoom: 14.0,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
            subdomains: const ['a', 'b', 'c'],
          ),
          if (routePoints.isNotEmpty)
            PolylineLayer(
              polylines: [
                Polyline(
                  points: routePoints,
                  strokeWidth: 5.0,
                  color: Colors.blueAccent,
                )
              ],
            ),
        ],
      ),
    );
  }
}
