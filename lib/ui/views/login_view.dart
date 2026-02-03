import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:busmen_panama/core/viewmodels/login_viewmodel.dart';
import 'package:busmen_panama/ui/views/home_view.dart';

class LoginView extends StatelessWidget {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final viewModel = context.watch<LoginViewModel>();

    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/images/backgrounds/BusmenPanama13.png',
              fit: BoxFit.cover,
            ),
          ),

          // Logo Placement
          Positioned(
            left: 0,
            right: 0,
            bottom: size.height * 0.70, // Raised further from 0.55
            child: Center(
              child: Image.asset(
                'assets/images/logos/LogoBusmen.png',
                height: 80,
                fit: BoxFit.contain,
              ),
            ),
          ),

          // Form Card Container
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.all(30),
              margin: const EdgeInsets.symmetric(horizontal: 35).copyWith(bottom: 180),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.92),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start, // Align labels to the left
                children: [
                  // User Label
                  Text(
                    viewModel.getString('user_label').toUpperCase(),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // User Field
                  _buildTextField(
                    controller: viewModel.userController,
                    hint: viewModel.getString('user_label'),
                    icon: Icons.person_outline,
                  ),
                  const SizedBox(height: 25), // Increased spacing

                  // Password Label
                  Text(
                    viewModel.getString('pass_label').toUpperCase(),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Password Field
                  _buildTextField(
                    controller: viewModel.passwordController,
                    hint: viewModel.getString('pass_label'),
                    icon: Icons.lock_outline,
                    isPassword: true,
                  ),
                  const SizedBox(height: 10),

                  // Remember Me Checkbox & Language Switcher
                  Row(
                    children: [
                      // Remember Me
                      Expanded(
                        child: Theme(
                          data: Theme.of(context).copyWith(
                            unselectedWidgetColor: Colors.grey[400],
                          ),
                          child: CheckboxListTile(
                            value: viewModel.rememberMe,
                            onChanged: viewModel.toggleRememberMe,
                            title: Text(
                              viewModel.getString('remember_me'),
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 11,
                              ),
                            ),
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: EdgeInsets.zero,
                            activeColor: const Color(0xFF064DC3),
                            dense: true,
                          ),
                        ),
                      ),

                      // Language Switcher - Visual Toggle
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Row(
                          children: [
                            _buildLanguageOption(
                              context,
                              'ES',
                              viewModel.currentLanguage == 'ES',
                              () => viewModel.setLanguage('ES'),
                            ),
                            _buildLanguageOption(
                              context,
                              'EN',
                              viewModel.currentLanguage == 'EN',
                              () => viewModel.setLanguage('EN'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30), // Increased spacing

                  // Login Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        viewModel.login(() {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => const HomeView()),
                          );
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF064DC3),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16), // Taller button
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 2,
                      ),
                      child: Text(
                        viewModel.getString('login_btn'),
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
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageOption(
    BuildContext context,
    String label,
    bool isActive,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF064DC3) : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: isActive ? Colors.white : Colors.grey[600],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50], // Very light background
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!, width: 1.5),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: Colors.grey[400],
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: Icon(icon, color: const Color(0xFF064DC3), size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}
