import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:busmen_panama/core/viewmodels/login_viewmodel.dart';
import 'package:busmen_panama/core/viewmodels/home_viewmodel.dart';
import 'package:busmen_panama/core/services/language_service.dart';
import 'package:busmen_panama/ui/views/home_view.dart';

import '../../core/services/cache_user_session.dart';

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
                                  _buildTextField(
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
                                  _buildTextField(
                                    controller: viewModel.passwordController,
                                    hint: localization.getString('pass_label'),
                                    icon: Icons.lock_outline,
                                    isPassword: true,
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
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: () {
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
                                    ] else if (CacheUserSession().isCopaair) ...[
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
                            )
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
    String? Function(String?)? validator,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 5),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword,
        onChanged: onChanged,
        validator: validator,
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
          filled: true,
          fillColor: Colors.grey[50],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: isSuccess ? Colors.green : Colors.grey[200]!, 
              width: 1.5
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: isSuccess ? Colors.green : Colors.grey[200]!, 
              width: 1.5
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: Color(0xFF064DC3), 
              width: 1.5
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: Colors.red, 
              width: 1.5
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  void _showRegisterSheet(BuildContext context, LoginViewModel viewModel, LanguageService localization) {
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
              Form(
                key: viewModel.formKeyNewUser,
                child: Column(
                  children: [
                    _buildTextField(
                        controller: viewModel.registerNewCompanyController,
                        hint: localization.getString('new_user_company'),
                        icon: Icons.domain,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return localization.getString('fill_all_fields');
                          }
                          return null;
                        },
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                        controller: viewModel.registerNewUserNameController,
                        hint: localization.getString('user_name_label'),
                        icon: Icons.person_outline,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return localization.getString('fill_all_fields');
                          }
                          return null;
                        },
                    ),
                    const SizedBox(height: 15),
                    _buildTextField(
                        controller: viewModel.registerNewEmailController,
                        hint: localization.getString('email_label'),
                        icon: Icons.email_outlined,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return localization.getString('fill_all_fields');
                          }
                          return null;
                        },
                    ),
                    const SizedBox(height: 25),
                    _buildTextField(
                        controller: viewModel.registerNewUserController,
                        hint: localization.getString('user_n_label'),
                        icon: Icons.person_outline,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return localization.getString('fill_all_fields');
                          }
                          return null;
                        },
                    ),
                  ]
                )
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

  void _showRecoverySheet(BuildContext context, LoginViewModel viewModel, LanguageService localization) {
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
              Form(
                key: viewModel.formKeyRecoveryPwd,
                child: Column(
                  children: [
                    _buildTextField(
                      controller: viewModel.recoveryUserController,
                      hint: localization.getString('user_n_label'),
                      icon: Icons.person_outline,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return localization.getString('fill_all_fields');
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 15),
                    _buildTextField(
                      controller: viewModel.recoveryEmailController,
                      hint: localization.getString('email_label'),
                      icon: Icons.email_outlined,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return localization.getString('fill_all_fields');
                        }
                        return null;
                      },
                    ),
                  ],
                )
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
