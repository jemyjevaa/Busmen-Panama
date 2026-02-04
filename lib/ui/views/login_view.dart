import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:busmen_panama/core/viewmodels/login_viewmodel.dart';
import 'package:busmen_panama/core/viewmodels/home_viewmodel.dart';
import 'package:busmen_panama/core/services/localization_service.dart';
import 'package:busmen_panama/ui/views/home_view.dart';

class LoginView extends StatelessWidget {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final viewModel = context.watch<LoginViewModel>();
    final localization = context.watch<LocalizationService>();
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false, 
      body: Stack(
        children: [
         
          Positioned.fill(
            child: Image.asset(
              'assets/images/backgrounds/BusmenPanama17.png',
              fit: BoxFit.cover,
              alignment: Alignment.bottomCenter, 
            ),
          ),

         
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.only(bottom: bottomInset > 0 ? bottomInset + 20 : 20),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: size.height - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 35),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, // Align to left
                    children: [
                      SizedBox(height: size.height * 0.12), // Fixed top margin
                      
                      // Logo aligned left
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Image.asset(
                          'assets/images/logos/LogoBusmen.png',
                          height: 69,
                          fit: BoxFit.contain,
                        ),
                      ),
                      
                      const SizedBox(height: 15), 
                      
                      // Form Card WITHOUT background
                      Container(
                        constraints: const BoxConstraints(maxWidth: 450), 
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // User Label
                            Text(
                              localization.getString('user_label'),
                              style: const TextStyle(
                                color: Color(0xFF064DC3),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.0,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildTextField(
                              controller: viewModel.userController,
                              hint: localization.getString('user_label'),
                              icon: Icons.person_outline,
                              isSuccess: viewModel.identifiedCompany != 0,
                              onChanged: viewModel.identifyCompany, // Reliability fix
                            ),
                            const SizedBox(height: 10),

                            if (viewModel.identifiedCompany != 0) ...[
                              // Password Section (Visible only if company identified)
                              Text(
                                localization.getString('pass_label'),
                                style: const TextStyle(
                                  color: Color(0xFF064DC3),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _buildTextField(
                                controller: viewModel.passwordController,
                                hint: localization.getString('pass_label'),
                                icon: Icons.lock_outline,
                                isPassword: true,
                              ),
                              const SizedBox(height: 30),
                            ],

                              // Remember Me & Language (Always visible)
                              Row(
                                children: [
                                  Expanded(
                                    child: Theme(
                                      data: Theme.of(context).copyWith(
                                        unselectedWidgetColor: Colors.grey[400],
                                      ),
                                      child: CheckboxListTile(
                                        value: viewModel.rememberMe,
                                        onChanged: viewModel.toggleRememberMe,
                                        title: Text(
                                          localization.getString('remember_me'),
                                          style: const TextStyle(
                                            color: Color(0xFF555555),
                                            fontSize: 14,
                                          ),
                                        ),
                                        controlAffinity: ListTileControlAffinity.leading,
                                        contentPadding: EdgeInsets.zero,
                                        activeColor: const Color(0xFF064DC3),
                                        dense: true,
                                      ),
                                    ),
                                  ),
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
                                          localization.currentLanguage == 'ES',
                                          () => localization.setLanguage('ES'),
                                        ),
                                        _buildLanguageOption(
                                          context,
                                          'EN',
                                          localization.currentLanguage == 'EN',
                                          () => localization.setLanguage('EN'),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              
                              if (viewModel.identifiedCompany != 0) ...[
                                const SizedBox(height: 30),
                                // Login Button (Shared)
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      viewModel.login((side) {
                                        context.read<HomeViewModel>().setSide(side);
                                        Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(builder: (context) => const HomeView()),
                                        );
                                      }, context);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF064DC3),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                      elevation: 2,
                                    ),
                                    child: Text(
                                      localization.getString('login_btn'),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                  ),
                                ),
                                
                                // Company-specific Actions
                                if (viewModel.identifiedCompany == 1) ...[
                                  const SizedBox(height: 15),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        // QR logic placeholder
                                      },
                                      icon: const Icon(Icons.qr_code_scanner),
                                      label: const Text(
                                        "ESCANEAR CÓDIGO QR",
                                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        foregroundColor: const Color(0xFF064DC3),
                                        side: const BorderSide(color: Color(0xFF064DC3), width: 1.5),
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                        elevation: 0,
                                      ),
                                    ),
                                  ),
                                ] else if (viewModel.identifiedCompany == 2) ...[
                                  const SizedBox(height: 15),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: () => _showRegisterSheet(context, viewModel, localization),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        foregroundColor: const Color(0xFF064DC3),
                                        side: const BorderSide(color: Color(0xFF064DC3), width: 1.5),
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                        elevation: 0,
                                      ),
                                      child: Text(
                                        localization.getString('register'),
                                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 15),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: () => _showRecoverySheet(context, viewModel, localization),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        foregroundColor: Colors.grey[700],
                                        elevation: 0,
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(15), 
                                          side: BorderSide(color: Colors.grey[300]!)
                                        ),
                                      ),
                                      child: Text(
                                        localization.getString('forgot_password'),
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ],
                          ),
                        ),
                        
                      const SizedBox(height: 40), // Safe bottom margin
                    ],
                  ),
                ),
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
    bool isSuccess = false,
    Function(String)? onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSuccess ? Colors.green : Colors.grey[200]!, 
          width: 1.5
        ),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        onChanged: onChanged,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: Colors.grey[400],
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: Icon(icon, color: const Color(0xFF064DC3), size: 20),
          suffixIcon: isSuccess ? const Icon(Icons.check_circle, color: Colors.green, size: 20) : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  void _showRegisterSheet(BuildContext context, LoginViewModel viewModel, LocalizationService localization) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          ),
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                localization.getString('create_account'),
                style: const TextStyle(
                  fontSize: 20, 
                  fontWeight: FontWeight.bold, 
                  color: Color(0xFF064DC3),
                ),
              ),
              const SizedBox(height: 20),
              _buildTextField(
                controller: viewModel.registerNameController, 
                hint: localization.getString('name_label'), 
                icon: Icons.person_outline
              ),
              const SizedBox(height: 15),
              _buildTextField(
                controller: viewModel.registerEmailController, 
                hint: localization.getString('email_label'), 
                icon: Icons.email_outlined
              ),
              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => viewModel.registerUser(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF064DC3),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: viewModel.isProcessing 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(localization.getString('register_btn'), style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(localization.getString('back_btn'), style: TextStyle(color: Colors.grey[600])),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRecoverySheet(BuildContext context, LoginViewModel viewModel, LocalizationService localization) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          ),
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                localization.getString('recover_access'),
                style: const TextStyle(
                  fontSize: 20, 
                  fontWeight: FontWeight.bold, 
                  color: Color(0xFF064DC3),
                ),
              ),
              const SizedBox(height: 20),
              _buildTextField(
                controller: viewModel.recoveryUserController, 
                hint: localization.getString('user_n_label'), 
                icon: Icons.person_outline
              ),
              const SizedBox(height: 15),
              _buildTextField(
                controller: viewModel.recoveryEmailController, 
                hint: localization.getString('email_label'), 
                icon: Icons.email_outlined
              ),
              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => viewModel.recoverPassword(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF064DC3),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: viewModel.isProcessing 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(localization.getString('send_btn'), style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(localization.getString('cancel_btn'), style: TextStyle(color: Colors.grey[600])),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
