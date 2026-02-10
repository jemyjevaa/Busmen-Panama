import 'package:busmen_panama/ui/views/announcements_view.dart';
import 'package:busmen_panama/ui/views/login_view.dart';
import 'package:busmen_panama/ui/views/regulation_view.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:busmen_panama/core/viewmodels/home_viewmodel.dart';
import 'package:busmen_panama/core/services/language_service.dart';
import 'package:busmen_panama/core/viewmodels/schedules_viewmodel.dart';
import 'package:busmen_panama/ui/views/profile_view.dart';
import 'package:busmen_panama/ui/views/schedules_view.dart';
import 'package:busmen_panama/ui/views/lost_found_view.dart';
import 'package:busmen_panama/ui/views/password_view.dart';
import 'package:busmen_panama/ui/views/notification_view.dart';
import 'package:busmen_panama/core/viewmodels/notifications_viewmodel.dart';
import 'package:busmen_panama/core/services/models/info_schedules_model.dart'; // Added for RouteData


import '../../core/services/cache_user_session.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  bool _isMapMenuOpen = false;

  @override
  void initState() {
    super.initState();
    // Initialize location access
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HomeViewModel>().getUserLocation();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Access the viewmodels
    final viewModel = context.watch<HomeViewModel>();
    final schedulesViewModel = context.watch<SchedulesViewModel>();
    final localization = context.watch<LanguageService>();
    final notificationsViewModel = context.watch<NotificationsViewModel>();

    // Deep link handling
    if (notificationsViewModel.pendingFlyerType != null) {
      final type = notificationsViewModel.pendingFlyerType;
      notificationsViewModel.clearPendingFlyerType();
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleDeepLink(context, type!, schedulesViewModel, localization);
      });
    }

    final selectedRoute = schedulesViewModel.selectedRoute;
    final bool isRouteActive = selectedRoute != null && schedulesViewModel.isRouteActiveNow(selectedRoute);

    return Scaffold(
      drawer: _buildDrawer(context, viewModel, localization),
      body: viewModel.isLoadingLocation
          ? const Center(child: CircularProgressIndicator())
          : Builder(
              builder: (context) => Stack(
                children: [
                  GoogleMap(
                    mapType: viewModel.currentMapType,
                    initialCameraPosition: CameraPosition(
                      target: () {
                        // 1. Check currentPosition (might be company if ViewModel finished quickly)
                        if (viewModel.currentPosition != null) {
                          return LatLng(viewModel.currentPosition!.latitude, viewModel.currentPosition!.longitude);
                        }
                        // 2. Check Company LatLog directly from Session for the very first frame
                        final companyLatLog = CacheUserSession().companyLatLog;
                        if (companyLatLog != null && companyLatLog.isNotEmpty) {
                          final parts = companyLatLog.split(',');
                          if (parts.length == 2) {
                            final lat = double.tryParse(parts[0].trim());
                            final lng = double.tryParse(parts[1].trim());
                            if (lat != null && lng != null) return LatLng(lat, lng);
                          }
                        }
                        // 3. Fallback
                        return const LatLng(8.9824, -79.5199);
                      }(),
                      zoom: 15,
                    ),
                    onMapCreated: viewModel.onMapCreated,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                    padding: const EdgeInsets.only(top: 100),
                    markers: _buildMapMarkers(schedulesViewModel),
                    polylines: _buildMapPolylines(schedulesViewModel),
                  ),

                  // Top Left Menu Button
                  Positioned(
                    top: 70,
                    left: 20,
                    child: _buildCircleButton(
                      icon: Icons.menu,
                      onTap: () {
                        Scaffold.of(context).openDrawer();
                      },
                    ),
                  ),

                   // Top Center Notifications Button
                  Positioned(
                    top: 70,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: _buildNotificationButton(
                        hasUnread: notificationsViewModel.hasUnread,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const NotificationView()),
                          );
                        },
                      ),
                    ),
                  ),

                  // Top Right Map Type FAB Menu
                  Positioned(
                    top: 70,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Main Toggle Button (Custom Style)
                        _buildCircleButton(
                          icon: _isMapMenuOpen ? Icons.close : Icons.layers_outlined,
                          onTap: () {
                            setState(() {
                              _isMapMenuOpen = !_isMapMenuOpen;
                            });
                          },
                        ),
                        
                        if (_isMapMenuOpen) ...[
                          const SizedBox(height: 16),
                          // Expanded Options
                          _buildCustomOption(
                            localization.getString('normal'),
                            MapType.normal,
                            Icons.map_outlined,
                            viewModel, // Pass viewModel for checking state
                          ),
                          const SizedBox(height: 12),
                          _buildCustomOption(
                            localization.getString('satellite'),
                            MapType.satellite,
                            Icons.satellite_outlined,
                            viewModel,
                          ),
                          const SizedBox(height: 12),
                          _buildCustomOption(
                            localization.getString('hybrid'),
                            MapType.hybrid,
                            Icons.layers_outlined,
                            viewModel,
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Bottom Route Selection UI
                  Positioned(
                    bottom: 30,
                    left: 20,
                    right: 20,
                    child: FadeInUp(
                      duration: const Duration(milliseconds: 500),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              // TRACKING BANNER (PILL DESIGN)
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    if (selectedRoute != null) {
                                      _showLiveTrackingSheet(context, schedulesViewModel, localization);
                                    } else {
                                      _showRouteSelectionSheet(context, viewModel, localization);
                                    }
                                  },
                                  child: Container(
                                    height: 65,
                                    padding: const EdgeInsets.symmetric(horizontal: 20),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(35),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.12),
                                          blurRadius: 15,
                                          offset: const Offset(0, 8),
                                        ),
                                      ],
                                      border: Border.all(color: Colors.grey[100]!),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 42,
                                          height: 42,
                                          decoration: BoxDecoration(
                                            color: (isRouteActive ? const Color(0xFF064DC3) : Colors.orange).withOpacity(0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            isRouteActive ? Icons.radar_rounded : Icons.history_rounded,
                                            color: isRouteActive ? const Color(0xFF064DC3) : Colors.orange[800],
                                            size: 22,
                                          ),
                                        ),
                                        const SizedBox(width: 15),
                                        Expanded(
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                selectedRoute?.nombre ?? localization.getString('route_not_selected'),
                                                style: const TextStyle(
                                                  color: Color(0xFF333333),
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              Row(
                                                children: [
                                                  if (isRouteActive) const _BlinkingDot(),
                                                  Text(
                                                    isRouteActive ? "RASTREO EN VIVO" : "FUERA DE HORARIO",
                                                    style: TextStyle(
                                                      color: isRouteActive ? Colors.green[700] : Colors.orange[800],
                                                      fontWeight: FontWeight.w900,
                                                      fontSize: 9,
                                                      letterSpacing: 0.5,
                                                    ),
                                                  ),
                                                  if (isRouteActive && schedulesViewModel.getCurrentStop() != null) ...[
                                                    const SizedBox(width: 5),
                                                    const Text("•", style: TextStyle(color: Colors.grey, fontSize: 10)),
                                                    const SizedBox(width: 5),
                                                    Expanded(
                                                      child: Text(
                                                        schedulesViewModel.getCurrentStop()!.nombre_parada,
                                                        style: const TextStyle(
                                                          color: Color(0xFF064DC3),
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: 9,
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        Icon(Icons.unfold_more_rounded, color: Colors.grey[400], size: 20),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // YELLOW FILTER BUTTON (ENHANCED)
                              GestureDetector(
                                onTap: () {
                                  if (schedulesViewModel.selectedRoute != null && isRouteActive) {
                                    schedulesViewModel.toggleFilteredStops();
                                  }
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  width: 65,
                                  height: 65,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: schedulesViewModel.showFilteredStops 
                                        ? [Colors.green[400]!, Colors.green[700]!]
                                        : [const Color(0xFFF8B600), const Color(0xFFE5A500)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: (schedulesViewModel.showFilteredStops ? Colors.green : const Color(0xFFF8B600)).withOpacity(0.4),
                                        blurRadius: 12,
                                        spreadRadius: schedulesViewModel.showFilteredStops ? 2 : 0,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    schedulesViewModel.showFilteredStops ? Icons.layers_clear_rounded : Icons.location_searching_rounded,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 15),
                          // SELECT ROUTE BUTTON (UPGRADED)
                          SizedBox(
                            width: double.infinity,
                            height: 60,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF064DC3).withOpacity(0.3),
                                    blurRadius: 10,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: () => _showRouteSelectionSheet(context, viewModel, localization),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF064DC3),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                  padding: EdgeInsets.zero,
                                ).copyWith(
                                  backgroundColor: MaterialStateProperty.resolveWith((states) => null), // Use decoration
                                ),
                                child: Ink(
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF064DC3), Color(0xFF053E9E)],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    ),
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  child: Container(
                                    alignment: Alignment.center,
                                    child: Text(
                                      localization.getString('select_route').toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
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

  Widget _buildCustomOption(
    String label,
    MapType type,
    IconData icon,
    HomeViewModel viewModel,
  ) {
    final isSelected = viewModel.currentMapType == type;
    final primaryBlue = const Color(0xFF064DC3);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Label
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // The Custom Circular Button
        GestureDetector(
          onTap: () {
            viewModel.setMapType(type);
          },
          child: Container(
            width: 45, // Slightly smaller than main button (55)
            height: 45,
            decoration: BoxDecoration(
              color: isSelected ? primaryBlue : Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: isSelected ? Colors.white : primaryBlue,
              size: 22,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDrawer(BuildContext context, HomeViewModel viewModel, LanguageService localization) {

    return Drawer(
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(topRight: Radius.circular(20), bottomRight: Radius.circular(20)),
      ),
      width: MediaQuery.of(context).size.width * 0.75,
      child: Column(
        children: [
          // Drawer Header - Increased top padding & User Icon
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 80, bottom: 20, left: 20, right: 20), // Lowered header
            decoration: const BoxDecoration(
              color: Color(0xFF064DC3),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 160, // Slightly larger for better visibility
                  height: 75,  // Adjusted height
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.2), // Darker background for white logos
                    borderRadius: BorderRadius.circular(10), // Rounded corners instead of circle
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: viewModel.userImage != null && viewModel.userImage!.isNotEmpty
                        ? Image.network(
                            viewModel.userImage!,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => Image.asset(
                              'assets/images/logos/LogoBusmen.png',
                              fit: BoxFit.contain,
                            ),
                          )
                        : Image.asset(
                            'assets/images/logos/LogoBusmen.png',
                            fit: BoxFit.contain,
                          ),
                  ),
                ),
                const SizedBox(height: 15),
                // User Info with Icon - Always visible
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.person, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      viewModel.userName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Column(
                  children: viewModel.userEmails.map((email) => Text(
                    email,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  )).toList(),
                ),
                if (viewModel.userSide == 2) ...[
                  const SizedBox(height: 8),
                  
                ],
              ],
            ),
          ),

          // Menu Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
              children: [
                if (viewModel.userSide == 1) ...[

                  CacheUserSession().isCopaair? const SizedBox():
                  _buildDrawerItem(
                    icon: Icons.person_outline,
                    title: localization.getString('profile'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ProfileView()),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                ],
                _buildDrawerItem(
                  icon: Icons.schedule_outlined,
                  title: localization.getString('schedules'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SchedulesView()),
                    );
                  },
                ),
                const SizedBox(height: 10),
                _buildDrawerItem(
                  icon: Icons.monitor_heart_outlined,
                  title: localization.getString('monitoring_center'),
                  onTap: () {
                    Navigator.pop(context); // Close drawer
                    viewModel.makeMonitoringCall();
                  },
                ),
                const SizedBox(height: 10),
                _buildDrawerItem(
                  icon: Icons.search_outlined,
                  title: localization.getString('lost_found'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const LostFoundView()),
                    );
                  },
                ),
                const SizedBox(height: 10),
                _buildDrawerItem(
                  icon: Icons.lock_outline,
                  title: localization.getString('password'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const PasswordView()),
                    );
                  },
                ),
                const SizedBox(height: 10),

                // Information Submenu - Integrated style
                Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(horizontal: 5, vertical: 0),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF064DC3).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.info_outline, color: Color(0xFF064DC3), size: 20),
                    ),
                    title: Text(
                      localization.getString('information'),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF333333),
                        letterSpacing: 0.5,
                      ),
                    ),
                    trailing: const Icon(Icons.keyboard_arrow_down, size: 20, color: Colors.grey),
                    childrenPadding: EdgeInsets.zero,
                    children: [
                      _buildSubMenuItem(
                        localization.getString('announcements'),
                        icon: Icons.campaign_outlined,
                        onTap: () {
                          final schedulesModel = context.read<SchedulesViewModel>();
                          if (schedulesModel.bulletins.isNotEmpty) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => _FlyerStoryViewer(
                                  flyers: schedulesModel.bulletins, 
                                  title: localization.getString('announcements'),
                                ),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("No hay ${localization.getString('announcements').toLowerCase()} disponibles")),
                            );
                          }
                        },
                      ),
                      _buildSubMenuItem(
                        localization.getString('regulations'),
                        icon: Icons.gavel_outlined,
                        onTap: () {
                          final schedulesModel = context.read<SchedulesViewModel>();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => _FlyerStoryViewer(
                                flyers: schedulesModel.regulations, 
                                title: localization.getString('regulations'),
                              ),
                            ),
                          );
                        },
                      ),
                      _buildSubMenuItem(
                        localization.getString('manual'),
                        icon: Icons.menu_book_outlined,
                        onTap: () {
                          final schedulesModel = context.read<SchedulesViewModel>();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => _FlyerStoryViewer(
                                flyers: schedulesModel.manuals, 
                                title: localization.getString('manual'),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                if (viewModel.userSide == 2) ...[
                  const SizedBox(height: 10),
                  _buildDrawerItem(
                    icon: Icons.delete_outline,
                    title: localization.getString('delete_user'),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text(localization.getString('delete_user')),
                          content: const Text('¿Está seguro de que desea eliminar su cuenta? Esta acción no se puede deshacer.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text(localization.getString('cancel_btn')),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                                viewModel.deleteUser(context);
                              },
                              child: Text(localization.getString('delete_user'), style: const TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      );
                    },
                    isDestructive: true,
                  ),
                ],
                
              ],
            ),
          ),

          // Logout Button - Fixed at the very bottom
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 10, 15, 30),
            child: _buildLogoutItem(context, localization),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final color = isDestructive ? Colors.red[700]! : const Color(0xFF064DC3);
    final bgColor = isDestructive ? Colors.red.withOpacity(0.1) : const Color(0xFF064DC3).withOpacity(0.1);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 5),
      visualDensity: const VisualDensity(horizontal: 0, vertical: -1),
      horizontalTitleGap: 15,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: isDestructive ? Colors.red[700] : const Color(0xFF333333),
          letterSpacing: 0.5,
        ),
      ),
      trailing: isDestructive ? null : const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey),
      onTap: onTap,
    );
  }

  Widget _buildSubMenuItem(String title, {required IconData icon, required VoidCallback onTap}) {
    return ListTile(
      contentPadding: const EdgeInsets.only(left: 20, right: 10),
      visualDensity: const VisualDensity(horizontal: 0, vertical: -3),
      leading: Icon(icon, size: 18, color: Colors.grey[600]),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Colors.grey[700],
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 10, color: Colors.grey),
      onTap: onTap,
    );
  }

  Widget _buildLogoutItem(BuildContext context, LanguageService localization) {
    return InkWell(
      onTap: () {
        CacheUserSession().clear();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginView()),
        );
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.logout_rounded, size: 20, color: Colors.red[700]),
            ),
            const SizedBox(width: 15),
            Text(
              localization.getString('logout'), // Changed here
              style: TextStyle(
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                fontSize: 13,
                color: Colors.red[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCircleButton({ required IconData icon, required VoidCallback onTap, }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 55,
        height: 55,
        decoration: BoxDecoration(
          color: const Color(0xFF064DC3),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 27,
        ),
      ),
    );
  }

  Widget _buildNotificationButton({
    required bool hasUnread,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 55,
            height: 55,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              color: Color(0xFF064DC3),
              size: 26,
            ),
          ),
          if (hasUnread)
            Positioned(
              top: 2,
              right: 2,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _handleDeepLink(BuildContext context, String type, SchedulesViewModel schedulesModel, LanguageService localization) {
    List<FlyerData> flyers = [];
    String title = "";

    if (type == '2') {
      flyers = schedulesModel.bulletins;
      title = localization.getString('announcements');
    } else if (type == '3') {
      flyers = schedulesModel.regulations;
      title = localization.getString('regulations');
    } else if (type == '4') {
      flyers = schedulesModel.manuals;
      title = localization.getString('manual');
    }

    if (flyers.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => _FlyerStoryViewer(
            flyers: flyers, 
            title: title,
          ),
        ),
      );
    }
  }

  void _showRouteSelectionSheet(BuildContext context, HomeViewModel homeViewModel, LanguageService localization) {
    final schedulesViewModel = Provider.of<SchedulesViewModel>(context, listen: false);
    
    // Default to 'FRECUENTES' if there are recent routes, otherwise 'EN TIEMPO' or 'TODAS'
    if (schedulesViewModel.recentRoutes.isNotEmpty) {
      schedulesViewModel.setFilterOption('FRECUENTES');
    } else {
      schedulesViewModel.setFilterOption('EN TIEMPO');
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: const BoxDecoration(
            color: Color(0xFFF8FAFF), // Very light blue/white background
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 10,
                spreadRadius: 2,
              )
            ],
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 45,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 20),
              
              // Premium Tab Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Consumer<SchedulesViewModel>(
                  builder: (context, model, _) {
                    return Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Row(
                        children: [
                          _buildTabItem('filter_frequent', model, localization),
                          _buildTabItem('filter_on_time', model, localization),
                          _buildTabItem('filter_all', model, localization),
                        ],
                      ),
                    );
                  },
                ),
              ),
              
              const SizedBox(height: 15),
              
              Expanded(
                child: Consumer<SchedulesViewModel>(
                  builder: (context, model, child) {
                    if (model.isLoadingRoutes) {
                       return const Center(child: CircularProgressIndicator());
                    }
                    
                    final routes = model.filteredRoutes;

                    if (model.filterOption == 'filter_all') {
                       final groups = model.groupedRoutes;
                       if (groups.isEmpty) {
                         return _buildEmptyState(Icons.search_off, "No hay rutas disponibles");
                       }
                       return ListView.builder(
                         padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                         itemCount: groups.length,
                         itemBuilder: (context, index) {
                           final groupName = groups.keys.elementAt(index);
                           final groupRoutes = groups[groupName]!;
                           return _RouteGroupItem(groupName: groupName, routes: groupRoutes, model: model);
                         },
                       );
                    } else {
                       if (routes.isEmpty) {
                         String msg = model.filterOption == 'filter_frequent' 
                            ? localization.getString('no_routes_segment') /* Or specific 'no_recent_routes' key if added */
                            : localization.getString('no_routes_segment');
                         return _buildEmptyState(
                            model.filterOption == 'filter_frequent' ? Icons.history : Icons.timer_off, 
                            msg
                         );
                       }
                       return _buildRouteList(context, routes, model, localization);
                    }
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(IconData icon, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 15),
          Text(
            message,
            style: TextStyle(color: Colors.grey[500], fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteList(BuildContext context, List<RouteData> routes, SchedulesViewModel model, LanguageService localization) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      itemCount: routes.length,
      itemBuilder: (context, index) {
        final route = routes[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildRouteTile(context, route, model, localization),
        );
      },
    );
  }

  Widget _buildRouteTile(BuildContext context, RouteData route, SchedulesViewModel model, LanguageService localization) {
      final isSelected = model.selectedRoute?.claveruta == route.claveruta;
      final bool isActive = model.isRouteActiveNow(route);

      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF064DC3) : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF064DC3) : const Color(0xFF064DC3).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.hub_rounded, 
              color: isSelected ? Colors.white : const Color(0xFF064DC3),
              size: 22,
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  route.nombre,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: isSelected ? const Color(0xFF064DC3) : Colors.black87,
                  ),
                ),
              ),
              if (isActive)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        "LIVE",
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                "${localization.getString('schedule_label')}: ${localization.getString(route.tipo_ruta.toLowerCase())}",
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              Text(
                "${localization.getString('route_label')}: ${localization.getString(route.tramo.toLowerCase())}",
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              ),
            ],
          ),
          trailing: Icon(Icons.info_outline_rounded, size: 20, color: isSelected ? const Color(0xFF064DC3) : Colors.grey[400]),
          onTap: () => _showRouteDetailsModal(context, route, model, localization),
        ),
      );
  }

  void _showRouteDetailsModal(BuildContext context, RouteData route, SchedulesViewModel model, LanguageService localization) {
    final bool isActive = model.isRouteActiveNow(route);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.65,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 25),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF064DC3).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    route.claveruta,
                    style: const TextStyle(
                      color: Color(0xFF064DC3),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isActive ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isActive ? "RUTA ACTIVA" : "FUERA DE HORARIO",
                    style: TextStyle(
                      color: isActive ? Colors.green : Colors.orange, 
                      fontWeight: FontWeight.bold, 
                      fontSize: 10
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Text(
              route.nombre,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF064DC3),
              ),
            ),
            const SizedBox(height: 30),
            _buildDetailRow(Icons.calendar_today_rounded, localization.getString('days_label'), localization.getString(model.getActiveDays(route.dia_ruta ?? route.tipo_ruta))),
            const SizedBox(height: 20),
            _buildDetailRow(Icons.access_time_filled_rounded, localization.getString('schedule_label'), localization.getString(route.tipo_ruta.toLowerCase())),
            const SizedBox(height: 20),
            _buildDetailRow(Icons.alt_route_rounded, localization.getString('route_label'), localization.getString(route.tramo.toLowerCase())),
            const Spacer(),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "La ruta se encuentra ${isActive ? 'operando actualmente.' : 'fuera de su horario habitual.'}",
                      style: TextStyle(color: Colors.grey[700], fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () {
                  model.selectRoute(route, onRouteLoaded: () {
                    // Move camera to route after data loads
                    if (model.stops.isNotEmpty) {
                      final homeViewModel = context.read<HomeViewModel>();
                      final points = model.stops
                          .map((s) => LatLng(s.latitud, s.longitud))
                          .toList();
                      homeViewModel.moveCameraToRoute(points);
                    }
                  });
                  Navigator.pop(context); // Close details
                  Navigator.pop(context); // Close selection sheet
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF064DC3),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 0,
                ),
                child: const Text(
                  "SELECCIONAR ESTA RUTA",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  void _showLiveTrackingSheet(BuildContext context, SchedulesViewModel model, LanguageService localization) {
    if (model.selectedRoute == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Consumer<SchedulesViewModel>(
        builder: (context, model, child) {
          final stops = model.stops;
          final isRouteActive = model.isRouteActiveNow(model.selectedRoute!);
          final myStop = model.selectedUserStop;

          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                
                // HEADER with Status
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF064DC3).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.radar_rounded, color: Color(0xFF064DC3), size: 24),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              model.selectedRoute!.nombre,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF333333)),
                            ),
                            Text(
                              isRouteActive ? localization.getString('active_tracking') : localization.getString('offline_system'),
                              style: TextStyle(
                                color: isRouteActive ? Colors.green[700] : Colors.orange[800], 
                                fontSize: 10, 
                                fontWeight: FontWeight.w900, 
                                letterSpacing: 0.5
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.grey),
                        onPressed: () => Navigator.pop(context),
                      )
                    ],
                  ),
                ),
                
                // OFFLINE BANNER
                if (!isRouteActive)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.orange.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Colors.orange[800], size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            localization.getString('offline_msg'),
                            style: TextStyle(color: Colors.orange[900], fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 10),
                
                // SEARCH / MI PARADA QUICK ACTIONS
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              "${localization.getString('full_route')} (${stops.length} ${localization.getString('schedules').toUpperCase()})",
                              style: TextStyle(color: Colors.grey[600], fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: TextButton.icon(
                          onPressed: () => _showMyStopPicker(context, model, localization),
                          style: TextButton.styleFrom(
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            backgroundColor: myStop != null ? Colors.orange.withOpacity(0.1) : const Color(0xFF064DC3).withOpacity(0.05),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: myStop != null ? Colors.orange.withOpacity(0.3) : Colors.transparent)),
                          ),
                          icon: Icon(Icons.stars_rounded, color: myStop != null ? Colors.orange : const Color(0xFF064DC3), size: 18),
                          label: Text(
                            localization.getString('select_my_stop'),
                            style: TextStyle(color: myStop != null ? Colors.orange[800] : const Color(0xFF064DC3), fontSize: 12, fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1),

                // FULL STOP LIST
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    itemCount: stops.length,
                    itemBuilder: (context, index) {
                      final stop = stops[index];
                      final status = model.getStopLiveStatus(stop);
                      final isSelectedMyStop = myStop != null && 
                          myStop.claveruta == stop.claveruta && 
                          myStop.numero_parada == stop.numero_parada;
                      
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTrackingPoint(
                            title: stop.nombre_parada,
                            subtitle: stop.horario,
                            state: stop.estatus,
                            isRouteActive: isRouteActive,
                            isMyStop: isSelectedMyStop,
                            localization: localization,
                          ),
                          if (index < stops.length - 1)
                            _buildTrackingLine(
                              isActive: isRouteActive && (status == 'Ya Realizada' || status == 'Unidad en el punto'),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTrackingPoint({
    required String title,
    required String subtitle,
    required String state,
    required LanguageService localization,
    bool isRouteActive = true,
    bool isMyStop = false,
  }) {
    Color pointColor = Colors.grey[300]!;
    Widget icon = Container(
      width: 12, 
      height: 12, 
      decoration: BoxDecoration(
        color: isRouteActive ? pointColor : const Color(0xFF064DC3).withOpacity(0.1), 
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      )
    );

    if (isRouteActive) {
      if (state == 'Ya Realizada') {
        pointColor = const Color(0xFF064DC3);
        icon = const Icon(Icons.check_circle_rounded, color: Color(0xFF064DC3), size: 22);
      } else if (state == 'Unidad en el punto') {
        pointColor = Colors.green;
        icon = Container(
          padding: const EdgeInsets.all(4),
          decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
          child: const Icon(Icons.directions_bus_rounded, color: Colors.white, size: 14),
        );
      } else if (state == 'En Camino') {
        pointColor = Colors.blue;
        icon = Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.2),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.blue, width: 2),
          ),
          child: Center(
            child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle)),
          ),
        );
      }
    } else {
       // Warm up the offline state
       pointColor = const Color(0xFF064DC3).withOpacity(0.4);
    }

    // Override icon if it IS My Stop
    if (isMyStop) {
      icon = Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.stars_rounded, color: Colors.orange, size: 28),
      );
      state = localization.getString('my_stop_label');
    }

    final String translatedStatus = localization.getString(state);

    return Row(
      children: [
        SizedBox(width: 32, child: Center(child: icon)),
        const SizedBox(width: 18),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                translatedStatus.toUpperCase(),
                style: TextStyle(
                  fontWeight: FontWeight.bold, 
                  fontSize: 15, 
                  color: !isRouteActive ? const Color(0xFF064DC3).withOpacity(0.5) : (state == 'Ya Realizada' ? Colors.black54 : Colors.black87)
                ),
              ),
              if (isRouteActive)
                Text(
                  localization.getString('view_details'),
                  style: TextStyle(color: pointColor.withOpacity(0.8), fontSize: 10),
                ),
              Text(
                subtitle.toUpperCase(),
                style: TextStyle(
                  color: isMyStop ? Colors.orange : pointColor,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTrackingLine({required bool isActive, bool isDashed = false}) {
    return Container(
      margin: const EdgeInsets.only(left: 14),
      height: 40,
      width: 2,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Column(
            children: List.generate(
              isDashed ? 4 : 1,
              (index) => Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 2),
                  color: isActive ? const Color(0xFF064DC3) : Colors.grey[300],
                ),
              ),
            ),
          ),
          if (isActive)
            const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF064DC3), size: 14),
        ],
      ),
    );
  }

  Set<Marker> _buildMapMarkers(SchedulesViewModel model) {
    Set<Marker> markers = {};
    
    // 1. Unit Marker
    if (model.unit != null) {
      markers.add(Marker(
        markerId: const MarkerId('unit'),
        position: LatLng(double.tryParse(model.unit!.lat) ?? 0, double.tryParse(model.unit!.lon) ?? 0),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan),
        infoWindow: InfoWindow(title: "Unidad: ${model.unit!.economico}"),
      ));
    }

    // 2. Stop Markers
    final List<StopData> stopsToShow = model.showFilteredStops && model.unit != null
        ? [
            if (model.getPreviousStop() != null) model.getPreviousStop()!,
            if (model.getCurrentStop() != null) model.getCurrentStop()!,
            if (model.getNextStop() != null) model.getNextStop()!,
          ]
        : model.stops;

    for (var stop in stopsToShow) {
      final bool isMyStop = model.selectedUserStop?.claveruta == stop.claveruta && model.selectedUserStop?.numero_parada == stop.numero_parada;
      
      double hue = BitmapDescriptor.hueAzure; // Default
      
      if (model.showFilteredStops && model.unit != null) {
        if (stop.numero_parada == model.getPreviousStop()?.numero_parada) {
          hue = BitmapDescriptor.hueMagenta; // Using Magenta for "Black" since default hues are limited
        } else if (stop.numero_parada == model.getCurrentStop()?.numero_parada) {
          hue = BitmapDescriptor.hueGreen;
        } else if (stop.numero_parada == model.getNextStop()?.numero_parada) {
          hue = BitmapDescriptor.hueYellow;
        }
      }

      if (isMyStop) {
        hue = BitmapDescriptor.hueBlue; // User requested Blue for their stop
      }

      markers.add(Marker(
        markerId: MarkerId('stop_${stop.claveruta}_${stop.numero_parada}'),
        position: LatLng(stop.latitud, stop.longitud),
        icon: BitmapDescriptor.defaultMarkerWithHue(hue),
        infoWindow: InfoWindow(
          title: stop.nombre_parada,
          snippet: isMyStop ? "MI PARADA" : "Parada ${stop.numero_parada}",
        ),
      ));
    }

    return markers;
  }

  Set<Polyline> _buildMapPolylines(SchedulesViewModel model) {
    if (model.stops.isEmpty) return {};

    // Use filtered points if showFilteredStops is active
    final List<LatLng> points;
    if (model.showFilteredStops && model.unit != null) {
      final List<StopData> stopsToShow = [
        if (model.getPreviousStop() != null) model.getPreviousStop()!,
        if (model.getCurrentStop() != null) model.getCurrentStop()!,
        if (model.getNextStop() != null) model.getNextStop()!,
      ];
      points = stopsToShow.map((s) => LatLng(s.latitud, s.longitud)).toList();
    } else {
      // Use high-fidelity road points if available (for Special Companies), 
      // otherwise fallback to straight lines between stops.
      points = model.roadPoints.isNotEmpty 
          ? model.roadPoints 
          : model.stops.map((s) => LatLng(s.latitud, s.longitud)).toList();
    }

    if (points.length < 2) return {};

    return {
      Polyline(
        polylineId: PolylineId(model.showFilteredStops ? 'route_line_filtered' : 'route_line'),
        points: points,
        color: const Color(0xFF064DC3).withOpacity(model.showFilteredStops ? 0.8 : 0.6),
        width: model.showFilteredStops ? 6 : 5,
        geodesic: true,
        jointType: JointType.round,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
      )
    };
  }

  void _showMyStopPicker(BuildContext context, SchedulesViewModel model, LanguageService localization) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 25),
            Text(
              localization.getString('select_my_stop'), 
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF064DC3), letterSpacing: 1),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 8),
              child: Text(
                localization.getString('select_stop_desc'),
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
            ),
            const SizedBox(height: 15),
            const Divider(height: 1),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: model.stops.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final stop = model.stops[index];
                  final isSelected = model.selectedUserStop?.claveruta == stop.claveruta && model.selectedUserStop?.numero_parada == stop.numero_parada;
                  
                  return InkWell(
                    onTap: () {
                      model.selectUserStop(stop);
                      Navigator.pop(context);
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF064DC3).withOpacity(0.05) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF064DC3) : Colors.grey[200]!,
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: isSelected ? [
                          BoxShadow(color: const Color(0xFF064DC3).withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))
                        ] : [],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFF064DC3) : const Color(0xFF064DC3).withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.location_on_rounded, 
                              color: isSelected ? Colors.white : const Color(0xFF064DC3), 
                              size: 20
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  stop.nombre_parada, 
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold, 
                                    fontSize: 14,
                                    color: isSelected ? const Color(0xFF064DC3) : Colors.black87
                                  )
                                ),
                                Text(
                                  "${localization.getString('stop_number')}${stop.numero_parada}", 
                                  style: TextStyle(color: Colors.grey[500], fontSize: 11)
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            const Icon(Icons.check_circle_rounded, color: Color(0xFF064DC3), size: 24),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String title, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF064DC3).withOpacity(0.05),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: const Color(0xFF064DC3), size: 22),
        ),
        const SizedBox(width: 15),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTabItem(String label, SchedulesViewModel model, LanguageService localization) {
    final isSelected = model.filterOption == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => model.setFilterOption(label),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected ? [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              )
            ] : [],
          ),
          child: Text(
            localization.getString(label),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? const Color(0xFF064DC3) : Colors.grey[600],
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

}

