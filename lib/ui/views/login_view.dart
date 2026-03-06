import 'package:busmen_panama/ui/views/qr_scanner_view.dart';
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
  // Each LoginView instance owns its form key — never share from a singleton ViewModel
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final viewModel = context.read<LoginViewModel>();
      final session = CacheUserSession();

      if (session.isPerduration &&
          session.perdureEmail.isNotEmpty &&
          session.perdurePass.isNotEmpty) {
        // Auto-fill credentials
        viewModel.userController.text = session.perdureEmail;
        viewModel.passwordController.text = session.perdurePass;

        // Auto-login if not already in a login attempt
        if (!viewModel.loadingLogIn) {
          viewModel.login(context, _formKey);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<LoginViewModel>();
    final localization = context.watch<LanguageService>();

    return Theme(
      data: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0C13A2),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: Colors.white,
        useMaterial3: true,
      ),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: Stack(
          children: [
            // Full-screen background image
            Positioned.fill(
              child: Image.asset(
                'assets/images/backgrounds/FondoPanamaNN5.png',
                fit: BoxFit.cover,
                alignment: Alignment.center,
              ),
            ),

            // Gradient overlay
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.transparent,
                      Color(0x44000000),
                    ],
                    stops: [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),

            // White card pinned to bottom
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: double.infinity,
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.82,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 30,
                      offset: Offset(0, -8),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.only(
                    top: 30,
                    left: 28,
                    right: 28,
                    bottom: MediaQuery.of(context).padding.bottom + 20,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Handle bar
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 22),
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),

                      Form(
                        key: _formKey,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // User label
                            Text(
                              localization.getString('user_label'),
                              style: const TextStyle(
                                color: Color(0xFF064DC3),
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 8),
                            buildTextField(
                              controller: viewModel.userController,
                              hint: localization.getString('user_label'),
                              icon: Icons.person_outline,
                              isSuccess: viewModel.identifiedCompany != 0,
                              onChanged: viewModel.identifyCompany,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return localization.getString('fill_all_fields');
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Password label
                            Text(
                              localization.getString('pass_label'),
                              style: const TextStyle(
                                color: Color(0xFF064DC3),
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
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
                            const SizedBox(height: 16),

                            // Remember Me + Language switcher
                            Row(
                              children: [
                                Expanded(
                                  child: CheckboxListTile(
                                    value: viewModel.rememberMe,
                                    onChanged: viewModel.toggleRememberMe,
                                    title: Text(
                                      localization.getString('remember_me'),
                                      style: const TextStyle(
                                        color: Color(0xFF555555),
                                        fontSize: 13,
                                      ),
                                    ),
                                    controlAffinity: ListTileControlAffinity.leading,
                                    contentPadding: EdgeInsets.zero,
                                    activeColor: const Color(0xFF064DC3),
                                    dense: true,
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
                                        context, 'ES',
                                        localization.currentLanguage == 'ES',
                                        () {
                                          localization.setLanguage('ES');
                                          viewModel.language.setLanguage('ES');
                                        },
                                      ),
                                      _buildLanguageOption(
                                        context, 'EN',
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

                            const SizedBox(height: 24),

                            // Login Button
                            viewModel.loadingLogIn
                                ? const Center(child: CircularProgressIndicator())
                                : SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        hideKeyboard(context);
                                        viewModel.login(context, _formKey);
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF064DC3),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
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

                            const SizedBox(height: 12),

                            // QR Scan Button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => const QRScannerView()),
                                  );
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

                            const SizedBox(height: 16),
                            RecoveryButton(viewModel: viewModel, localization: localization),
                            const SizedBox(height: 8),
                            RegisterButton(viewModel: viewModel, localization: localization),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
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