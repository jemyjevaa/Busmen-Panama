import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:busmen_panama/core/viewmodels/lost_found_viewmodel.dart';
import 'package:busmen_panama/core/services/localization_service.dart';
import 'package:intl/intl.dart';

class LostFoundView extends StatelessWidget {
  const LostFoundView({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<LostFoundViewModel>();
    final localization = context.watch<LocalizationService>();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(localization.getString('lost_found').toUpperCase(), 
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18)),
        backgroundColor: const Color(0xFF064DC3),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Intro Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF064DC3).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.search_rounded, color: Color(0xFF064DC3), size: 30),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          localization.getString('report_lost_object'),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
                        ),
                        Text(
                          localization.getString('report_msg'),
                          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),

            // Form Section: User Info
            _buildSectionTitle('Información de Contacto', Icons.person_outline),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Column(
                children: [
                  _buildModernTextField(
                    viewModel.nameController, 
                    localization.getString('user_name_hint'), 
                    Icons.account_circle_outlined
                  ),
                  const SizedBox(height: 15),
                  _buildModernTextField(
                    viewModel.phoneController, 
                    localization.getString('phone_hint'), 
                    Icons.phone_outlined,
                    isPhone: true
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Form Section: Incident Details
            _buildSectionTitle('Detalles del Incidente', Icons.bus_alert_outlined),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Column(
                children: [
                  // Custom Dropdown
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: viewModel.selectedRoute,
                        hint: Row(children: [
                          Icon(Icons.directions_bus_outlined, color: Colors.grey[400], size: 20),
                          const SizedBox(width: 10),
                          Text(localization.getString('route_hint'), style: TextStyle(color: Colors.grey[500])),
                        ]),
                        isExpanded: true,
                        icon: const Icon(Icons.arrow_drop_down_circle, color: Color(0xFF064DC3)),
                        items: viewModel.availableRoutes.map((String route) {
                          return DropdownMenuItem<String>(value: route, child: Text(route));
                        }).toList(),
                        onChanged: (String? newValue) => viewModel.setRoute(newValue),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  // Date Picker
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
                              colorScheme: const ColorScheme.light(primary: Color(0xFF064DC3)),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (date != null) viewModel.setDate(date);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today_outlined, color: Colors.grey[400], size: 20),
                          const SizedBox(width: 10),
                          Text(
                            viewModel.selectedDate == null 
                                ? localization.getString('date_hint')
                                : DateFormat('dd/MM/yyyy').format(viewModel.selectedDate!),
                            style: TextStyle(
                              color: viewModel.selectedDate == null ? Colors.grey[500] : Colors.black87,
                              fontWeight: viewModel.selectedDate == null ? FontWeight.normal : FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          const Icon(Icons.touch_app_outlined, color: Color(0xFF064DC3), size: 18),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            
            // Description
            _buildSectionTitle('Descripción', Icons.description_outlined),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: TextField(
                controller: viewModel.descriptionController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: localization.getString('description_hint'),
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  border: InputBorder.none,
                ),
              ),
            ),

            const SizedBox(height: 40),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () => viewModel.submitReport(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF064DC3),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 5,
                  shadowColor: const Color(0xFF064DC3).withOpacity(0.4),
                ),
                child: viewModel.isSubmitting 
                  ? const SizedBox(width: 25, height: 25, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(
                      localization.getString('send_report'),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white, letterSpacing: 1.0),
                    ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          title.toUpperCase(),
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[600], letterSpacing: 1.0),
        ),
      ],
    );
  }

  Widget _buildModernTextField(TextEditingController controller, String hint, IconData icon, {bool isPhone = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: TextField(
        controller: controller,
        keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
        decoration: InputDecoration(
          icon: Icon(icon, color: Colors.grey[400], size: 20),
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[500]),
          border: InputBorder.none,
        ),
      ),
    );
  }
}
