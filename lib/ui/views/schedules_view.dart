import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:busmen_panama/core/viewmodels/schedules_viewmodel.dart';
import 'package:busmen_panama/core/services/language_service.dart';

class SchedulesView extends StatelessWidget {
  const SchedulesView({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<SchedulesViewModel>();
    final localization = context.watch<LanguageService>();
    final schedules = viewModel.schedules;

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
      ),
      body: Column(
        children: [
          // Route Selector Header
          Container(
            padding: const EdgeInsets.all(20),
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
                Text(
                  localization.getString('select_route'),
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: viewModel.selectedRoute,
                      hint: const Text(
                        'Seleccione...',
                        style: TextStyle(color: Colors.white),
                      ),
                      isExpanded: true,
                      dropdownColor: const Color(0xFF0C13A2),
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
                      items: viewModel.routes.map((String route) {
                        return DropdownMenuItem<String>(
                          value: route,
                          child: Text(route),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          viewModel.selectRoute(newValue);
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Schedules List or Empty State
          Expanded(
            child: viewModel.selectedRoute == null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.directions_bus_outlined, size: 80, color: Colors.grey[300]),
                        const SizedBox(height: 20),
                        Text(
                          'Seleccione una ruta para ver los horarios',
                          style: TextStyle(color: Colors.grey[500], fontSize: 16),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: schedules.length,
                    itemBuilder: (context, index) {
                      final schedule = schedules[index];
                      final isDelayed = schedule['status'] == 'Retrasado';
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 15),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
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
                                // Left Status Bar
                                Container(
                                  width: 6,
                                  color: isDelayed ? Colors.red : Colors.green,
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      children: [
                                        // Times
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            _buildTimeRow(Icons.departure_board, schedule['departure'] ?? schedule['dep'] ?? '--:--', 'Salida'),
                                            const SizedBox(height: 12),
                                            _buildTimeRow(Icons.arrow_circle_down, schedule['arrival'] ?? schedule['arr'] ?? '--:--', 'Llegada'),
                                          ],
                                        ),
                                        const Spacer(),
                                        // Status Pill
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: isDelayed ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                isDelayed ? Icons.warning_amber_rounded : Icons.check_circle_outline,
                                                size: 16,
                                                color: isDelayed ? Colors.red : Colors.green,
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                isDelayed ? localization.getString('delayed') : localization.getString('on_time'),
                                                style: TextStyle(
                                                  color: isDelayed ? Colors.red : Colors.green,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
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
}
