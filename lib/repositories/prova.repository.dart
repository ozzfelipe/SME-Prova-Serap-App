import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';

import 'package:appserap/models/prova.model.dart';
import 'package:appserap/models/prova_alternativa.model.dart';
import 'package:appserap/models/prova_arquivo.model.dart';
import 'package:appserap/models/prova_detalhe.model.dart';
import 'package:appserap/models/prova_questao.model.dart';
import 'package:appserap/services/dio.service.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProvaRepository {
  final _api = GetIt.I.get<ApiService>();

  Future<List<ProvaModel>> obterProvas() async {
    try {
      final response = await _api.dio.get('/v1/provas');

      if (response.statusCode == 200) {
        var retorno =
            (response.data as List).map((x) => ProvaModel.fromJson(x)).toList();
        return retorno;
      }
      return new List<ProvaModel>.empty();
    } catch (e) {
      print(e);
      return new List<ProvaModel>.empty();
    }
  }

  Future<Uint8List> obterImagemPorId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    //await prefs.remove(id);
    var verificaImagemCache = prefs.getString(id);
    if (verificaImagemCache != null) {
      var imagemGuardada = base64Decode(verificaImagemCache);
      return imagemGuardada;
    }

    final ByteData imageData = await NetworkAssetBundle(Uri.parse(
            "https://serap.sme.prefeitura.sp.gov.br/Files/Texto_Base/2017/6/c4ea385b-d1d2-4659-a9dc-79a174b088a9.png"))
        .load("");
    var bytes = imageData.buffer.asUint8List();
    prefs.setString(id, base64Encode(bytes));
    return bytes;
  }

  Future<String> obterImagemPorUrl(String? url) async {
    if (url != null) {
      try {
        final ByteData imageData =
            await NetworkAssetBundle(Uri.parse(url)).load("");
        var bytes = imageData.buffer.asUint8List();
        return base64Encode(bytes);
      } catch (e) {
        print(e);
        return "";
      }
    }
    return "";
  }

  Future<ProvaDetalheModel?> obterProva(int id) async {
    try {
      final response = await _api.dio.get('/v1/provas/$id/detalhes-resumido');

      if (response.statusCode == 200) {
        var retorno = ProvaDetalheModel.fromJson(response.data);
        return retorno;
      }
      return null;
    } catch (e) {
      print(e);
      return null;
    }
  }

  Future<ProvaArquivoModel?> obterArquivo(int arquivoId) async {
    try {
      final response = await _api.dio.get('/v1/arquivos/$arquivoId/legado');
      if (response.statusCode == 200) {
        var retorno = ProvaArquivoModel.fromJson(response.data);
        return retorno;
      }
      return null;
    } catch (e) {
      print(e);
      return null;
    }
  }

  Future<ProvaQuestaoModel?> obterQuestao(int questaoId) async {
    try {
      final response = await _api.dio.get('/v1/questoes/$questaoId');
      if (response.statusCode == 200) {
        var retorno = ProvaQuestaoModel.fromJson(response.data);
        return retorno;
      }
      return null;
    } catch (e) {
      print(e);
      return null;
    }
  }

  Future<ProvaAlternativaModel?> obterAlternativa(int alternativaId) async {
    try {
      final response = await _api.dio.get('/v1/alternativas/$alternativaId');
      if (response.statusCode == 200) {
        var retorno = ProvaAlternativaModel.fromJson(response.data);
        return retorno;
      }
      return null;
    } catch (e) {
      print(e);
      return null;
    }
  }
}
