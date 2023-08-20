import 'package:appserap/dtos/prova.response.dto.dart';
import 'package:appserap/dtos/prova_anterior.response.dto.dart';
import 'package:appserap/dtos/prova_detalhes.response.dto.dart';
import 'package:appserap/dtos/prova_detalhes_caderno.response.dto.dart';
import 'package:appserap/dtos/questao_resposta.response.dto.dart';
import 'package:chopper/chopper.dart';
import 'package:injectable/injectable.dart';

part 'prova.service.chopper.dart';

@injectable
@ChopperApi(baseUrl: "/v1/provas")
abstract class ProvaService extends ChopperService {

  @factoryMethod
  static ProvaService create(ChopperClient client) => _$ProvaService(client);

  @Get()
  Future<Response<List<ProvaResponseDTO>>> getProvas();

  @Get(path: '{idProva}/detalhes-resumido')
  Future<Response<ProvaDetalhesResponseDTO>> getResumoProva({
    @Path() required int idProva,
  });

  @Get(path: '{idProva}/detalhes-resumido-caderno/{caderno}')
  Future<Response<ProvaDetalhesCadernoResponseDTO>> getResumoProvaCaderno({
    @Path() required int idProva,
    @Path() required String caderno,
  });

  @Get(path: '{idProva}/status-aluno')
  Future<Response<int>> getStatusProva({
    @Path() required int idProva,
  });

  @Post(path: '{idProva}/status-aluno')
  Future<Response<bool>> setStatusProva({
    @Path() required int idProva,
    @Field() required int status,
    @Field() required int tipoDispositivo,
    @Field() int? dataInicio,
    @Field() int? dataFim,
  });

  @Get(path: '{idProva}/respostas')
  Future<Response<List<QuestaoRespostaResponseDTO>>> getRespostasPorProvaId({@Path() required int idProva});

  @Get(path: 'finalizadas')
  Future<Response<List<ProvaAnteriorResponseDTO>>> getProvasAnteriores();
}
