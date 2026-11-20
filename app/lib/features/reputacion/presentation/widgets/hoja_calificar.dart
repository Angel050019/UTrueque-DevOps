import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/network_info.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../../../core/widgets/filtros_texto.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../perfil/presentation/widgets/avatar_perfil.dart';
import '../../domain/entities/trato.dart';
import '../../domain/repositories/reputacion_repository.dart';
import '../../domain/usecases/casos_de_uso_reputacion.dart';
import '../../domain/validators/calificacion_validator.dart';
import '../cubit/calificar_cubit.dart';
import '../reputacion_keys.dart';
import 'estrellas.dart';

/// HU-09: hoja "Calificar" de un trato (Escenarios 3, 4, 9, 10, 12 a 14).
///
/// Devuelve `true` si el aviso "Califica tu trato" se debe quitar (se
/// calificó, o ese trato ya no se puede calificar).
class HojaCalificar extends StatefulWidget {
  const HojaCalificar({super.key});

  static Future<bool> abrir(BuildContext context, TratoPorCalificar trato) async {
    final ReputacionRepository repositorio = context.read<ReputacionRepository>();
    final NetworkInfo red = context.read<NetworkInfo>();
    final bool? quitar = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: AppColores.superficie,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppMedidas.radioTarjeta)),
      ),
      builder: (_) => BlocProvider(
        create: (_) => CalificarCubit(trato: trato, calificar: Calificar(repositorio, red)),
        child: const HojaCalificar(),
      ),
    );
    return quitar ?? false;
  }

  @override
  State<HojaCalificar> createState() => _HojaCalificarState();
}

class _HojaCalificarState extends State<HojaCalificar> {
  final TextEditingController _comentario = TextEditingController();

  @override
  void dispose() {
    _comentario.dispose();
    super.dispose();
  }

  void _escuchar(BuildContext context, CalificarState state) {
    if (state.enviada) {
      mostrarMensaje(context, CalificarCubit.mensajeGracias, icono: Icons.star_rounded);
      Navigator.of(context).pop(true);
    } else if (state.tratoCerrado) {
      mostrarMensaje(context, state.error ?? '', esError: true);
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CalificarCubit, CalificarState>(
      listenWhen: (antes, ahora) =>
          (ahora.enviada && !antes.enviada) || (ahora.tratoCerrado && !antes.tratoCerrado),
      listener: _escuchar,
      builder: (context, state) {
        final CalificarCubit cubit = context.read<CalificarCubit>();
        final TratoPorCalificar trato = cubit.trato;
        final String? error = state.error;
        return Padding(
          key: ReputacionKeys.hojaCalificar,
          padding: EdgeInsets.fromLTRB(
            AppMedidas.margen,
            0,
            AppMedidas.margen,
            AppMedidas.margen + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(child: AvatarPerfil(fotoUrl: trato.otroFotoUrl, nombre: trato.otroNombre, radio: 32)),
                const SizedBox(height: 10),
                Text(
                  'Califica a ${trato.otroNombre}',
                  textAlign: TextAlign.center,
                  style: AppTexto.titulo(size: 20),
                ),
                const SizedBox(height: 2),
                Text(
                  '${trato.soyVendedor ? 'Te compró' : 'Te vendió'} "${trato.publicacionTitulo}"',
                  textAlign: TextAlign.center,
                  style: AppTexto.cuerpo(size: 14),
                ),
                const SizedBox(height: 12),
                SelectorEstrellas(
                  elegidas: state.estrellas,
                  onElegir: state.enviando ? null : cubit.elegirEstrellas,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  key: ReputacionKeys.comentario,
                  controller: _comentario,
                  label: 'Comentario (opcional)',
                  hint: 'Por ejemplo: Muy puntual, el artículo estaba como en las fotos.',
                  lineas: 3,
                  habilitado: !state.enviando,
                  filtros: FiltrosTexto.descripcion,
                  textoError: state.errorComentario,
                  onChanged: cubit.cambiarComentario,
                ),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '${state.largoComentario}/${CalificacionValidator.longitudMaxima}',
                    key: ReputacionKeys.contador,
                    style: AppTexto.cuerpo(
                      size: 12,
                      color: state.largoComentario > CalificacionValidator.longitudMaxima
                          ? AppColores.error
                          : AppColores.textoSecundario,
                    ),
                  ),
                ),
                if (error != null && !state.tratoCerrado) ...[
                  const SizedBox(height: 8),
                  Container(
                    key: ReputacionKeys.mensajeError,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColores.errorSuave,
                      borderRadius: BorderRadius.circular(AppMedidas.radioCampo),
                    ),
                    child: Text(error, style: AppTexto.cuerpo(size: 13, color: AppColores.error)),
                  ),
                ],
                const SizedBox(height: 16),
                PrimaryButton(
                  key: ReputacionKeys.enviarCalificacion,
                  texto: 'Enviar calificación',
                  cargando: state.enviando,
                  onPressed: state.completa ? cubit.enviar : null,
                ),
                const SizedBox(height: 8),
                Text(
                  'Tu calificación no se puede cambiar después. El otro estudiante verá tus estrellas y tu comentario.',
                  textAlign: TextAlign.center,
                  style: AppTexto.cuerpo(size: 12),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Aviso "Califica tu trato con <nombre>" del chat y de Mi perfil
/// (Escenario 3).
// TODO(diseño): aviso según Figma.
class AvisoCalificarTrato extends StatelessWidget {
  const AvisoCalificarTrato({super.key, required this.trato, required this.onCalificar, this.ahora});

  final TratoPorCalificar trato;
  final VoidCallback onCalificar;

  /// Para las pruebas; por omisión, la hora del celular.
  final DateTime? ahora;

  @override
  Widget build(BuildContext context) {
    final int dias = trato.diasRestantesAl(ahora ?? DateTime.now());
    final String plazo = dias == 0 ? 'Hoy es el último día' : (dias == 1 ? 'Te queda 1 día' : 'Te quedan $dias días');
    return Container(
      key: ReputacionKeys.avisoCalificar(trato.ventaId),
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        color: AppColores.estrellaSuave,
        borderRadius: BorderRadius.circular(AppMedidas.radioCampo),
        border: Border.all(color: AppColores.estrella),
      ),
      child: Row(
        children: [
          const Icon(Icons.star_rounded, color: AppColores.estrella),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(trato.invitacion, style: AppTexto.subtitulo(size: 14)),
                Text(
                  '$plazo · ${trato.publicacionTitulo}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTexto.cuerpo(size: 12),
                ),
              ],
            ),
          ),
          TextButton(
            key: ReputacionKeys.calificarBoton(trato.ventaId),
            onPressed: onCalificar,
            style: TextButton.styleFrom(foregroundColor: AppColores.primario),
            child: const Text('Calificar'),
          ),
        ],
      ),
    );
  }
}
