import 'package:flutter/material.dart';

Widget buildTextField({
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