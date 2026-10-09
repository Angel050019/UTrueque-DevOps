import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../domain/entities/foto_articulo.dart';
import '../../domain/errors/publicacion_failures.dart';
import '../cubit/publicacion_cubit.dart';
import '../cubit/publicacion_state.dart';
import '../publicacion_keys.dart';
import '../widgets/elegir_fotos_articulo.dart';
import '../widgets/estado_carga_publicacion.dart';
import '../widgets/selector_categoria.dart';
import '../widgets/selector_fotos.dart';
import '../widgets/selector_modalidad.dart';
import 'publicacion_confirmada_page.dart';

/// Pantalla "Publicar artículo" (HU-03, issue #4).
/// Se abre desde el botón "Publicar" del Feed. Al publicar con éxito
/// (201 Created) regresa al Feed principal.
///
/// Solo dibuja el estado del [PublicacionCubit] y le pasa lo que el
/// estudiante escribe; las validaciones viven en el Cubit y en los casos de
/// uso.
class PublicarArticuloPage extends StatefulWidget {
  const PublicarArticuloPage({super.key});

  @override
  State<PublicarArticuloPage> createState() => _PublicarArticuloPageState();
}

class _PublicarArticuloPageState extends State<PublicarArticuloPage> {
  final TextEditingController _tituloController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();
  final TextEditingController _precioController = TextEditingController();

  @override
  void dispose() {
    _tituloController.dispose();
    _descripcionController.dispose();
    _precioController.dispose();
    super.dispose();
  }

  Future<void> _agregarFotos(PublicacionCubit cubit, int yaElegidas) async {
    final List<FotoArticulo> fotos = await elegirFotosArticulo(
      maximo: AppConstants.fotosPorPublicacionMaximo - yaElegidas,
    );
    if (fotos.isNotEmpty) cubit.agregarFotos(fotos);
  }

  void _publicar(PublicacionCubit cubit) {
    FocusScope.of(context).unfocus();
    cubit.publicar(
      titulo: _tituloController.text,
      descripcion: _descripcionController.text,
      precioTexto: _precioController.text,
    );
  }

  void _escuchar(BuildContext context, PublicacionState state) {
    if (state is PublicacionPublicada) {
      // Feed recargado + pantalla "Tu publicación está activa" encima.
      PublicacionConfirmadaPage.mostrar(
        context,
        publicacion: state.publicacion,
        portada: state.datos.fotos.isEmpty ? null : state.datos.fotos.first,
        categoriaNombre: state.datos.categoria?.nombre,
      );
    }
    if (state is PublicacionError && state.datos != null) {
      mostrarMensaje(context, state.mensaje, esError: true);
    }
  }

  Widget _construir(BuildContext context, PublicacionState state) {
    final PublicacionDatos? datos = state.datos;
    if (datos == null) {
      if (state is PublicacionError) {
        return ErrorCargaPublicacion(
          mensaje: state.mensaje,
          onReintentar: context.read<PublicacionCubit>().cargarCategorias,
        );
      }
      return const CargandoPublicacion();
    }
    return _formulario(context, state, datos);
  }

  Widget _formulario(BuildContext context, PublicacionState state, PublicacionDatos datos) {
    final PublicacionCubit cubit = context.read<PublicacionCubit>();
    final bool enviando = state is PublicacionEnviando || state is PublicacionPublicada;

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
              SelectorFotos(
                fotos: datos.fotos,
                error: datos.errorDe(CampoPublicacion.fotos),
                habilitado: !enviando,
                onAgregar: () => _agregarFotos(cubit, datos.fotos.length),
                onQuitar: cubit.quitarFoto,
              ),
              const SizedBox(height: 20),
              AppTextField(
                key: PublicacionKeys.tituloField,
                controller: _tituloController,
                label: 'Título',
                hint: 'Ej. Calculadora Casio fx-991',
                habilitado: !enviando,
                textoError: datos.errorDe(CampoPublicacion.titulo),
                onChanged: (_) => cubit.campoEditado(CampoPublicacion.titulo),
              ),
              const SizedBox(height: 16),
              AppTextField(
                key: PublicacionKeys.descripcionField,
                controller: _descripcionController,
                label: 'Descripción',
                hint: 'Estado, edición, detalles que deba saber quien lo reciba…',
                lineas: 4,
                habilitado: !enviando,
                textoError: datos.errorDe(CampoPublicacion.descripcion),
                onChanged: (_) => cubit.campoEditado(CampoPublicacion.descripcion),
              ),
              const SizedBox(height: 16),
              SelectorCategoria(
                categorias: datos.categorias,
                seleccionada: datos.categoria,
                error: datos.errorDe(CampoPublicacion.categoria),
                habilitado: !enviando,
                onChanged: cubit.seleccionarCategoria,
              ),
              const SizedBox(height: 16),
              SelectorModalidad(
                seleccionada: datos.modalidad,
                error: datos.errorDe(CampoPublicacion.modalidad),
                habilitado: !enviando,
                onSeleccionar: cubit.seleccionarModalidad,
              ),
              if (datos.muestraPrecio) ...[
                const SizedBox(height: 16),
                AppTextField(
                  key: PublicacionKeys.precioField,
                  controller: _precioController,
                  label: 'Precio',
                  hint: '0.00',
                  prefijo: r'$ ',
                  tipoTeclado: const TextInputType.numberWithOptions(decimal: true),
                  habilitado: !enviando,
                  textoError: datos.errorDe(CampoPublicacion.precio),
                  onChanged: (_) => cubit.campoEditado(CampoPublicacion.precio),
                ),
              ],
              const SizedBox(height: 20),
              const _AvisoPublicacion(),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(AppMedidas.margen, 8, AppMedidas.margen, 16),
            child: PrimaryButton(
              key: PublicacionKeys.publicarBoton,
              texto: 'Publicar artículo',
              cargando: enviando,
              onPressed: () => _publicar(cubit),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const BarraSuperior(titulo: 'Publicar artículo'),
            Expanded(
              child: BlocConsumer<PublicacionCubit, PublicacionState>(
                listener: _escuchar,
                builder: _construir,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Recordatorio de cómo se verá la publicación.
class _AvisoPublicacion extends StatelessWidget {
  const _AvisoPublicacion();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColores.acentoSuave,
        borderRadius: BorderRadius.circular(AppMedidas.radioTarjeta),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.verified_user_rounded, color: AppColores.primario, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Tu artículo aparecerá como Disponible y solo lo verán estudiantes '
              'de la UTSJR con su cuenta institucional.',
              style: AppTexto.cuerpo(size: 13, color: AppColores.texto),
            ),
          ),
        ],
      ),
    );
  }
}
