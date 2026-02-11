import 'package:busmen_panama/core/services/models/info_schedules_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:busmen_panama/core/viewmodels/schedules_viewmodel.dart';
import 'package:busmen_panama/core/viewmodels/home_viewmodel.dart';
import 'package:busmen_panama/core/services/language_service.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class SchedulesView extends StatelessWidget {
  const SchedulesView({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<SchedulesViewModel>();
    final localization = context.watch<LanguageService>();
    final stops = viewModel.stops;

    void _showRoutePicker() {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => _SimpleRoutePicker(viewModel: viewModel, localization: localization),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          localization.getString('schedules').toUpperCase(),
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18),
        ),
        backgroundColor: const Color(0xFF064DC3),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_calls_rounded),
            onPressed: _showRoutePicker,
            tooltip: localization.getString('change_route'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Selected Route Info Header
          if (viewModel.selectedRoute != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Color(0xFF064DC3),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        localization.getString('route_label').toUpperCase(),
                        style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: viewModel.isRouteActiveNow(viewModel.selectedRoute!) 
                            ? Colors.green.withOpacity(0.2) 
                            : Colors.orange.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: viewModel.isRouteActiveNow(viewModel.selectedRoute!) 
                              ? Colors.green 
                              : Colors.orange,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          viewModel.isRouteActiveNow(viewModel.selectedRoute!) 
                            ? localization.getString('active') 
                            : localization.getString('out_of_schedule'),
                          style: TextStyle(
                            color: viewModel.isRouteActiveNow(viewModel.selectedRoute!) ? Colors.green : Colors.orange,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    viewModel.selectedRoute!.nombre,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 15,
                    runSpacing: 8,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.access_time_rounded, color: Colors.white70, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            "${localization.getString('shift_label')}: ${localization.getString(viewModel.selectedRoute!.tipo_ruta.toLowerCase())}",
                            style: const TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.calendar_today_rounded, color: Colors.white70, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            "${localization.getString('days_label')}: ${localization.getString(viewModel.getActiveDays(viewModel.selectedRoute!.dia_ruta ?? viewModel.selectedRoute!.tipo_ruta))}",
                            style: const TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (viewModel.unit != null) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
                            child: const Icon(Icons.directions_bus, color: Colors.white, size: 18),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(localization.getString('assigned_unit'), style: const TextStyle(color: Colors.white60, fontSize: 10, fontWeight: FontWeight.bold)),
                                Text(
                                  viewModel.unit!.economico,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

          // Stops List or Empty State
          Expanded(
            child: viewModel.isLoadingStops
                ? const Center(child: CircularProgressIndicator())
                : viewModel.selectedRoute == null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.directions_bus_outlined, size: 80, color: Colors.grey[300]),
                            const SizedBox(height: 20),
                            Text(
                              localization.getString('select_route_msg'),
                              style: TextStyle(color: Colors.grey[500], fontSize: 16),
                            ),
                          ],
                        ),
                      )
                    : stops.isEmpty
                        ? Center(
                        child: Text(
                          localization.getString('no_stops_found'),
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(20),
                            itemCount: stops.length,
                            itemBuilder: (context, index) {
                              final stop = stops[index];
                              final isDelayed = stop.estatus == 'Retrasado';

                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Transit Path Visual
                                  Column(
                                    children: [
                                      Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: isDelayed ? Colors.red : Colors.green,
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.white, width: 2),
                                          boxShadow: [
                                            BoxShadow(
                                              color: (isDelayed ? Colors.red : Colors.green).withOpacity(0.3),
                                              blurRadius: 4,
                                              spreadRadius: 1,
                                            )
                                          ],
                                        ),
                                      ),
                                      if (index < stops.length - 1)
                                        Container(
                                          width: 2,
                                          height: 80, // Approximate height of the card
                                          color: Colors.grey[300],
                                        ),
                                    ],
                                  ),
                                  const SizedBox(width: 15),
                                  Expanded(
                                    child: Container(
                                      margin: const EdgeInsets.only(bottom: 20),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(15),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.04),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(15),
                                        child: IntrinsicHeight(
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 4,
                                                color: isDelayed ? Colors.red : Colors.green,
                                              ),
                                              Expanded(
                                                child: Padding(
                                                  padding: const EdgeInsets.all(16),
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Row(
                                                        children: [
                                                          Expanded(
                                                            child: Text(
                                                              stop.nombre_parada,
                                                              style: const TextStyle(
                                                                fontWeight: FontWeight.bold,
                                                                fontSize: 15,
                                                                color: Color(0xFF064DC3),
                                                              ),
                                                            ),
                                                          ),
                                                          if (stop.url_imagen != null && stop.url_imagen!.isNotEmpty)
                                                            IconButton(
                                                              onPressed: () => _showStopImage(context, stop.nombre_parada, stop.url_imagen!),
                                                              icon: const Icon(Icons.image_rounded, color: Color(0xFF064DC3), size: 18),
                                                              padding: EdgeInsets.zero,
                                                              constraints: const BoxConstraints(),
                                                              tooltip: "Ver foto de la parada",
                                                            ),
                                                        ],
                                                      ),
                                                      const SizedBox(height: 10),
                                                      Row(
                                                        children: [
                                                          _buildTimeRow(Icons.access_time_rounded, stop.horario, localization.getString('stops_label')),
                                                          const Spacer(),
                                                          Container(
                                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                            decoration: BoxDecoration(
                                                              color: viewModel.isRouteActiveNow(viewModel.selectedRoute!)
                                                                  ? (isDelayed ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1))
                                                                  : Colors.grey.withOpacity(0.1),
                                                              borderRadius: BorderRadius.circular(10),
                                                            ),
                                                            child: Text(
                                                              viewModel.isRouteActiveNow(viewModel.selectedRoute!)
                                                                  ? (isDelayed ? localization.getString('delayed') : localization.getString('on_time'))
                                                                  : stop.hora_parada, // Using exact parada time when inactive
                                                              style: TextStyle(
                                                                color: viewModel.isRouteActiveNow(viewModel.selectedRoute!)
                                                                    ? (isDelayed ? Colors.red : Colors.green)
                                                                    : Colors.grey[700],
                                                                fontWeight: FontWeight.bold,
                                                                fontSize: 10,
                                                              ),
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
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeRow(IconData icon, String time, String label) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[400]),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              time,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF333333)),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 10, color: Colors.grey[500]),
            ),
          ],
        ),
      ],
    );
  }

  void _showStopImage(BuildContext context, String stopName, String url) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.9),
      builder: (context) => Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(stopName, style: const TextStyle(color: Colors.white, fontSize: 16)),
        ),
        body: Center(
          child: InteractiveViewer(
            minScale: 1.0,
            maxScale: 4.0,
            child: Image.network(
              url,
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
          ),
        ),
      ),
    );
  }
}

