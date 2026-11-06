import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../../../core/widgets/aviso_pantalla.dart';
import '../../../../core/widgets/filtros_texto.dart';
import '../../../../core/widgets/primary_button.dart';
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
/// Solo dibuja el estado del [ChatCubit].
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: ChatKeys.pantalla,
      body: SafeArea(
        child: BlocConsumer<ChatCubit, ChatState>(
          listener: _escuchar,
          builder: (context, state) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Encabezado(conversacion: state.conversacion),
                const Divider(height: 1, color: AppColores.borde),
                Expanded(child: _contenido(context, state)),
                if (state is ChatListo)
                  state.cerrada
                      ? const _AvisoCerrada()
                      : _CampoMensaje(
                          controller: _texto,
                          enviando: state.enviando,
                          puedeEnviar: (texto) => _validador.sePuedeEnviar(texto),
                          onEnviar: _enviar,
                        ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _contenido(BuildContext context, ChatState state) {
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
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppMedidas.margen),
          child: Text(
            state.conversacion.soyVendedor
                ? 'Aún no hay mensajes en esta conversación.'
                : 'Escríbele al vendedor para ponerse de acuerdo.',
            key: ChatKeys.bienvenida,
            textAlign: TextAlign.center,
            style: AppTexto.cuerpo(size: 14),
          ),
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
          final Mensaje mensaje = mensajes[mensajes.length - 1 - i];
          return BurbujaMensaje(mensaje: mensaje, esMio: mensaje.esDe(cubit.miId));
        },
      ),
    );
  }
}

/// El otro estudiante y la publicación de la conversación.
// TODO(diseño): encabezado del chat según Figma.
class _Encabezado extends StatelessWidget {
  const _Encabezado({required this.conversacion});

  final Conversacion conversacion;

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: ChatKeys.encabezado,
      padding: const EdgeInsets.fromLTRB(4, 8, AppMedidas.margen, 8),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Regresar',
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back_rounded, color: AppColores.primario),
          ),
          AvatarPerfil(fotoUrl: conversacion.otroFotoUrl, nombre: conversacion.otroNombre, radio: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  conversacion.otroNombre,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTexto.subtitulo(size: 16),
                ),
                Text(
                  conversacion.tituloVisible,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTexto.cuerpo(size: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Campo de texto y botón "Enviar".
// TODO(diseño): campo del chat según Figma.
class _CampoMensaje extends StatefulWidget {
  const _CampoMensaje({
    required this.controller,
    required this.enviando,
    required this.puedeEnviar,
    required this.onEnviar,
  });

  final TextEditingController controller;
  final bool enviando;
  final bool Function(String texto) puedeEnviar;
  final VoidCallback onEnviar;

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
    return Container(
      padding: const EdgeInsets.fromLTRB(AppMedidas.margen, 8, 8, 8),
      decoration: const BoxDecoration(
        color: AppColores.superficie,
        border: Border(top: BorderSide(color: AppColores.borde)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
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
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppMedidas.radioCampo),
                  borderSide: const BorderSide(color: AppColores.borde),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppMedidas.radioCampo),
                  borderSide: const BorderSide(color: AppColores.borde),
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          IconButton.filled(
            key: ChatKeys.enviarBoton,
            tooltip: 'Enviar',
            onPressed: habilitado ? widget.onEnviar : null,
            style: IconButton.styleFrom(
              backgroundColor: AppColores.primario,
              foregroundColor: AppColores.sobrePrimario,
              disabledBackgroundColor: AppColores.borde,
            ),
            icon: widget.enviando
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColores.sobrePrimario),
                  )
                : const Icon(Icons.send_rounded),
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
      padding: const EdgeInsets.all(AppMedidas.margen),
      color: AppColores.primarioSuave,
      child: Text(
        'Esta publicación ya no está disponible. Puedes leer la conversación, pero ya no enviar mensajes.',
        textAlign: TextAlign.center,
        style: AppTexto.cuerpo(size: 14, color: AppColores.primario),
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
