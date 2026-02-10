import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:busmen_panama/core/viewmodels/lost_found_viewmodel.dart';
import 'package:busmen_panama/core/viewmodels/schedules_viewmodel.dart';
import 'package:busmen_panama/core/services/language_service.dart';
import 'package:intl/intl.dart';

class LostFoundView extends StatelessWidget {
  const LostFoundView({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<LostFoundViewModel>();
    final schedulesViewModel = context.watch<SchedulesViewModel>();
    final localization = context.watch<LanguageService>();

    // Sync routes from SchedulesViewModel if available
    if (viewModel.availableRoutesModel.isEmpty && schedulesViewModel.routes.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        viewModel.setAvailableRoutes(schedulesViewModel.routes);
      });
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          localization.getString('lost_found').toUpperCase(),
          style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 16, letterSpacing: 1.5),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF064DC3), Color(0xFF053E9E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
        child: Column(
          children: [
            // Intro Card (Modernized)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF064DC3).withOpacity(0.06),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: const Color(0xFF064DC3).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(Icons.search_rounded, color: Color(0xFF064DC3), size: 28),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          localization.getString('report_lost_object'),
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          localization.getString('report_msg'),
                          style: TextStyle(fontSize: 13, color: Colors.blueGrey[400], height: 1.3),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),

            // Form Section: User Info
            _buildSectionTitle('Información de Contacto', Icons.person_rounded),
            const SizedBox(height: 16),
            _buildFormCard([
              _buildModernTextField(
                viewModel.nameController, 
                localization.getString('user_name_hint'), 
                Icons.person_pin_rounded
              ),
              const SizedBox(height: 16),
              _buildModernTextField(
                viewModel.phoneController, 
                localization.getString('phone_hint'), 
                Icons.phone_iphone_rounded,
                isPhone: true
              ),
            ]),

            const SizedBox(height: 32),

            // Form Section: Incident Details
            _buildSectionTitle('Detalles del Incidente', Icons.bus_alert_rounded),
            const SizedBox(height: 16),
            _buildFormCard([
              // Modern Searchable Picker
              InkWell(
                onTap: () => _showRoutePicker(context, viewModel, localization),
                child: Container(
                  height: 58,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.directions_bus_filled_rounded, color: Colors.blueGrey[300], size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          viewModel.selectedRouteModel == null 
                              ? localization.getString('route_hint')
                              : "${viewModel.selectedRouteModel!.nombre}${viewModel.selectedRouteModel!.hora_inicio != null ? ' (${viewModel.selectedRouteModel!.hora_inicio} - ${viewModel.selectedRouteModel!.hora_fin})' : ''}",
                          style: TextStyle(
                            color: viewModel.selectedRouteModel == null ? Colors.blueGrey[400] : const Color(0xFF334155),
                            fontSize: 14,
                            fontWeight: viewModel.selectedRouteModel == null ? FontWeight.normal : FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(Icons.search_rounded, color: Color(0xFF064DC3), size: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Modern Date Picker
              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: const ColorScheme.light(
                            primary: Color(0xFF064DC3),
                            onPrimary: Colors.white,
                            onSurface: Color(0xFF1E293B),
                          ),
                          dialogBackgroundColor: Colors.white,
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (date != null) viewModel.setDate(date);
                },
                child: Container(
                  height: 58,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today_rounded, color: Colors.blueGrey[300], size: 20),
                      const SizedBox(width: 12),
                      Text(
                        viewModel.selectedDate == null 
                            ? localization.getString('date_hint')
                            : DateFormat('dd/MM/yyyy').format(viewModel.selectedDate!),
                        style: TextStyle(
                          color: viewModel.selectedDate == null ? Colors.blueGrey[400] : const Color(0xFF334155),
                          fontWeight: viewModel.selectedDate == null ? FontWeight.normal : FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.touch_app_rounded, color: Color(0xFF064DC3), size: 18),
                    ],
                  ),
                ),
              ),
            ]),

            const SizedBox(height: 32),
            
            // Description
            _buildSectionTitle('Descripción del Objeto', Icons.description_rounded),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF064DC3).withOpacity(0.04),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: TextField(
                controller: viewModel.descriptionController,
                maxLines: 4,
                style: const TextStyle(fontSize: 14, color: Color(0xFF334155)),
                decoration: InputDecoration(
                  hintText: localization.getString('description_hint'),
                  hintStyle: TextStyle(color: Colors.blueGrey[200]),
                  border: InputBorder.none,
                ),
              ),
            ),

            const SizedBox(height: 48),

            // Submit Button (Upgraded)
            SizedBox(
              width: double.infinity,
              height: 60,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF064DC3).withOpacity(0.25),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () => viewModel.submitReport(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF064DC3),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    padding: EdgeInsets.zero,
                  ),
                  child: Ink(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF064DC3), Color(0xFF053E9E)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Container(
                      alignment: Alignment.center,
                      child: viewModel.isSubmitting 
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(
                            localization.getString('send_report').toUpperCase(),
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Colors.white, letterSpacing: 1.2),
                          ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF475569)),
          const SizedBox(width: 10),
          Text(
            title.toUpperCase(),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF475569), letterSpacing: 1.2),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF064DC3).withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildModernTextField(TextEditingController controller, String hint, IconData icon, {bool isPhone = false}) {
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextField(
        controller: controller,
        keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
        style: const TextStyle(fontSize: 14, color: Color(0xFF334155)),
        decoration: InputDecoration(
          icon: Icon(icon, color: Colors.blueGrey[300], size: 20),
          hintText: hint,
          hintStyle: TextStyle(color: Colors.blueGrey[400], fontSize: 14),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 18),
        ),
      ),
    );
  }

  void _showRoutePicker(BuildContext context, LostFoundViewModel viewModel, LanguageService localization) {
    viewModel.setSearchQuery(''); // Reset search on open
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final groupedRoutes = viewModel.groupedFilteredRoutes;
            
            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Column(
                children: [
                  // Handle
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Header & Search
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          localization.getString('route_hint').toUpperCase(),
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1E293B), letterSpacing: 0.5),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
                            ],
                          ),
                          child: TextField(
                            onChanged: (value) {
                              viewModel.setSearchQuery(value);
                              setModalState(() {});
                            },
                            decoration: InputDecoration(
                              icon: const Icon(Icons.search_rounded, color: Color(0xFF064DC3), size: 22),
                              hintText: 'Buscar ruta...',
                              hintStyle: TextStyle(color: Colors.blueGrey[200], fontSize: 14),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // List
                  Expanded(
                    child: groupedRoutes.isEmpty 
                    ? Center(child: Text("No se encontraron rutas", style: TextStyle(color: Colors.grey[400])))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                        itemCount: groupedRoutes.keys.length,
                        itemBuilder: (context, index) {
                          final groupName = groupedRoutes.keys.elementAt(index);
                          final routesInGroup = groupedRoutes[groupName]!;
                          
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Group Header
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                                child: Text(
                                  groupName,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF064DC3), letterSpacing: 1),
                                ),
                              ),
                              // Routes in group
                              ...routesInGroup.map((route) {
                                final isSelected = viewModel.selectedRouteModel?.claveruta == route.claveruta;
                                final schedule = (route.hora_inicio != null) 
                                    ? "${route.hora_inicio} - ${route.hora_fin}"
                                    : "Horario no definido";
                                
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: InkWell(
                                    onTap: () {
                                      viewModel.setRouteModel(route);
                                      Navigator.pop(context);
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: isSelected ? const Color(0xFF064DC3).withOpacity(0.05) : Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: isSelected ? const Color(0xFF064DC3) : Colors.transparent,
                                          width: 1.5,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: (isSelected ? const Color(0xFF064DC3) : Colors.blueGrey[500])!.withOpacity(0.1),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              Icons.access_time_filled_rounded, 
                                              size: 18, 
                                              color: isSelected ? const Color(0xFF064DC3) : Colors.blueGrey[300]
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  route.tramo,
                                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B)),
                                                ),
                                                Text(
                                                  schedule,
                                                  style: TextStyle(fontSize: 12, color: Colors.blueGrey[300]),
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (isSelected) 
                                            const Icon(Icons.check_circle_rounded, color: Color(0xFF064DC3), size: 22),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }),
                              const SizedBox(height: 10),
                            ],
                          );
                        },
                      ),
                  ),
                ],
              ),
            );
          },
        );
      }
    );
  }
}
