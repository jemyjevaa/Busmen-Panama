import 'package:busmen_panama/core/services/cache_user_session.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:busmen_panama/core/viewmodels/profile_viewmodel.dart';
import 'package:busmen_panama/core/services/language_service.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ProfileViewModel>();
    final localization = context.watch<LanguageService>();

    return Scaffold(
      backgroundColor: Colors.grey[100], // Cleaner background
      body: Stack(
        children: [
          // Gradient Header with Curve
          Container(
            height: 250,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF064DC3), Color(0xFF0C13A2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
          ),
          
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  // Custom AppBar
                  Row(
                    children: [
                      const BackButton(color: Colors.white),
                      Text(
                        localization.getString('profile').toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Profile Card
                  Stack(
                    alignment: Alignment.topCenter,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 60), // Medium space for medium logo
                        padding: const EdgeInsets.fromLTRB(20, 70, 20, 20), // Adjusted padding
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Text(
                              viewModel.userName,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF333333),
                              ),
                            ),
                             const SizedBox(height: 5),
                             Column(
                               children: viewModel.userEmails.map((email) => Text(
                                 email,
                                 style: TextStyle(
                                   fontSize: 14,
                                   color: Colors.grey[600],
                                 ),
                                 textAlign: TextAlign.center,
                               )).toList(),
                             ),
                            const SizedBox(height: 20),
                            const Divider(),
                            const SizedBox(height: 20),
                            
                            // QR Section in a subtle box
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(color: Colors.grey[200]!),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    localization.getString('user_code').toUpperCase(),
                                    style: const TextStyle(
                                      color: Color(0xFF064DC3),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                  const SizedBox(height: 15),
                                  QrImageView(
                                    data: viewModel.userId,
                                    version: QrVersions.auto,
                                    size: 180.0,
                                    foregroundColor: const Color(0xFF333333),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    viewModel.userId,
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 12,
                                      letterSpacing: 2.0,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Floating Avatar (Logo)
                      Container(
                        width: 200, // Medium width
                        height: 100, // Medium height
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.2), // Reverted dark background
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: viewModel.userImage != null && viewModel.userImage!.isNotEmpty
                              ? Image.network(
                                  viewModel.userImage!,
                                  fit: BoxFit.contain, // Contain to avoid cropping logo
                                  errorBuilder: (context, error, stackTrace) => const Icon(
                                    Icons.person,
                                    size: 40,
                                    color: Colors.white70,
                                  ),
                                )
                              : const Icon(
                                  Icons.person,
                                  size: 40,
                                  color: Colors.white70,
                                ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Delete Button - Less intrusive
                  CacheUserSession().isCopaair?
                  TextButton.icon(
                    onPressed: () => viewModel.deleteUser(context),
                    icon: viewModel.isDeleting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red),
                          )
                        : const Icon(Icons.delete_outline, color: Colors.red),
                    label: Text(
                      localization.getString('delete_user'),
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      backgroundColor: Colors.red.withOpacity(0.05),
                    ),
                  )
                  :const SizedBox(),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