class _SimpleRoutePicker extends StatelessWidget {
  final SchedulesViewModel viewModel;
  final LanguageService localization;
  const _SimpleRoutePicker({required this.viewModel, required this.localization});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFF),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 45, height: 5,
            decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
          ),
          const SizedBox(height: 20),
          Text(localization.getString('select_a_route').toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF064DC3))),
          const SizedBox(height: 15),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              itemCount: viewModel.groupedRoutes.length,
              itemBuilder: (context, index) {
                final groupName = viewModel.groupedRoutes.keys.elementAt(index);
                final routes = viewModel.groupedRoutes[groupName]!;
                return _SimpleRouteGroup(groupName: groupName, routes: routes, model: viewModel, localization: localization);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SimpleRouteGroup extends StatefulWidget {
  final String groupName;
  final List<RouteData> routes;
  final SchedulesViewModel model;
  final LanguageService localization;
  const _SimpleRouteGroup({required this.groupName, required this.routes, required this.model, required this.localization});

  @override
  State<_SimpleRouteGroup> createState() => _SimpleRouteGroupState();
}

class _SimpleRouteGroupState extends State<_SimpleRouteGroup> {
  String? _selectedTramo;

  @override
  Widget build(BuildContext context) {
    List<RouteData> displayed = _selectedTramo == null ? [] : widget.routes.where((r) {
      final t = r.tramo.toUpperCase();
      if (_selectedTramo == 'entry') return t.contains('ENTRADA');
      if (_selectedTramo == 'exit') return t.contains('SALIDA');
      return false;
    }).toList();
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      color: Colors.white,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        leading: const Icon(Icons.alt_route_rounded, color: Color(0xFF064DC3)),
        title: Text(widget.groupName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        children: [
           Padding(
             padding: const EdgeInsets.all(16),
             child: Column(
               children: [
                 Row(
                   children: [
                     _buildChip('entry', widget.localization.getString('entry')),
                     const SizedBox(width: 8),
                     _buildChip('exit', widget.localization.getString('exit')),
                   ],
                 ),
                 if (_selectedTramo != null) ...[
                   const SizedBox(height: 10),
                   ...displayed.map((r) => ListTile(
                       title: Text("${widget.localization.getString('shift_label')}: ${widget.localization.getString(r.tipo_ruta.toLowerCase())}", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                       subtitle: Text(
                         "${widget.localization.getString('days_label')}: ${widget.localization.getString(widget.model.getActiveDays(r.dia_ruta ?? r.tipo_ruta))}", 
                         style: const TextStyle(fontSize: 11)
                       ),
                       dense: true,
                      onTap: () {
                        widget.model.selectRoute(r, onRouteLoaded: () {
                          final homeViewModel = context.read<HomeViewModel>();
                          if (widget.model.stops.isNotEmpty) {
                            final points = widget.model.stops.map((s) => LatLng(s.latitud, s.longitud)).toList();
                            homeViewModel.moveCameraToRoute(points);
                          }
                        });
                        Navigator.pop(context);
                      },
                   )),
                 ]
               ],
             ),
           )
        ],
      ),
    );
  }

  Widget _buildChip(String key, String label) {
    final isS = _selectedTramo == key;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 11, color: isS ? Colors.white : Colors.black87)),
      selected: isS,
      onSelected: (s) => setState(() => _selectedTramo = s ? key : null),
      selectedColor: const Color(0xFF064DC3),
      backgroundColor: Colors.grey[100],
      showCheckmark: false,
    );
  }
}