class _FlyerStories extends StatelessWidget {
  final SchedulesViewModel model;
  const _FlyerStories({required this.model});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        children: [
          if (model.bulletins.isNotEmpty)
            _StoryCircle(
              title: context.read<LanguageService>().getString('announcements'),
              color: Colors.blue,
              icon: Icons.notifications_active_rounded,
              flyers: model.bulletins,
            ),
          if (model.regulations.isNotEmpty)
            _StoryCircle(
              title: context.read<LanguageService>().getString('regulations'),
              color: Colors.purple,
              icon: Icons.gavel_rounded,
              flyers: model.regulations,
            ),
          if (model.manuals.isNotEmpty)
            _StoryCircle(
              title: context.read<LanguageService>().getString('manual'),
              color: Colors.teal,
              icon: Icons.menu_book_rounded,
              flyers: model.manuals,
            ),
        ],
      ),
    );
  }
}

class _StoryCircle extends StatelessWidget {
  final String title;
  final Color color;
  final IconData icon;
  final List<FlyerData> flyers;

  const _StoryCircle({
    required this.title,
    required this.color,
    required this.icon,
    required this.flyers,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 20),
      child: GestureDetector(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => _FlyerStoryViewer(flyers: flyers, title: title),
            ),
          );
        },
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [color.withOpacity(0.8), color],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: CircleAvatar(
                  radius: 30,
                  backgroundColor: color.withOpacity(0.1),
                  child: Icon(icon, color: color, size: 28),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
            ),
          ],
        ),
      ),
    );
  }
}

