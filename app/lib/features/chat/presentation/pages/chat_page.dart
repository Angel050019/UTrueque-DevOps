import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formato_fecha.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../../../core/widgets/aviso_pantalla.dart';
import '../../../../core/widgets/filtros_texto.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../encuentros/domain/entities/encuentro.dart';
import '../../../encuentros/presentation/cubit/encuentros_cubit.dart';
import '../../../encuentros/presentation/cubit/encuentros_state.dart';
import '../../../encuentros/presentation/encuentro_keys.dart';
import '../../../encuentros/presentation/widgets/hoja_proponer_encuentro.dart';
import '../../../encuentros/presentation/widgets/tarjeta_encuentro.dart';
import '../../../perfil/presentation/widgets/avatar_perfil.dart';
import '../../domain/entities/conversacion.dart';
import '../../domain/entities/mensaje.dart';
import '../../domain/validators/mensaje_validator.dart';
import '../chat_keys.dart';
import '../cubit/chat_cubit.dart';
import '../cubit/chat_state.dart';
import '../widgets/burbuja_mensaje.dart';

/// Lo que recibe la ruta `/chat`.
class ChatArgs {
  const ChatArgs(this.conversacion);

  final Conversacion conversacion;
}

/// Pantalla "Chat" (HU-07, issue #2). Se abre con "Contactar al vendedor"
/// desde el Detalle o desde la bandeja de mensajes.
///
/// Arriba: el otro estudiante y la publicación. En medio: los mensajes (el
/// más nuevo abajo; al subir se cargan los anteriores). Abajo: el campo de
/// texto, o el aviso de conversación cerrada.
///
/// HU-08: arriba, el aviso fijo del encuentro confirmado; en la lista, las
/// tarjetas de encuentro; junto al campo, "Proponer punto de encuentro".
///
/// Solo dibuja el estado del [ChatCubit] y del [EncuentrosCubit].
class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  /// Abre el chat de [conversacion]. Se pide la ruta sin tipo (ver la nota
  /// de `PublicarArticuloPage.editar`).
  static Future<void> abrir(BuildContext context, Conversacion conversacion) async {
    await Navigator.of(context).pushNamed(AppRoutes.chat, arguments: ChatArgs(conversacion));
  }

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  /// Cuánto falta para llegar al primer mensaje para pedir los anteriores.
  static const double _distanciaParaCargarAnteriores = 300;
  static const MensajeValidator _validador = MensajeValidator();

  final TextEditingController _texto = TextEditingController();

  @override
  void dispose() {
    _texto.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    final bool enviado = await context.read<ChatCubit>().enviar(_texto.text);
    // Si no se envió, el texto se conserva (Escenarios 13 y 14).
    if (enviado && mounted) _texto.clear();
  }

  void _escuchar(BuildContext context, ChatState state) {
    if (state is ChatListo && state.aviso != null) {
      mostrarMensaje(context, state.aviso!, esError: true);
      context.read<ChatCubit>().avisoMostrado();
    }
  }

  // ---------------------------------------------------------------------
  // HU-08: punto de encuentro
  // ---------------------------------------------------------------------

  void _escucharEncuentros(BuildContext context, EncuentrosState state) {
    final String? aviso = state.aviso;
    if (aviso == null) return;
    mostrarMensaje(context, aviso, esError: state.avisoEsError);
    context.read<EncuentrosCubit>().avisoMostrado();
  }

  /// Después de una acción se piden los mensajes nuevos, por si el tiempo
  /// real tarda o está apagado (la tarjeta la crea el servidor).
  void _alCambiarEncuentro(bool enviado) {
    if (enviado && mounted) context.read<ChatCubit>().actualizar();
  }

  Future<void> _proponer() async {
    final EncuentrosCubit encuentros = context.read<EncuentrosCubit>();
    final bool enviada = await HojaProponerEncuentro.abrir(
      context,
      conversacion: encuentros.conversacion,
      encuentroActivo: encuentros.state.activoAl(encuentros.ahora),
    );
    if (!enviada || !mounted) return;
    mostrarMensaje(context, 'Propuesta enviada.');
    _alCambiarEncuentro(true);
    await encuentros.actualizar();
  }

  Future<void> _aceptar(Encuentro encuentro) async =>
      _alCambiarEncuentro(await context.read<EncuentrosCubit>().responder(encuentro, acepta: true));

  Future<void> _rechazar(Encuentro encuentro) async =>
      _alCambiarEncuentro(await context.read<EncuentrosCubit>().responder(encuentro, acepta: false));

  /// Escenario 4: se pide confirmación antes de cancelar.
  Future<void> _cancelar(Encuentro encuentro) async {
    final EncuentrosCubit encuentros = context.read<EncuentrosCubit>();
    final bool? confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogo) => AlertDialog(
        title: const Text('¿Cancelar el encuentro?'),
        content: Text('Se avisará al otro estudiante que ya no se verán en ${encuentro.punto.nombre}.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogo).pop(false), child: const Text('No')),
          TextButton(
            key: EncuentroKeys.confirmarCancelar,
            onPressed: () => Navigator.of(dialogo).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColores.error),
            child: const Text('Sí, cancelar'),
          ),
        ],
      ),
    );
    if (confirmado != true) return;
    _alCambiarEncuentro(await encuentros.cancelar(encuentro));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: ChatKeys.pantalla,
      backgroundColor: AppColores.fondo,
      body: SafeArea(
        child: BlocListener<EncuentrosCubit, EncuentrosState>(
          listenWhen: (antes, ahora) => ahora.aviso != null && antes.aviso != ahora.aviso,
          listener: _escucharEncuentros,
          child: BlocConsumer<ChatCubit, ChatState>(
            listener: _escuchar,
            builder: (context, state) {
              return BlocBuilder<EncuentrosCubit, EncuentrosState>(
                builder: (context, encuentros) {
                  final EncuentrosCubit cubitEncuentros = context.read<EncuentrosCubit>();
                  final Encuentro? confirmado = encuentros.confirmadoAl(cubitEncuentros.ahora);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _Encabezado(conversacion: state.conversacion),
                      // HU-08, Escenario 2: aviso fijo del encuentro confirmado.
                      if (confirmado != null) AvisoEncuentroConfirmado(encuentro: confirmado),
                      Expanded(child: _contenido(context, state, encuentros)),
                      if (state is ChatListo)
                        state.cerrada
                            ? const _AvisoCerrada()
                            : _CampoMensaje(
                                controller: _texto,
                                enviando: state.enviando,
                                puedeEnviar: (texto) => _validador.sePuedeEnviar(texto),
                                onEnviar: _enviar,
                                // HU-08, Escenarios 7 y 10.
                                onProponer: cubitEncuentros.puedeProponer ? _proponer : null,
                              ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _contenido(BuildContext context, ChatState state, EncuentrosState encuentros) {
    final ChatCubit cubit = context.read<ChatCubit>();
    if (state is ChatError) {
      // TODO(diseño): ilustración de error y de sin conexión.
      return AvisoPantalla(
        key: ChatKeys.error,
        icono: state.sinConexion ? Icons.wifi_off_rounded : Icons.cloud_off_rounded,
        titulo: 'No pudimos abrir la conversación',
        texto: state.mensaje,
        margen: const EdgeInsets.all(AppMedidas.margen),
        accion: PrimaryButton(key: ChatKeys.reintentarBoton, texto: 'Reintentar', onPressed: cubit.abrir),
      );
    }
    if (state is! ChatListo) {
      return const Center(child: CircularProgressIndicator(key: ChatKeys.cargando, color: AppColores.primario));
    }
    if (state.mensajes.isEmpty) {
      return _ChatVacio(
        soyVendedor: state.conversacion.soyVendedor,
        // Mensajes sugeridos: solo llenan el campo; el estudiante decide si los envía.
        onSugerencia: state.cerrada
            ? null
            : (texto) => _texto.value = TextEditingValue(
                  text: texto,
                  selection: TextSelection.collapsed(offset: texto.length),
                ),
      );
    }
    final List<Mensaje> mensajes = state.mensajes;
    return NotificationListener<ScrollNotification>(
      onNotification: (notificacion) {
        // La lista está volteada: el "final" es el mensaje más viejo.
        if (notificacion.metrics.extentAfter < _distanciaParaCargarAnteriores) cubit.cargarAnteriores();
        return false;
      },
      child: ListView.builder(
        key: ChatKeys.lista,
        reverse: true,
        padding: const EdgeInsets.symmetric(horizontal: AppMedidas.margen, vertical: 12),
        // Una fila extra arriba: cargando anteriores o su error.
        itemCount: mensajes.length + 1,
        itemBuilder: (context, i) {
          if (i == mensajes.length) return _InicioDeLista(state: state, onReintentar: cubit.cargarAnteriores);
          final int indice = mensajes.length - 1 - i;
          final Mensaje mensaje = mensajes[indice];
          final Mensaje? anterior = indice > 0 ? mensajes[indice - 1] : null;
          final bool otroDia = anterior == null || !_mismoDia(anterior.creadoEn, mensaje.creadoEn);
          final Widget elemento = _elemento(context, state, encuentros, mensaje, anterior, otroDia);
          if (!otroDia) return elemento;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [_SeparadorDia(fecha: mensaje.creadoEn), elemento],
          );
        },
      ),
    );
  }

  static bool _mismoDia(DateTime a, DateTime b) {
    final DateTime x = a.toLocal();
    final DateTime y = b.toLocal();
    return x.year == y.year && x.month == y.month && x.day == y.day;
  }

  Widget _elemento(
    BuildContext context,
    ChatListo state,
    EncuentrosState encuentros,
    Mensaje mensaje,
    Mensaje? anterior,
    bool otroDia,
  ) {
    final ChatCubit cubit = context.read<ChatCubit>();
    final EncuentrosCubit cubitEncuentros = context.read<EncuentrosCubit>();
    if (mensaje.esDeEncuentro) {
      // HU-08: tarjeta de encuentro.
      return TarjetaEncuentro(
        mensaje: mensaje,
        encuentro: encuentros.porId(mensaje.encuentroId),
        miId: cubit.miId,
        ahora: cubitEncuentros.ahora,
        habilitada: !encuentros.enviando && !cubitEncuentros.cerrada && !state.cerrada,
        onAceptar: _aceptar,
        onRechazar: _rechazar,
        onCancelar: _cancelar,
      );
    }
    // Mensajes seguidos del mismo autor (y del mismo día) se pegan entre sí.
    final bool continuacion = !otroDia &&
        anterior != null &&
        !anterior.esDeEncuentro &&
        anterior.autorId == mensaje.autorId &&
        mensaje.creadoEn.difference(anterior.creadoEn).inMinutes < 5;
    return BurbujaMensaje(mensaje: mensaje, esMio: mensaje.esDe(cubit.miId), continuacion: continuacion);
  }
}

/// El otro estudiante y la publicación de la conversación, sobre una
/// franja azul marino.
class _Encabezado extends StatelessWidget {
  const _Encabezado({required this.conversacion});

  final Conversacion conversacion;

  @override
  Widget build(BuildContext context) {
    final String? foto = conversacion.publicacionFotoUrl;
    return Container(
      key: ChatKeys.encabezado,
      padding: const EdgeInsets.fromLTRB(4, 10, 16, 12),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColores.primario, AppColores.primarioOscuro],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Regresar',
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back_rounded, color: AppColores.sobrePrimario),
          ),
          Container(
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(color: AppColores.acento, shape: BoxShape.circle),
            child: AvatarPerfil(fotoUrl: conversacion.otroFotoUrl, nombre: conversacion.otroNombre, radio: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  conversacion.otroNombre,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTexto.subtitulo(size: 16, color: AppColores.sobrePrimario),
                ),
                Row(
                  children: [
                    const Icon(Icons.sell_rounded, size: 13, color: AppColores.acento),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        conversacion.tituloVisible,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTexto.cuerpo(size: 13, color: AppColores.primarioSuave),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (foto != null) ...[
            const SizedBox(width: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                foto,
                width: 44,
                height: 44,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stack) => const SizedBox(width: 44, height: 44),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Separador con el día ("Hoy", "Ayer" o la fecha) entre mensajes de días
/// distintos.
class _SeparadorDia extends StatelessWidget {
  const _SeparadorDia({required this.fecha});

  final DateTime fecha;

  String _etiqueta() {
    final DateTime l = fecha.toLocal();
    final DateTime hoy = DateTime.now();
    final int dias = DateTime(hoy.year, hoy.month, hoy.day).difference(DateTime(l.year, l.month, l.day)).inDays;
    if (dias == 0) return 'Hoy';
    if (dias == 1) return 'Ayer';
    return formatearFecha(l);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 4),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppColores.primarioSuave,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(_etiqueta(), style: AppTexto.cuerpo(size: 12, color: AppColores.primario, peso: FontWeight.w600)),
        ),
      ),
    );
  }
}

/// Conversación sin mensajes: ilustración, indicación y mensajes sugeridos
/// que llenan el campo de texto (el estudiante decide si los envía).
class _ChatVacio extends StatelessWidget {
  const _ChatVacio({required this.soyVendedor, required this.onSugerencia});

  final bool soyVendedor;
  final ValueChanged<String>? onSugerencia;

  static const List<String> _sugerenciasComprador = [
    '¡Hola! ¿Sigue disponible?',
    '¿Lo podemos ver en la Biblioteca?',
    '¿Aceptas un trueque?',
  ];
  static const List<String> _sugerenciasVendedor = [
    '¡Hola! Sí, sigue disponible.',
    '¿Te parece vernos en la Cafetería?',
  ];

  @override
  Widget build(BuildContext context) {
    final ValueChanged<String>? alElegir = onSugerencia;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppMedidas.margen),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: const BoxDecoration(color: AppColores.primarioSuave, shape: BoxShape.circle),
              child: const Icon(Icons.forum_rounded, size: 44, color: AppColores.primario),
            ),
            const SizedBox(height: 16),
            Text(
              soyVendedor ? 'Aún no hay mensajes en esta conversación.' : 'Escríbele al vendedor para ponerse de acuerdo.',
              key: ChatKeys.bienvenida,
              textAlign: TextAlign.center,
              style: AppTexto.subtitulo(size: 15),
            ),
            const SizedBox(height: 6),
            Text(
              'Nunca compartas contraseñas ni datos bancarios. Vean el artículo en una zona segura del campus.',
              textAlign: TextAlign.center,
              style: AppTexto.cuerpo(size: 13),
            ),
            if (alElegir != null) ...[
              const SizedBox(height: 18),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final String s in soyVendedor ? _sugerenciasVendedor : _sugerenciasComprador)
                    ActionChip(
                      label: Text(s),
                      onPressed: () => alElegir(s),
                      backgroundColor: AppColores.superficie,
                      side: const BorderSide(color: AppColores.borde),
                      labelStyle: AppTexto.cuerpo(size: 13, color: AppColores.primario, peso: FontWeight.w600),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Campo de texto y botón "Enviar".
class _CampoMensaje extends StatefulWidget {
  const _CampoMensaje({
    required this.controller,
    required this.enviando,
    required this.puedeEnviar,
    required this.onEnviar,
    required this.onProponer,
  });

  final TextEditingController controller;
  final bool enviando;
  final bool Function(String texto) puedeEnviar;
  final VoidCallback onEnviar;

  /// HU-08: "Proponer punto de encuentro"; `null` lo deshabilita.
  final VoidCallback? onProponer;

  @override
  State<_CampoMensaje> createState() => _CampoMensajeState();
}

class _CampoMensajeState extends State<_CampoMensaje> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_redibujar);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_redibujar);
    super.dispose();
  }

  void _redibujar() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final bool habilitado = !widget.enviando && widget.puedeEnviar(widget.controller.text);
    final OutlineInputBorder borde = OutlineInputBorder(
      borderRadius: BorderRadius.circular(24),
      borderSide: BorderSide.none,
    );
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
      decoration: const BoxDecoration(
        color: AppColores.superficie,
        boxShadow: [BoxShadow(color: Color(0x14033B56), blurRadius: 12, offset: Offset(0, -2))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // HU-08: botón para proponer un punto de encuentro.
          IconButton.filledTonal(
            key: EncuentroKeys.botonProponer,
            tooltip: 'Proponer punto de encuentro',
            onPressed: widget.onProponer,
            style: IconButton.styleFrom(
              backgroundColor: AppColores.acentoSuave,
              foregroundColor: AppColores.primario,
              disabledBackgroundColor: AppColores.fondo,
              disabledForegroundColor: AppColores.borde,
            ),
            icon: const Icon(Icons.add_location_alt_rounded),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: TextField(
              key: ChatKeys.campoTexto,
              controller: widget.controller,
              minLines: 1,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              // SEGURIDAD: solo caracteres permitidos y máximo 500.
              inputFormatters: [
                ...FiltrosTexto.descripcion,
                LengthLimitingTextInputFormatter(MensajeValidator.longitudMaxima),
              ],
              style: AppTexto.cuerpo(size: 15, color: AppColores.texto),
              decoration: InputDecoration(
                hintText: 'Escribe un mensaje',
                hintStyle: AppTexto.cuerpo(size: 15),
                filled: true,
                fillColor: AppColores.fondo,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                border: borde,
                enabledBorder: borde,
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: AppColores.primario, width: 1.2),
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          AnimatedScale(
            scale: habilitado || widget.enviando ? 1 : 0.9,
            duration: const Duration(milliseconds: 150),
            child: IconButton.filled(
              key: ChatKeys.enviarBoton,
              tooltip: 'Enviar',
              onPressed: habilitado ? widget.onEnviar : null,
              style: IconButton.styleFrom(
                backgroundColor: AppColores.primario,
                foregroundColor: AppColores.acento,
                disabledBackgroundColor: AppColores.borde,
                disabledForegroundColor: AppColores.superficie,
                minimumSize: const Size(46, 46),
              ),
              icon: widget.enviando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColores.sobrePrimario),
                    )
                  : const Icon(Icons.send_rounded),
            ),
          ),
        ],
      ),
    );
  }
}

