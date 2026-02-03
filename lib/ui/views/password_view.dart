import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:busmen_panama/core/viewmodels/password_viewmodel.dart';

class PasswordView extends StatelessWidget {
  const PasswordView({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<PasswordViewModel>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('CONTRASEÑA', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF064DC3).withOpacity(0.05),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lock_reset, size: 40, color: Color(0xFF064DC3)),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Cambiar Contraseña',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF064DC3)),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'Asegúrese de usar una contraseña segura que recuerde.',
                          style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 40),

            _buildLabel('Nueva Contraseña'),
            TextField(
              controller: viewModel.newPasswordController,
              obscureText: viewModel.obscureText,
              decoration: InputDecoration(
                hintText: 'Ingrese su nueva contraseña',
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
                suffixIcon: IconButton(
                  icon: Icon(
                    viewModel.obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    color: Colors.grey,
                  ),
                  onPressed: viewModel.toggleVisibility,
                ),
              ),
            ),

            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: viewModel.isSubmitting ? null : () => viewModel.changePassword(context),
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
                      'CAMBIAR CONTRASEÑA',
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
}