class _FlyerStoryViewer extends StatefulWidget {
  final List<FlyerData> flyers;
  final String title;

  const _FlyerStoryViewer({required this.flyers, required this.title});

  @override
  State<_FlyerStoryViewer> createState() => _FlyerStoryViewerState();
}

class _FlyerStoryViewerState extends State<_FlyerStoryViewer> {
  late PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.flyers.length == 0 ? 1 : widget.flyers.length,
            onPageChanged: (index) {
              setState(() => _currentIndex = index);
            },
            itemBuilder: (context, index) {
              if (widget.flyers.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.info_outline_rounded, color: Colors.white.withOpacity(0.5), size: 60),
                      const SizedBox(height: 20),
                      Text(
                        context.read<LanguageService>().getString('no_flyers_to_show').replaceFirst('{title}', widget.title.toLowerCase()),
                        style: const TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                    ],
                  ),
                );
              }

              final flyer = widget.flyers[index];
              return Container(
// ...
                width: double.infinity,
                height: double.infinity,
                alignment: Alignment.center,
                child: Image.network(
                  flyer.url,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(child: CircularProgressIndicator(color: Colors.white));
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Text("Error al cargar imagen", style: TextStyle(color: Colors.white)),
                    );
                  },
                ),
              );
            },
          ),

          // Tap areas for navigation (Moved below header so header remains clickable)
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    if (_currentIndex > 0) {
                      _pageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                  child: Container(color: Colors.transparent),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    if (_currentIndex < widget.flyers.length - 1) {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                  child: Container(color: Colors.transparent),
                ),
              ),
            ],
          ),

          // Header with Progress Bars
          Positioned(
            top: 60,
            left: 10,
            right: 10,
            child: Column(
              children: [
                if (widget.flyers.isNotEmpty)
                  Row(
                    children: List.generate(
                      widget.flyers.length,
                      (index) => Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: LinearProgressIndicator(
                            value: index < _currentIndex ? 1.0 : (index == _currentIndex ? 0.0 : 0.0), // Simplified
                            backgroundColor: Colors.white24,
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                            minHeight: 2,
                          ),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title.toUpperCase(),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          if (widget.flyers.isNotEmpty) ...[
                            Text(
                              widget.flyers[_currentIndex].nombre,
                              style: const TextStyle(color: Colors.white, fontSize: 11),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              "${context.read<LanguageService>().getString('published_at')} ${widget.flyers[_currentIndex].fecha_alta}",
                              style: const TextStyle(color: Colors.white60, fontSize: 9),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


class _RouteGroupItem extends StatefulWidget {
  final String groupName;
  final List<RouteData> routes;
  final SchedulesViewModel model;

  const _RouteGroupItem({required this.groupName, required this.routes, required this.model});

  @override
  State<_RouteGroupItem> createState() => _RouteGroupItemState();
}

class _RouteGroupItemState extends State<_RouteGroupItem> {
  String? _selectedTramo; // 'ENTRADA' or 'SALIDA'

  @override
  Widget build(BuildContext context) {
    List<RouteData> displayedRoutes = [];
    if (_selectedTramo != null) {
      displayedRoutes = widget.routes.where((r) {
        final t = r.tramo.toUpperCase();
        if (_selectedTramo == 'entry') return t.contains('ENTRADA');
        if (_selectedTramo == 'exit') return t.contains('SALIDA');
        return false;
      }).toList();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: [
          // Header of the Route Group
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF064DC3).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.hub_rounded, color: Color(0xFF064DC3), size: 22),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.groupName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        "${widget.routes.length} ${context.read<LanguageService>().getString('available_schedules')}",
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Tramo Selection Path
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                _buildModernTramoChip('entry', context.read<LanguageService>().getString('entry'), Icons.login_rounded),
                const SizedBox(width: 10),
                _buildModernTramoChip('exit', context.read<LanguageService>().getString('exit'), Icons.logout_rounded),
              ],
            ),
          ),

          if (_selectedTramo != null)
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  if (displayedRoutes.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Text("No routes available"), // Fallback if tramo filtering results in empty, but tramo names ENTRADA/SALIDA are usually fixed.
                    )
                  else
                    ...displayedRoutes.map((route) {
                      final isSelected = widget.model.selectedRoute?.claveruta == route.claveruta;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF064DC3).withOpacity(0.05) : Colors.grey[50],
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: isSelected ? const Color(0xFF064DC3) : Colors.transparent,
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          leading: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.circle, size: 8, color: Color(0xFF064DC3)),
                              Container(width: 2, height: 15, color: Colors.grey[300]),
                              const Icon(Icons.circle, size: 8, color: Colors.grey),
                            ],
                          ),
                          title: Text(
                            "${context.read<LanguageService>().getString('shift_label')}: ${context.read<LanguageService>().getString(route.tipo_ruta.toLowerCase())}",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: isSelected ? const Color(0xFF064DC3) : Colors.black87,
                            ),
                          ),
                          subtitle: Text(
                            context.read<LanguageService>().getString('view_details'), 
                            style: TextStyle(fontSize: 11, color: Colors.grey[500])
                          ),
                          trailing: const Icon(Icons.info_outline_rounded, size: 20, color: Colors.grey),
                          onTap: () {
                             // We don't have access to _showRouteDetailsModal directly here since it's in HomeViewState
                             // but we can pass it via callback or use context to find it if it was a separate widget logic.
                             // For now, I'll just trigger the selection directly or show details if possible.
                             // Actually, _showRouteDetailsModal is inside HomeViewState. 
                             // I'll make selective use of the model.
                             widget.model.selectRoute(route);
                             Navigator.pop(context);
                          },
                        ),
                      );
                    }),
                  const SizedBox(height: 10),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildModernTramoChip(String key, String label, IconData icon) {
    final isSelected = _selectedTramo == key;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTramo = isSelected ? null : key),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF064DC3) : Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: isSelected ? Colors.white : Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[600],
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTramoChip(String tramo) {
    final isSelected = _selectedTramo == tramo;
    return ChoiceChip(
      label: Text(tramo),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedTramo = selected ? tramo : null;
        });
      },
      selectedColor: const Color(0xFF064DC3),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: isSelected ? const Color(0xFF064DC3) : Colors.grey[300]!),
      ),
      showCheckmark: false,
    );
  }
}
class _BlinkingDot extends StatefulWidget {
  const _BlinkingDot();

  @override
  State<_BlinkingDot> createState() => _BlinkingDotState();
}

class _BlinkingDotState extends State<_BlinkingDot> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this, duration: const Duration(seconds: 1));
    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animationController,
      child: Container(
        margin: const EdgeInsets.only(right: 5),
        width: 6,
        height: 6,
        decoration: const BoxDecoration(
          color: Colors.green,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class FadeInUp extends StatefulWidget {
  final Widget child;
  final Duration duration;

  const FadeInUp({required this.child, required this.duration});

  @override
  State<FadeInUp> createState() => _FadeInUpState();
}

class _FadeInUpState extends State<FadeInUp> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _offsetAnimation = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutQuad));
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacityAnimation,
      child: SlideTransition(
        position: _offsetAnimation,
        child: widget.child,
      ),
    );
  }
}
