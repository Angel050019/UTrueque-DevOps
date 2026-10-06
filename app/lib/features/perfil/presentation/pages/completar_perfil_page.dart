import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_ui.dart';
import '../cubit/perfil_cubit.dart';
import '../cubit/perfil_state.dart';
import '../widgets/estado_carga_perfil.dart';
import '../widgets/formulario_perfil.dart';

/// Pantalla 5 - Completar perfil (HU-02, Escenario 1).
/// Aparece después del login cuando `perfil_completo` es falso.
/// Al guardar con éxito lleva al Feed. No tiene botón "atrás".
class CompletarPerfilPage extends StatefulWidget {
  const CompletarPerfilPage({super.key});

  @override
  State<CompletarPerfilPage> createState() => _CompletarPerfilPageState();
}

class _CompletarPerfilPageState extends State<CompletarPerfilPage> {
  final TextEditingController _nombreController = TextEditingController();
  bool _nombreInicializado = false;

  @override
  void dispose() {
    _nombreController.dispose();
    super.dispose();
  }

  void _escuchar(BuildContext context, PerfilState state) {
    if (state is PerfilCargado && !_nombreInicializado) {
      _nombreInicializado = true;
      _nombreController.text = state.datos.perfil.nombreMostrar ?? '';
    }
    if (state is PerfilGuardado) {
      Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.feedPrincipal, (route) => false);
    }
    if (state is PerfilError && state.datos != null) {
      mostrarMensaje(context, state.mensaje, esError: true);
    }
  }

  Widget _construir(BuildContext context, PerfilState state) {
    final PerfilDatos? datos = state.datos;
    if (datos == null) {
      if (state is PerfilError) {
        return ErrorCargaPerfil(
          mensaje: state.mensaje,
          onReintentar: context.read<PerfilCubit>().cargarMiPerfil,
        );
      }
      return const CargandoPerfil();
    }
    return FormularioPerfil(
      estado: state,
      datos: datos,
      nombreController: _nombreController,
      textoBoton: 'Guardar y continuar',
      encabezado: const _EncabezadoCompletar(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocConsumer<PerfilCubit, PerfilState>(
          listener: _escuchar,
          builder: _construir,
        ),
      ),
    );
  }
}

class _EncabezadoCompletar extends StatelessWidget {
  const _EncabezadoCompletar();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          'PASO 2 DE 2',
          style: AppTexto.etiqueta(color: AppColores.primario).copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _barra()),
            const SizedBox(width: 6),
            Expanded(child: _barra()),
          ],
        ),
        const SizedBox(height: 20),
        Text('¡Ya casi!', style: AppTexto.titulo()),
        const SizedBox(height: 6),
        Text(
          'Completa tu perfil para que otros estudiantes sepan quién eres.',
          style: AppTexto.cuerpo(),
        ),
      ],
    );
  }

  Widget _barra() => Container(
        height: 6,
        decoration: BoxDecoration(
          color: AppColores.acento,
          borderRadius: BorderRadius.circular(3),
        ),
      );
}
