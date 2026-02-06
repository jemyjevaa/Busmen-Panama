import 'package:busmen_panama/core/services/cache_user_session.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:busmen_panama/core/viewmodels/password_viewmodel.dart';
import 'package:busmen_panama/core/services/language_service.dart';

class PasswordView extends StatelessWidget {
  const PasswordView({super.key});

  @override
  Widget build(BuildContext context) {

    final viewModel = context.watch<PasswordViewModel>();
    final localization = context.watch<LanguageService>();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(localization.getString('password').toUpperCase(), 
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18)),
        backgroundColor: const Color(0xFF064DC3),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Security Icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: const Color(0xFF064DC3).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.shield_outlined, size: 50, color: Color(0xFF064DC3)),
              ),
              const SizedBox(height: 30),

              // Form Card
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5)),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      localization.getString('change_password'),
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      localization.getString('password_msg'),
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 40),

                    // Password Input
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: TextField(
                        controller: viewModel.newPasswordController,
                        obscureText: viewModel.obscureText,
                        decoration: InputDecoration(
                          hintText: localization.getString('new_password_hint'),
                          hintStyle: TextStyle(color: Colors.grey[500]),
                          border: InputBorder.none,
                          prefixIcon: Icon(Icons.lock_outline, color: Colors.grey[400]),
                          suffixIcon: IconButton(
                            icon: Icon(
                              viewModel.obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                              color: Colors.grey[500],
                            ),
                            onPressed: viewModel.toggleVisibility,
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 40),

                    // Action Button
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: () => viewModel.changePassword(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF064DC3),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          elevation: 5,
                          shadowColor: const Color(0xFF064DC3).withOpacity(0.4),
                        ),
                        child: viewModel.isSubmitting 
                          ? const SizedBox(width: 25, height: 25, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Text(
                              localization.getString('change_password_btn'),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white, letterSpacing: 1.0),
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
