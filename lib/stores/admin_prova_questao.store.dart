import 'dart:convert';

import 'package:appserap/dtos/admin_prova_resumo.response.dto.dart';
import 'package:appserap/dtos/admin_questao_detalhes.response.dto.dart';
import 'package:appserap/dtos/alternativa.response.dto.dart';
import 'package:appserap/dtos/arquivo.response.dto.dart';
import 'package:appserap/dtos/arquivo_video.response.dto.dart';
import 'package:appserap/dtos/questao.response.dto.dart';
import 'package:appserap/interfaces/loggable.interface.dart';
import 'package:appserap/main.ioc.dart';
import 'package:appserap/services/api.dart';
// import 'package:injectable/injectable.dart';
import 'package:mobx/mobx.dart';
import 'package:retry/retry.dart';
import 'package:shared_preferences/shared_preferences.dart';
part 'admin_prova_questao.store.g.dart';

// @Injectable()
class AdminProvaQuestaoViewStore = _AdminProvaQuestaoViewStoreBase with _$AdminProvaQuestaoViewStore;

abstract class _AdminProvaQuestaoViewStoreBase with Store, Loggable {
  @observable
  bool carregando = false;

  @observable
  int totalQuestoes = 0;

  @observable
  AdminQuestaoDetalhesResponseDTO? detalhes;

  @observable
  QuestaoResponseDTO? questao;

  List<AlternativaResponseDTO> alternativas = [];

  List<ArquivoResponseDTO> imagens = [];

  List<ArquivoResponseDTO> audios = [];

  List<ArquivoVideoResponseDTO> videos = [];

  @action
  Future<void> carregarDetalhesQuestao({required int idProva, String? nomeCaderno, required int ordem}) async {
    carregando = true;
    await retry(
      () async {
        var prefs = sl<SharedPreferences>();

        totalQuestoes = calcularTotalQuestoes(prefs, idProva, nomeCaderno);

        String key = 'a-$idProva-$nomeCaderno-$ordem';

        var resumoQuestao = AdminProvaResumoResponseDTO.fromJson(jsonDecode(prefs.getString(key)!));

        var res = await sl<AdminService>().getDetalhes(idProva: idProva, idQuestao: resumoQuestao.id);

        if (res.isSuccessful) {
          detalhes = res.body!;
          await carregarDetalhes();
        } else {
          fine("Erro ao carregar detalhes da questão: ${res.error}");
        }
      },
      onRetry: (e) {
        fine('[Prova $idProva] - Tentativa de carregamento detalhes da questão $ordem da prova - ${e.toString()}');
      },
    );
    carregando = false;
  }

  int calcularTotalQuestoes(SharedPreferences prefs, int idProva, String? nomeCaderno) {
    int total = 0;
    prefs.getKeys().forEach((element) {
      if (element.startsWith('a-$idProva-$nomeCaderno-')) {
        total++;
      }
    });
    return total;
  }

  @action
  limpar() {
    questao = null;
    alternativas = [];
    imagens = [];
    audios = [];
    videos = [];
  }

  @action
  carregarDetalhes() async {
    limpar();

    fine("Carregando ${detalhes!.alternativasId.length} alternativas");
    for (var id in detalhes!.alternativasId) {
      var res = await sl<AlternativaService>().getAlternativa(idAlternativa: id);
      if (res.isSuccessful) {
        alternativas.add(res.body!);
      }
    }

    fine("Carregando ${detalhes!.arquivosId.length} imagens");
    for (var id in detalhes!.arquivosId) {
      var res = await sl<ArquivoService>().getArquivo(idArquivo: id);
      if (res.isSuccessful) {
        imagens.add(res.body!);
      }
    }

    fine("Carregando ${detalhes!.audiosId.length} audios");
    for (var id in detalhes!.audiosId) {
      var res = await sl<ArquivoService>().getAudio(idArquivo: id);
      if (res.isSuccessful) {
        audios.add(res.body!);
      }
    }

    fine("Carregando ${detalhes!.videosId.length} videos");
    for (var id in detalhes!.videosId) {
      var res = await sl<ArquivoService>().getVideo(idArquivo: id);
      if (res.isSuccessful) {
        videos.add(res.body!);
      }
    }

    var res = await sl<QuestaoService>().getQuestao(idQuestao: detalhes!.questaoId);
    if (res.isSuccessful) {
      questao = res.body!;
    }
  }
}
