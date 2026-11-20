import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/failures.dart';
import '../../../core/network/network_info.dart';
import '../../../core/widgets/app_ui.dart';
import '../../auth/domain/repositories/auth_repository.dart';
import '../../publicaciones/domain/entities/publicacion.dart';
import '../domain/entities/conversacion.dart';
import '../domain/errors/chat_failures.dart';
import '../domain/repositories/chat_repository.dart';
import '../domain/usecases/iniciar_conversacion.dart';
import 'pages/chat_page.dart';

/// HU-07: "Contactar al vendedor" desde el Detalle (Escenarios 1, 2, 5 y 6).
/// Abre (o crea) la conversación y muestra el chat. Si el servidor la
/// rechaza, muestra el motivo.
Future<void> contactarVendedor(BuildContext context, Publicacion publicacion) async {
  final IniciarConversacion iniciar = IniciarConversacion(
    context.read<ChatRepository>(),
    context.read<NetworkInfo>(),
  );
  final String? miId = context.read<AuthRepository>().usuarioActual?.id;
  try {
    final Conversacion conversacion = await iniciar(publicacion, miId: miId);
    if (context.mounted) await ChatPage.abrir(context, conversacion);
  } catch (error) {
    if (!context.mounted) return;
    final Failure falla = error is Failure ? error : const ChatServidorFailure();
    mostrarMensaje(context, falla.mensaje, esError: true);
  }
}
