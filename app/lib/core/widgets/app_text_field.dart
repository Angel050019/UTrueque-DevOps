import 'package:flutter/material.dart';

/// Campo de texto estándar de UTrueque, reutilizado en registro y login.
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
    this.esContrasena = false,
    this.tipoTeclado,
    this.textoError,
  });

  final TextEditingController controller;
  final String label;
  final bool esContrasena;
  final TextInputType? tipoTeclado;
  final String? textoError;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: esContrasena,
      keyboardType: tipoTeclado,
      decoration: InputDecoration(
        labelText: label,
        errorText: textoError,
        border: const OutlineInputBorder(),
      ),
    );
  }
}
