import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../domain/entities/foto_perfil.dart';
import '../cubit/perfil_cubit.dart';
import '../cubit/perfil_state.dart';
import '../perfil_keys.dart';
import 'avatar_perfil.dart';
import 'elegir_foto.dart';
import 'selector_academico.dart';

/// Formulario compartido por "Completar perfil" y "Editar perfil".
/// Solo lee [estado] y llama métodos de [PerfilCubit].
///
/// TODO(diseño): acomodo final del formulario (secciones, espaciados,
/// ayuda de "foto opcional", contador de caracteres del nombre, etc.).
class FormularioPerfil extends StatelessWidget {
  const FormularioPerfil({
    super.key,
    required this.estado,
    required this.datos,
    required this.nombreController,
    required this.textoBoton,
  });

  final PerfilState estado;
  final PerfilDatos datos;
  final TextEditingController nombreController;
  final String textoBoton;

  Future<void> _elegirFoto(PerfilCubit cubit) async {
    final FotoPerfil? foto = await elegirFotoDeGaleria();
    if (foto != null) cubit.seleccionarFoto(foto);
  }

  @override
  Widget build(BuildContext context) {
    final PerfilCubit cubit = context.read<PerfilCubit>();
    final bool guardando = estado is PerfilGuardando;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Center(
          child: AvatarPerfil(fotoUrl: datos.perfil.fotoUrl, fotoNueva: datos.fotoNueva),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              key: PerfilKeys.elegirFotoBoton,
              onPressed: guardando ? null : () => _elegirFoto(cubit),
              child: const Text('Elegir foto (opcional)'),
            ),
            if (datos.fotoNueva != null)
              TextButton(
                key: PerfilKeys.quitarFotoBoton,
                onPressed: guardando ? null : cubit.quitarFotoNueva,
                child: const Text('Quitar'),
              ),
          ],
        ),
        const SizedBox(height: 16),
        AppTextField(
          key: PerfilKeys.nombreField,
          controller: nombreController,
          label: 'Nombre a mostrar',
        ),
        const SizedBox(height: 16),
        SelectorAcademico(datos: datos, habilitado: !guardando),
        const SizedBox(height: 24),
        PrimaryButton(
          key: PerfilKeys.guardarBoton,
          texto: textoBoton,
          cargando: guardando,
          onPressed: () => cubit.guardar(nombre: nombreController.text),
        ),
      ],
    );
  }
}
