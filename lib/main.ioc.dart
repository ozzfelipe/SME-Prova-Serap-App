import 'dart:async';

import 'package:appserap/database/app.database.dart';
import 'package:appserap/interfaces/loggable.interface.dart';
import 'package:appserap/services/api_service.dart';
import 'package:appserap/stores/apresentacao.store.dart';
import 'package:appserap/stores/home.store.dart';
import 'package:appserap/stores/login.store.dart';
import 'package:appserap/stores/orientacao_inicial.store.dart';
import 'package:appserap/stores/principal.store.dart';
import 'package:appserap/stores/prova.view.store.dart';
import 'package:appserap/stores/questao_revisao.store.dart';
import 'package:appserap/stores/questao_tai_view.store.dart';
import 'package:appserap/stores/tema.store.dart';
import 'package:appserap/stores/usuario.store.dart';
import 'package:chopper/chopper.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'database/respostas.database.dart';
import 'main.route.dart';
import 'stores/admin_prova_caderno.store.dart';
import 'stores/admin_prova_contexto.store.dart';
import 'stores/admin_prova_questao.store.dart';
import 'stores/admin_prova_resumo.store.dart';
import 'stores/contexto_prova_view.store.dart';
import 'stores/home.admin.store.dart';
import 'stores/home_provas_anteriores.store.dart';
import 'stores/job.store.dart';
import 'stores/login_adm.store.dart';
import 'stores/prova_resultado_resumo_view.store.dart';
import 'stores/prova_tai.view.store.dart';
import 'stores/questao.store.dart';
import 'stores/questao_resultado_detalhes_view.store.dart';
import 'stores/resumo_tai_view.store.dart';

import 'main.ioc.config.dart';

// ignore: non_constant_identifier_names
GetIt sl = GetIt.instance;

@InjectableInit(
  initializerName: 'init',
  preferRelativeImports: true,
  asExtension: true,
)
void configureDependencies() => sl.init();

@module
abstract class RegisterModule {
  @preResolve
  Future<SharedPreferences> get prefs => SharedPreferences.getInstance();

  @injectable
  ChopperClient get chopperClient => ApiService.create();

  InternetConnection get internetConnection => InternetConnection();
}

class DependenciasIoC with Loggable {
  setup() async {
    config('Configurando Injeção de Dependencias');
    sl.allowReassignment = true;
    registrarServicosAsync();
    await sl.allReady();

    registrarServicos();
    registrarStores();



    await sl.allReady();
  }

  registrarServicosAsync() {
    registerSingletonAsync<SharedPreferences>(() async => SharedPreferences.getInstance());
  }

  registrarServicos() {
    registerSingleton<AppDatabase>(AppDatabase());
    registerSingleton<RespostasDatabase>(RespostasDatabase());
    registerSingleton<AppRouter>(AppRouter());
  }

  registrarStores() {
    registerSingleton<UsuarioStore>(UsuarioStore());
    registerSingleton<PrincipalStore>(PrincipalStore());
    registerSingleton<LoginStore>(LoginStore());
    registerSingleton<TemaStore>(TemaStore());
    registerSingleton<HomeStore>(HomeStore());
    registerSingleton<ProvaViewStore>(ProvaViewStore());
    registerSingleton<ApresentacaoStore>(ApresentacaoStore());
    registerSingleton<OrientacaoInicialStore>(OrientacaoInicialStore());
    registerSingleton<HomeProvasAnterioresStore>(HomeProvasAnterioresStore());
    registerSingleton<QuestaoStore>(QuestaoStore());
    registerSingleton<QuestaoRevisaoStore>(QuestaoRevisaoStore());
    registerSingleton<LoginAdmStore>(LoginAdmStore());
    registerSingleton<HomeAdminStore>(HomeAdminStore());
    registerSingleton<AdminProvaCadernoViewStore>(AdminProvaCadernoViewStore());
    registerSingleton<AdminProvaResumoViewStore>(AdminProvaResumoViewStore());
    registerSingleton<AdminProvaQuestaoViewStore>(AdminProvaQuestaoViewStore());
    registerSingleton<AdminProvaContextoViewStore>(AdminProvaContextoViewStore());
    registerSingleton<ContextoProvaViewStore>(ContextoProvaViewStore());
    registerSingleton<JobStore>(JobStore());
    registerSingleton<ProvaResultadoResumoViewStore>(ProvaResultadoResumoViewStore());
    registerSingleton<QuestaoResultadoDetalhesViewStore>(QuestaoResultadoDetalhesViewStore());
    registerSingleton<ProvaTaiViewStore>(ProvaTaiViewStore());
    registerSingleton<QuestaoTaiViewStore>(QuestaoTaiViewStore());
    registerSingleton<ResumoTaiViewStore>(ResumoTaiViewStore());
  }

  void registerSingletonAsync<T extends Object>(
    Future<T> Function() factoryFunc, {
    String? instanceName,
    Iterable<Type>? dependsOn,
    bool? signalsReady,
    FutureOr<dynamic> Function(T)? dispose,
  }) {
    if (!sl.isRegistered<T>()) {
      finest('[SingletonAsync] Registrando ${T.toString()}');
      sl.registerSingletonAsync<T>(
        factoryFunc,
        instanceName: instanceName,
        dependsOn: dependsOn,
        signalsReady: signalsReady,
        dispose: dispose,
      );
    }
  }

  void registerSingleton<T extends Object>(
    T instance, {
    String? instanceName,
    bool? signalsReady,
    FutureOr<dynamic> Function(T)? dispose,
  }) {
    if (!sl.isRegistered<T>()) {
      finest('[Singleton] Registrando ${T.toString()}');
      sl.registerSingleton<T>(
        instance,
        instanceName: instanceName,
        signalsReady: signalsReady,
        dispose: dispose,
      );
    }
  }
}