/// Escenario 11: la publicación se vendió o se borró.
class _AvisoCerrada extends StatelessWidget {
  const _AvisoCerrada();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ChatKeys.cerradaAviso,
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColores.primarioSuave,
        borderRadius: BorderRadius.circular(AppMedidas.radioCampo),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_outline_rounded, color: AppColores.primario),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Esta publicación ya no está disponible. Puedes leer la conversación, pero ya no enviar mensajes.',
              style: AppTexto.cuerpo(size: 13, color: AppColores.primario),
            ),
          ),
        ],
      ),
    );
  }
}

/// Lo que se ve arriba de todo: cargando anteriores o su error.
class _InicioDeLista extends StatelessWidget {
  const _InicioDeLista({required this.state, required this.onReintentar});

  final ChatListo state;
  final VoidCallback onReintentar;

  @override
  Widget build(BuildContext context) {
    final String? error = state.errorAnteriores;
    if (error != null) {
      return Padding(
        key: ChatKeys.errorAnteriores,
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            Text(error, textAlign: TextAlign.center, style: AppTexto.cuerpo(size: 13)),
            TextButton(
              key: ChatKeys.reintentarAnterioresBoton,
              onPressed: onReintentar,
              style: TextButton.styleFrom(foregroundColor: AppColores.primario),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }
    if (state.hayAnteriores) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              key: ChatKeys.cargandoAnteriores,
              strokeWidth: 2.5,
              color: AppColores.primario,
            ),
          ),
        ),
      );
    }
    return const SizedBox(height: 4);
  }
}
