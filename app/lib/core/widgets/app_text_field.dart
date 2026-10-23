import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Campo de texto estándar de UTrueque: etiqueta arriba y caja redondeada.
/// Si [esContrasena] es true, incluye el botón para mostrar u ocultar.
/// Con [lineas] mayor a 1 sirve para textos largos (descripción) y con
/// [prefijo] muestra un texto fijo antes del valor (por ejemplo `$`).
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
    this.esContrasena = false,
    this.tipoTeclado,
    this.textoError,
    this.hint,
    this.habilitado = true,
    this.lineas = 1,
    this.prefijo,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final bool esContrasena;
  final TextInputType? tipoTeclado;
  final String? textoError;
  final String? hint;
  final bool habilitado;
  final int lineas;
  final String? prefijo;
  final ValueChanged<String>? onChanged;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  bool _oculto = true;

  OutlineInputBorder _borde(Color color, {double ancho = 1.5}) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppMedidas.radioCampo),
        borderSide: BorderSide(color: color, width: ancho),
      );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(widget.label, style: AppTexto.etiqueta()),
        const SizedBox(height: 8),
        TextField(
          controller: widget.controller,
          enabled: widget.habilitado,
          obscureText: widget.esContrasena && _oculto,
          keyboardType: widget.tipoTeclado,
          minLines: widget.esContrasena ? 1 : widget.lineas,
          maxLines: widget.esContrasena ? 1 : widget.lineas,
          onChanged: widget.onChanged,
          style: AppTexto.cuerpo(color: AppColores.texto),
          decoration: InputDecoration(
            hintText: widget.hint,
            prefixText: widget.prefijo,
            prefixStyle: AppTexto.cuerpo(color: AppColores.texto, peso: FontWeight.w600),
            hintStyle: AppTexto.cuerpo(),
            errorText: widget.textoError,
            errorMaxLines: 2,
            filled: true,
            fillColor: AppColores.superficie,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            border: _borde(AppColores.borde),
            enabledBorder: _borde(AppColores.borde),
            disabledBorder: _borde(AppColores.borde.withValues(alpha: 0.6)),
            focusedBorder: _borde(AppColores.primario, ancho: 2),
            errorBorder: _borde(AppColores.error),
            focusedErrorBorder: _borde(AppColores.error, ancho: 2),
            suffixIcon: widget.esContrasena
                ? IconButton(
                    tooltip: _oculto ? 'Mostrar contraseña' : 'Ocultar contraseña',
                    icon: Icon(
                      _oculto ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                      color: AppColores.textoSecundario,
                    ),
                    onPressed: () => setState(() => _oculto = !_oculto),
                  )
                : null,
          ),
        ),
      ],
    );
  }
}
