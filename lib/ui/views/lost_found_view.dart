import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:busmen_panama/core/viewmodels/lost_found_viewmodel.dart';
import 'package:intl/intl.dart';

class LostFoundView extends StatelessWidget {
  const LostFoundView({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<LostFoundViewModel>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('OBJETOS PERDIDOS', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Reportar Objeto Perdido',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
            ),
            const SizedBox(height: 5),
            const Text(
              'Complete el formulario con los detalles del objeto.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 30),

            _buildLabel('Nombre de Usuario'),
            _buildTextField(viewModel.nameController, 'Ingrese su nombre'),
            
            const SizedBox(height: 20),
            _buildLabel('Teléfono de Contacto'),
            _buildTextField(viewModel.phoneController, 'Ingrese su teléfono', keyboardType: TextInputType.phone),

            const SizedBox(height: 20),
            _buildLabel('Ruta'),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: viewModel.selectedRoute,
                  hint: const Text('Seleccione la ruta'),
                  isExpanded: true,
                  items: viewModel.availableRoutes.map((String route) {
                    return DropdownMenuItem<String>(
                      value: route,
                      child: Text(route),
                    );
                  }).toList(),
                  onChanged: (newValue) => viewModel.setSelectedRoute(newValue),
                ),
              ),
            ),

            const SizedBox(height: 20),
            _buildLabel('Fecha del Incidente'),
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
                  }
                );
                if (date != null) {
                  viewModel.setSelectedDate(date);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, size: 20, color: Colors.grey[600]),
                    const SizedBox(width: 10),
                    Text(
                      viewModel.selectedDate == null 
                          ? 'Seleccione la fecha' 
                          : DateFormat('dd/MM/yyyy').format(viewModel.selectedDate!),
                      style: TextStyle(
                        color: viewModel.selectedDate == null ? Colors.grey[600] : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),
            _buildLabel('Descripción del Objeto'),
            _buildTextField(viewModel.descriptionController, 'Describa el objeto detalladamente', maxLines: 4),

            const SizedBox(height: 40),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: viewModel.isSubmitting ? null : () => viewModel.submitReport(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF064DC3),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 5,
                ),
                child: viewModel.isSubmitting 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text(
                      'ENVIAR REPORTE',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.0),
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 5),
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF333333)),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, {int maxLines = 1, TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400]),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
          borderSide: BorderSide(color: Color(0xFF064DC3), width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
      ),
    );
  }
}
