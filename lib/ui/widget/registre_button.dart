import 'package:busmen_panama/ui/widget/text_field.dart';
import 'package:flutter/material.dart';

import '../../core/services/cache_user_session.dart';
import '../../core/services/language_service.dart';
import '../../core/viewmodels/login_viewmodel.dart';

class RegisterButton extends StatefulWidget {
  final LoginViewModel viewModel;
  final LanguageService localization;

  const RegisterButton({
    super.key,
    required this.viewModel,
    required this.localization,
  });

  @override
  State<RegisterButton> createState() => _RegisterButtonState();
}

class _RegisterButtonState extends State<RegisterButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CacheUserSession().isCopaair? FadeTransition(
      opacity: _fadeAnimation,
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () =>
              _showRegisterSheet(context, widget.viewModel, widget.localization),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF064DC3),
            side: const BorderSide(
              color: Color(0xFF064DC3),
              width: 1.5,
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            elevation: 0,
          ),
          child: Text(
            widget.localization.getString('register'),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
        ),
      ),
    )
        : const SizedBox();
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
                        buildTextField(
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
                        buildTextField(
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
                        buildTextField(
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
                        buildTextField(
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


}
