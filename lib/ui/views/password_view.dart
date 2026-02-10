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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          localization.getString('password').toUpperCase(),
          style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 16, letterSpacing: 1.5),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF064DC3), Color(0xFF053E9E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Security Icon (Enhanced)
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: const Color(0xFF064DC3).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(40),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(Icons.shield_rounded, size: 70, color: const Color(0xFF064DC3).withOpacity(0.2)),
                    const Icon(Icons.lock_person_rounded, size: 40, color: Color(0xFF064DC3)),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // Form Card (Modernized)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 48),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF064DC3).withOpacity(0.08),
                      blurRadius: 30,
                      offset: const Offset(0, 15),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      localization.getString('change_password'),
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1E293B)),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      localization.getString('password_msg'),
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Colors.blueGrey[400], height: 1.5),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF064DC3).withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF064DC3).withOpacity(0.1)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.alternate_email_rounded, size: 14, color: const Color(0xFF1E293B).withOpacity(0.5)),
                          const SizedBox(width: 8),
                          Text(
                            viewModel.currentUser,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1E293B).withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 48),

                    // Password Input (Pill Design)
                    Container(
                      height: 60,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: TextField(
                        controller: viewModel.newPasswordController,
                        obscureText: viewModel.obscureText,
                        style: const TextStyle(fontSize: 16, color: Color(0xFF334155), fontWeight: FontWeight.w600),
                        decoration: InputDecoration(
                          hintText: localization.getString('new_password_hint'),
                          hintStyle: TextStyle(color: Colors.blueGrey[300], fontSize: 14),
                          border: InputBorder.none,
                          prefixIcon: Icon(Icons.password_rounded, color: Colors.blueGrey[300]),
                          suffixIcon: IconButton(
                            icon: Icon(
                              viewModel.obscureText ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                              color: const Color(0xFF064DC3).withOpacity(0.6),
                            ),
                            onPressed: viewModel.toggleVisibility,
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 20),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 48),

                    // Action Button (Upgraded)
                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF064DC3).withOpacity(0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: () => viewModel.changePassword(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF064DC3),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                            padding: EdgeInsets.zero,
                          ),
                          child: Ink(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF064DC3), Color(0xFF053E9E)],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Container(
                              alignment: Alignment.center,
                              child: viewModel.isSubmitting 
                                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : Text(
                                    localization.getString('change_password_btn').toUpperCase(),
                                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Colors.white, letterSpacing: 1.2),
                                  ),
                            ),
                          ),
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
