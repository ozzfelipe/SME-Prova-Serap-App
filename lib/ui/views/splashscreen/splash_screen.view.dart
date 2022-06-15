import 'package:appserap/interfaces/loggable.interface.dart';
import 'package:appserap/main.ioc.dart';
import 'package:appserap/services/api.dart';
import 'package:appserap/stores/principal.store.dart';
import 'package:appserap/stores/tema.store.dart';
import 'package:appserap/utils/app_config.util.dart';
import 'package:appserap/utils/tela_adaptativa.util.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:imei_plugin/imei_plugin.dart';
import 'package:lottie/lottie.dart';
import 'package:mobx/mobx.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:updater/updater.dart';

class SplashScreenView extends StatefulWidget {
  const SplashScreenView({Key? key}) : super(key: key);

  @override
  State<SplashScreenView> createState() => _SplashScreenViewState();
}

class _SplashScreenViewState extends State<SplashScreenView> with Loggable {
  final _principalStore = GetIt.I.get<PrincipalStore>();
  final _temaStore = GetIt.I.get<TemaStore>();

  UpdaterController controller = UpdaterController();

  @override
  void initState() {
    autorun((_) {
      carregarInformacoes();
    });

    super.initState();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> carregarInformacoes() async {
    await GetIt.instance.allReady();
    await _principalStore.setup();

    await _principalStore.usuario.carregarUsuario();

    if (_principalStore.temConexao && _principalStore.usuario.isLogado) {
      try {
        var responseMeusDados = await GetIt.I.get<ApiService>().auth.meusDados();

        if (responseMeusDados.isSuccessful) {
          var usuarioDados = responseMeusDados.body!;
          if (usuarioDados.nome != "") {
            if (kIsTablet && usuarioDados.tamanhoFonte < 16) {
              usuarioDados.tamanhoFonte = 16;
            }

            _principalStore.usuario.atualizarDados(
              nome: usuarioDados.nome,
              ano: usuarioDados.ano,
              tipoTurno: usuarioDados.tipoTurno,
              tamanhoFonte: usuarioDados.tamanhoFonte,
              familiaFonte: usuarioDados.familiaFonte,
              inicioTurno: usuarioDados.inicioTurno,
              fimTurno: usuarioDados.fimTurno,
              modalidade: usuarioDados.modalidade,
              dreAbreviacao: usuarioDados.dreAbreviacao,
              escola: usuarioDados.escola,
              turma: usuarioDados.turma,
              deficiencias: usuarioDados.deficiencias,
            );
          }
        }
      } catch (e) {
        await _principalStore.sair();
      }
    }

    _temaStore.fonteDoTexto = _principalStore.usuario.familiaFonte!;
    _temaStore.fachadaAlterarTamanhoDoTexto(_principalStore.usuario.tamanhoFonte!, update: false);

    try {
      if (kDebugMode || !(await checkUpdate())) {
        _navegar();
      }
    } catch (e) {
      _navegar();
    }

    await informarVersao();
  }

  _navegar() {
    if (_principalStore.usuario.isLogado) {
      if (_principalStore.usuario.isAdmin) {
        context.router.navigateNamed("/admin");
      } else {
        context.router.navigateNamed("/home");
      }
    } else {
      context.router.navigateNamed("/login");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          child: Lottie.asset('assets/images/students.json'),
        ),
      ),
    );
  }

  Future<bool> checkUpdate() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    int buildNumber = int.parse(packageInfo.buildNumber);

    info("Versão: ${packageInfo.version} Build: $buildNumber");

    bool isAvailable = await Updater(
      context: context,
      url: AppConfigReader.getApiHost() + "/v1/versoes/atualizacao",
      titleText: 'Atualização disponível!',
      confirmText: "Atualizar",
      backgroundDownload: false,
      allowSkip: false,
      callBack: (versionName, versionCode, contentText, minSupport, downloadUrl) {
        info("Ultima Versão: $versionName Build: $versionCode");
      },
      controller: controller,
    ).check();

    return isAvailable;
  }

  informarVersao() async {
    if (kIsWeb) {
      return;
    }

    try {
      PermissionStatus status = await Permission.contacts.status;

      if (!status.isGranted) {
        status = await Permission.phone.request();
      } else if (status.isPermanentlyDenied || status.isDenied) {
        await openAppSettings();
      }

      if (status.isGranted) {
        SharedPreferences prefs = ServiceLocator.get();
        PackageInfo packageInfo = await PackageInfo.fromPlatform();

        int buildNumber = prefs.getInt("_buildNumber") ?? 0;
        String version = prefs.getString("_version") ?? "1.0.0";

        if (buildNumber != int.parse(packageInfo.buildNumber) || version != packageInfo.version) {
          String? imei = await ImeiPlugin.getImei(shouldShowRequestPermissionRationale: false);

          info("Informando versão...");
          info("IMEI: $imei Versão: ${packageInfo.version} Build: ${packageInfo.buildNumber} ");

          await GetIt.I.get<ApiService>().versao.informarVersao(
                chaveAPI: AppConfigReader.getChaveApi(),
                versaoCodigo: int.parse(packageInfo.buildNumber),
                versaoDescricao: packageInfo.version,
                dispositivoImei: imei!,
                atualizadoEm: DateTime.now().toIso8601String(),
              );

          await prefs.setInt("_buildNumber", int.parse(packageInfo.buildNumber));
          await prefs.setString("_version", packageInfo.version);
        }
      }
    } on PlatformException catch (e) {
      severe("Erro ao informar versão: ${e.message}");
    }
  }
}
