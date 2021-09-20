import 'package:appserap/dtos/arquivo.response.dto.dart';
import 'package:chopper/chopper.dart';

part 'arquivo.service.chopper.dart';

@ChopperApi(baseUrl: "/arquivos")
abstract class ArquivoService extends ChopperService {
  static ArquivoService create([ChopperClient? client]) => _$ArquivoService(client);

  @Get(path: '{idArquivo}/legado')
  Future<Response<ArquivoResponseDTO>> getArquivo({@Path() required int idArquivo});
}
