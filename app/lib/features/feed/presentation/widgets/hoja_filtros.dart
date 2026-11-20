import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../perfil/domain/entities/carrera.dart';
import '../../../perfil/domain/entities/division.dart';
import '../cubit/feed_cubit.dart';
import '../cubit/feed_state.dart';
import '../cubit/opciones_filtro.dart';
import '../feed_keys.dart';

/// Abre la hoja de filtros de división y carrera (HU-05, Escenario 3).
Future<void> mostrarHojaFiltros(BuildContext context) {
  final FeedCubit cubit = context.read<FeedCubit>();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: AppColores.superficie,
    builder: (_) => BlocProvider<FeedCubit>.value(
      value: cubit,
      child: const HojaFiltros(),
    ),
  );
}

/// Hoja con los selectores encadenados División → Carrera.
///
/// Lo elegido aquí solo se aplica al presionar "Aplicar"; "Quitar" deja
/// todas las divisiones y carreras. La carrera solo se puede elegir de la
/// división elegida (si se cambia la división, la carrera se limpia).
class HojaFiltros extends StatefulWidget {
  const HojaFiltros({super.key});

  @override
  State<HojaFiltros> createState() => _HojaFiltrosState();
}

class _HojaFiltrosState extends State<HojaFiltros> {
  int? _divisionId;
  int? _carreraId;

  @override
  void initState() {
    super.initState();
    final FeedState state = context.read<FeedCubit>().state;
    _divisionId = state.filtros.divisionId;
    _carreraId = state.filtros.carreraId;
    if (state.opciones.divisiones.isEmpty) {
      context.read<FeedCubit>().recargarOpciones();
    }
  }

  void _elegirDivision(int? divisionId) {
    setState(() {
      if (divisionId != _divisionId) _carreraId = null;
      _divisionId = divisionId;
    });
  }

  void _aplicar({required bool quitar}) {
    final FeedCubit cubit = context.read<FeedCubit>();
    if (quitar) {
      cubit.aplicarDivisionYCarrera();
    } else {
      cubit.aplicarDivisionYCarrera(divisionId: _divisionId, carreraId: _carreraId);
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final double teclado = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      key: FeedKeys.hojaFiltros,
      padding: EdgeInsets.fromLTRB(AppMedidas.margen, 0, AppMedidas.margen, 24 + teclado),
      child: BlocBuilder<FeedCubit, FeedState>(
        buildWhen: (anterior, actual) => anterior.opciones != actual.opciones,
        builder: (context, state) {
          final OpcionesFiltro opciones = state.opciones;
          // La carrera solo es válida si pertenece a la división elegida.
          final List<Carrera> carreras = opciones.carrerasDe(_divisionId);
          final int? carreraId = carreras.any((c) => c.id == _carreraId) ? _carreraId : null;
          final bool divisionValida = opciones.divisiones.any((d) => d.id == _divisionId);
          final int? divisionId = divisionValida ? _divisionId : null;

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Filtrar por división y carrera', style: AppTexto.subtitulo(size: 18)),
              const SizedBox(height: 4),
              Text(
                'Verás las publicaciones de estudiantes de esa división o carrera.',
                style: AppTexto.cuerpo(size: 13),
              ),
              const SizedBox(height: 20),
              if (opciones.divisiones.isEmpty)
                _SinCatalogo(onReintentar: context.read<FeedCubit>().recargarOpciones)
              else ...[
                // TODO(diseño): selectores de la hoja de filtros.
                _Selector(
                  etiqueta: 'División',
                  selectorKey: FeedKeys.divisionFiltro,
                  valor: divisionId,
                  textoTodas: 'Todas las divisiones',
                  opciones: {for (final Division d in opciones.divisiones) d.id: d.nombre},
                  onChanged: _elegirDivision,
                ),
                const SizedBox(height: 16),
                _Selector(
                  etiqueta: 'Carrera',
                  selectorKey: FeedKeys.carreraFiltro,
                  valor: carreraId,
                  textoTodas: divisionId == null ? 'Primero elige una división' : 'Todas las carreras',
                  opciones: {for (final Carrera c in carreras) c.id: c.nombre},
                  onChanged: divisionId == null ? null : (id) => setState(() => _carreraId = id),
                ),
              ],
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: SecondaryButton(
                      key: FeedKeys.quitarFiltrosAcademicosBoton,
                      texto: 'Quitar',
                      onPressed: () => _aplicar(quitar: true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: PrimaryButton(
                      key: FeedKeys.aplicarFiltrosBoton,
                      texto: 'Aplicar',
                      onPressed: opciones.divisiones.isEmpty ? null : () => _aplicar(quitar: false),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Selector con el mismo estilo que los del perfil. La primera opción
/// (`null`) es "Todas…".
class _Selector extends StatelessWidget {
  const _Selector({
    required this.etiqueta,
    required this.selectorKey,
    required this.valor,
    required this.textoTodas,
    required this.opciones,
    required this.onChanged,
  });

  final String etiqueta;
  final Key selectorKey;
  final int? valor;
  final String textoTodas;
  final Map<int, String> opciones;

  /// `null` deshabilita el selector.
  final ValueChanged<int?>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onChanged == null ? 0.55 : 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(etiqueta, style: AppTexto.etiqueta()),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: AppColores.superficie,
              borderRadius: BorderRadius.circular(AppMedidas.radioCampo),
              border: Border.all(color: AppColores.borde, width: 1.5),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int?>(
                key: selectorKey,
                isExpanded: true,
                value: valor,
                borderRadius: BorderRadius.circular(AppMedidas.radioCampo),
                dropdownColor: AppColores.superficie,
                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColores.textoSecundario),
                style: AppTexto.cuerpo(color: AppColores.texto),
                items: [
                  DropdownMenuItem<int?>(
                    value: null,
                    child: Text(textoTodas, overflow: TextOverflow.ellipsis),
                  ),
                  for (final MapEntry<int, String> opcion in opciones.entries)
                    DropdownMenuItem<int?>(
                      value: opcion.key,
                      child: Text(opcion.value, overflow: TextOverflow.ellipsis),
                    ),
                ],
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// No se pudo cargar el catálogo (por ejemplo, sin internet).
class _SinCatalogo extends StatelessWidget {
  const _SinCatalogo({required this.onReintentar});

  final VoidCallback onReintentar;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'No pudimos cargar las divisiones y carreras. Revisa tu conexión.',
          textAlign: TextAlign.center,
          style: AppTexto.cuerpo(size: 14),
        ),
        TextButton(
          key: FeedKeys.reintentarOpcionesBoton,
          onPressed: onReintentar,
          style: TextButton.styleFrom(foregroundColor: AppColores.primario),
          child: const Text('Reintentar'),
        ),
      ],
    );
  }
}
