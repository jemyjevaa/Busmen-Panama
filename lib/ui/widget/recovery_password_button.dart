import 'package:busmen_panama/ui/widget/text_field.dart';
import 'package:flutter/material.dart';

import '../../core/services/language_service.dart';
import '../../core/viewmodels/login_viewmodel.dart';

class RecoveryButton extends StatefulWidget {
  final LoginViewModel viewModel;
  final LanguageService localization;

  const RecoveryButton({
    super.key,
    required this.viewModel,
    required this.localization,
  });

  @override
  State<RecoveryButton> createState() => _RecoveryButtonState();
}

class _RecoveryButtonState extends State<RecoveryButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
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
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => _showRecoverySheet(
            context,
            widget.viewModel,
            widget.localization,
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.grey[700],
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
              side: BorderSide(color: Colors.grey[300]!),
            ),
          ),
          child: Text(
            widget.localization.getString('forgot_password'),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
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
                      buildTextField(
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
                      buildTextField(
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
