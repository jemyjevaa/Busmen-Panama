import 'package:busmen_panama/ui/widget/recovery_password_button.dart';
import 'package:busmen_panama/ui/widget/registre_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:busmen_panama/core/viewmodels/login_viewmodel.dart';
import 'package:busmen_panama/core/services/language_service.dart';

import '../../app_globals.dart';
import '../../core/services/cache_user_session.dart';
import '../widget/text_field.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {


  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = context.read<LoginViewModel>();

      if (CacheUserSession().isPerduration) {
        viewModel.userController.text = CacheUserSession().perdureEmail;
        viewModel.passwordController.text = CacheUserSession().perdurePass;
      }
    });
  }


  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final viewModel = context.watch<LoginViewModel>();
    final localization = context.watch<LanguageService>();
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
                            Form(
                              key: viewModel.formKeyLogin,
                              autovalidateMode: AutovalidateMode.onUserInteraction,
                              child: Column(
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
                                  buildTextField(
                                    controller: viewModel.userController,
                                    hint: localization.getString('user_label'),
                                    icon: Icons.person_outline,
                                    isSuccess: viewModel.identifiedCompany != 0,
                                    onChanged: viewModel.identifyCompany, // Reliability fix
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return localization.getString('fill_all_fields');
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 10),

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
                                  buildTextField(
                                    controller: viewModel.passwordController,
                                    hint: localization.getString('pass_label'),
                                    icon: Icons.lock_outline,
                                    isPassword: true,
                                    obscureText: viewModel.obscurePassword,
                                    onToggleVisibility: viewModel.togglePasswordVisibility,
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        viewModel.isPasswordObscured
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                        color: const Color(0xFF064DC3),
                                        size: 20,
                                      ),
                                      onPressed: viewModel.togglePasswordVisibility,
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return localization.getString('fill_all_fields');
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 30),

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
                                                  () {
                                                        localization.setLanguage('ES');
                                                        viewModel.language.setLanguage('ES');
                                                  },
                                            ),
                                            _buildLanguageOption(
                                              context,
                                              'EN',
                                              localization.currentLanguage == 'EN',
                                                  () {
                                                localization.setLanguage('EN');
                                                viewModel.language.setLanguage('EN');
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 30),
                                  // Login Button (Shared)
                                  viewModel.loadingLogIn?
                                      const Center(
                                      child: CircularProgressIndicator(),
                                      )
                                      :SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        hideKeyboard(context);
                                        viewModel.login(context);
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
                                  if ( CacheUserSession().isCopaair ) ...[
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
                                          label: Text(
                                            localization.getString('scan_qr'),
                                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.0),
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
                                    ],
                                  ],
                                  const SizedBox(height: 20),
                                  RecoveryButton(
                                    viewModel: viewModel,
                                    localization: localization,
                                  ),
                                  const SizedBox(height: 10),
                                  RegisterButton(
                                    viewModel: viewModel,
                                    localization: localization,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
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

  Widget _buildLanguageOption(BuildContext context, String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF064DC3) : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[600],
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}