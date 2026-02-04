import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:busmen_panama/core/viewmodels/home_viewmodel.dart';
import 'package:busmen_panama/core/services/localization_service.dart';
import 'package:busmen_panama/ui/views/profile_view.dart';
import 'package:busmen_panama/ui/views/schedules_view.dart';
import 'package:busmen_panama/ui/views/lost_found_view.dart';
import 'package:busmen_panama/ui/views/password_view.dart';

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
    // Access the viewmodel
    final viewModel = context.watch<HomeViewModel>();
    final localization = context.watch<LocalizationService>();

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
                      target: viewModel.currentPosition != null
                          ? LatLng(viewModel.currentPosition!.latitude,
                              viewModel.currentPosition!.longitude)
                          : LatLng(8.9824, -79.5199), 
                      zoom: 15,
                    ),
                    onMapCreated: viewModel.onMapCreated,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                    padding: const EdgeInsets.only(top: 100), 
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
                      child: _buildCircleButton(
                        icon: Icons.notifications_none,
                        onTap: () {
                          // TODO: Implement notifications
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
                    bottom: 40,
                    left: 20,
                    right: 20,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Banner & Circular Button Row
                        Row(
                          children: [
                            // "Ruta no seleccionada" Banner
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 19),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  localization.getString('route_not_selected'),
                                  style: const TextStyle(
                                    color: Color(0xFF333333),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Standalone Circular Button
                            Container(
                              width: 55,
                              height: 55,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8B600),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 6,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.add_location,
                                color: Colors.white, // Dark icon for contrast
                                size: 29,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        // "SELECCIONAR RUTA" Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              // TODO: Navigate to route selection
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF064DC3),
                              foregroundColor: Colors.white,
                              elevation: 4,
                              shadowColor: const Color(0xFF064DC3).withOpacity(0.4),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: Text(
                              localization.getString('select_route'),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildDrawer(BuildContext context, HomeViewModel viewModel, LocalizationService localization) {
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
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Image.asset(
                      'assets/images/logos/LogoBusmen.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                // User Info with Icon
                if (viewModel.userSide == 1) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.person, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      const Text(
                        'Juan Pérez',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'email@example.com',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    localization.getString('driver_role'),
                    style: const TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                ] else ...[
                  Text(
                    localization.getString('no_profile'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
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
                  onTap: () {},
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
                        onTap: () {},
                      ),
                      _buildSubMenuItem(
                        localization.getString('regulations'),
                        icon: Icons.gavel_outlined,
                        onTap: () {},
                      ),
                      _buildSubMenuItem(
                        localization.getString('manual'),
                        icon: Icons.menu_book_outlined,
                        onTap: () {},
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 25), // Spacing before logout

                // Logout Button - Part of the list flow
                _buildLogoutItem(context, localization),

                if (viewModel.userSide == 2) ...[
                  const SizedBox(height: 10),
                  _buildDrawerItem(
                    icon: Icons.delete_outline,
                    title: localization.getString('delete_user'),
                    onTap: () {
                      // Implementation for deleting user
                      debugPrint('Eliminando usuario...');
                    },
                    isDestructive: true,
                  ),
                ],
              ],
            ),
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

  Widget _buildLogoutItem(BuildContext context, LocalizationService localization) {
    return InkWell(
      onTap: () {
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
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

  Widget _buildCircleButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
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
}
