import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../domain/entities/foto_perfil.dart';
import '../cubit/perfil_cubit.dart';
import '../cubit/perfil_state.dart';
import '../perfil_keys.dart';
import 'avatar_perfil.dart';
import 'elegir_foto.dart';
import 'selector_academico.dart';

/// Formulario compartido por "Completar perfil" y "Editar perfil".
/// Solo lee [estado] y llama métodos de [PerfilCubit]. El botón queda fijo
/// abajo y el resto se desplaza.
class FormularioPerfil extends StatelessWidget {
  const FormularioPerfil({
    super.key,
    required this.estado,
    required this.datos,
    required this.nombreController,
    required this.textoBoton,
    this.encabezado,
  });

  /// Largo máximo del nombre (la validación real la hace el Cubit).
  static const int maxNombre = 50;

  final PerfilState estado;
  final PerfilDatos datos;
  final TextEditingController nombreController;
  final String textoBoton;

  /// Contenido opcional arriba del formulario (título, pasos, etc.).
  final Widget? encabezado;

  Future<void> _elegirFoto(PerfilCubit cubit) async {
    final FotoPerfil? foto = await elegirFotoDeGaleria();
    if (foto != null) cubit.seleccionarFoto(foto);
  }

  @override
  Widget build(BuildContext context) {
    final PerfilCubit cubit = context.read<PerfilCubit>();
    final bool guardando = estado is PerfilGuardando;
    final bool tieneFoto = datos.fotoNueva != null || datos.perfil.tieneFoto;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppMedidas.margen,
              8,
              AppMedidas.margen,
              AppMedidas.margen,
            ),
            children: [
              if (encabezado != null) ...[encabezado!, const SizedBox(height: 20)],
              Center(
                child: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: nombreController,
                  builder: (context, valor, _) => AvatarPerfil(
                    fotoUrl: datos.perfil.fotoUrl,
                    fotoNueva: datos.fotoNueva,
                    nombre: valor.text,
                    mostrarInsignia: true,
                    onTap: guardando ? null : () => _elegirFoto(cubit),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  EnlaceTexto(
                    key: PerfilKeys.elegirFotoBoton,
                    texto: tieneFoto ? 'Cambiar foto' : 'Agregar foto (opcional)',
                    onPressed: guardando ? null : () => _elegirFoto(cubit),
                  ),
                  if (datos.fotoNueva != null)
                    EnlaceTexto(
                      key: PerfilKeys.quitarFotoBoton,
                      texto: 'Quitar',
                      color: AppColores.error,
                      onPressed: guardando ? null : cubit.quitarFotoNueva,
                    ),
                ],
              ),
              Text(
                'JPG o PNG · máx. 5 MB',
                textAlign: TextAlign.center,
                style: AppTexto.cuerpo(size: 12),
              ),
              const SizedBox(height: 20),
              AppTextField(
                key: PerfilKeys.nombreField,
                controller: nombreController,
                label: 'Nombre a mostrar',
                hint: 'Ej. Ana López',
                habilitado: !guardando,
              ),
              const SizedBox(height: 6),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: nombreController,
                builder: (context, valor, _) {
                  final int largo = valor.text.trim().length;
                  return Text(
                    '$largo/$maxNombre',
                    textAlign: TextAlign.right,
                    style: AppTexto.cuerpo(
                      size: 12,
                      color: largo > maxNombre ? AppColores.error : AppColores.textoSecundario,
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              SelectorAcademico(datos: datos, habilitado: !guardando),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(AppMedidas.margen, 8, AppMedidas.margen, 16),
            child: PrimaryButton(
              key: PerfilKeys.guardarBoton,
              texto: textoBoton,
              cargando: guardando,
              onPressed: () => cubit.guardar(nombre: nombreController.text),
            ),
          ),
        ),
      ],
    );
  }
}
