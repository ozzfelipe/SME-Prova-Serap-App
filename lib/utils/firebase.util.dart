// ignore_for_file: avoid_print

import 'dart:io';

import 'package:appserap/main.dart';
import 'package:appserap/main.ioc.dart';
import 'package:appserap/workers/jobs/baixar_prova.job.dart';
import 'package:firebase_core/firebase_core.dart' as fb;
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

setupFirebase() async {
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux)) {
    return;
  }

  try {
    logger.config('[Firebase] Configurando Firebase');
    await fb.Firebase.initializeApp();

    await setupCrashlytics();

    await registrarUsuarioLogado();
  } catch (e, stack) {
    logger.severe('[Firebase] Falha ao inicializar Firebase');
    await recordError(e, stack);
  }
}

Future<void> registrarUsuarioLogado() async {
  SharedPreferences prefs = await ServiceLocator.getAsync();
  String? ano = prefs.getString("serapUsuarioAno");
  String? codigoEOL = prefs.getString("serapUsuarioCodigoEOL");

  if (ano != null && ano.isNotEmpty) {
    await inscreverTurmaFirebase(ano);
  }

  if (codigoEOL != null && codigoEOL.isNotEmpty) {
    await setUserIdentifier(codigoEOL);
  }
}

setupCrashlytics() async {
  if (!kIsWeb && !Platform.isWindows) {
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;
  }
}

recordError(
  dynamic exception,
  StackTrace? stack, {
  dynamic reason,
}) async {
  if (!kIsWeb && !Platform.isWindows) {
    await FirebaseCrashlytics.instance.recordError(exception, stack);
  } else {
    print(exception);
    print(stack);
  }
}

setUserIdentifier(String identifier) async {
  if (!kIsWeb && !Platform.isWindows) {
    await FirebaseCrashlytics.instance.setUserIdentifier(identifier);
  }
}

inscreverTurmaFirebase(String ano) async {
  try {
    if (!await InternetConnection().hasInternetAccess) {
      return;
    }

    if (!kIsWeb && (Platform.isWindows || Platform.isLinux)) {
      return;
    }

    if (fb.Firebase.apps.isEmpty) {
      return;
    }

    logger.config('[Firebase] Inscrevendo no topico do ano $ano');
    await FirebaseMessaging.instance.subscribeToTopic('ano-$ano');

    String? token = await FirebaseMessaging.instance.getToken();
    print('Firebase Token: $token');

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    FirebaseMessaging.onMessage.listen(_firebaseMessagingBackgroundHandler);
  } catch (e, stack) {
    logger.severe('[Firebase] Falha ao inscrever no tópico do ano do aluno');
    await recordError(e, stack);
  }
}

desinscreverTurmaFirebase(String ano) async {
  try {
    if (!await InternetConnection().hasInternetAccess) {
      return;
    }

    if (!kIsWeb && (Platform.isWindows || Platform.isLinux)) {
      return;
    }

    if (fb.Firebase.apps.isEmpty) {
      return;
    }

    await FirebaseMessaging.instance.unsubscribeFromTopic('ano-$ano');
    logger.config('[Firebase] Desinscrevendo no topico do ano $ano');
  } catch (e, stack) {
    logger.severe('[Firebase] Falha ao desinscrever no tópico do ano $ano do aluno');
    await recordError(e, stack);
  }
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  logger.info('RECEBEU UMA MENSAGEM:');
  registerPluginsForIsolate();
  await configure(true);
  await BaixarProvaJob().run();
}
