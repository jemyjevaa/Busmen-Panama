import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:busmen_panama/core/viewmodels/profile_viewmodel.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ProfileViewModel>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('PERFIL', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              // Dummy Logo
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: const Color(0xFF064DC3).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.business, size: 50, color: Color(0xFF064DC3)),
              ),
              const SizedBox(height: 30),
              
              Text(
                viewModel.userName,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
              ),
              Text(
                viewModel.userEmail,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              
              const SizedBox(height: 40),
              
              // QR Code
              Container(
                padding: const EdgeInsets.all(20),
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
                    QrImageView(
                      data: viewModel.userId,
                      version: QrVersions.auto,
                      size: 200.0,
                    ),
                    const SizedBox(height: 10),
                    const Text('Código de Usuario', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
              
              const SizedBox(height: 50),
              
              // Delete User Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: viewModel.isDeleting ? null : () => viewModel.deleteUser(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[50],
                    foregroundColor: Colors.red,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(color: Colors.red.withOpacity(0.2)),
                    ),
                  ),
                  child: viewModel.isDeleting 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red))
                    : const Text(
                        'ELIMINAR USUARIO',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
