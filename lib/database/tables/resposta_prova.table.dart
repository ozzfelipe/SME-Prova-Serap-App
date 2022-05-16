import 'package:appserap/models/resposta_prova.model.dart';
import 'package:drift/drift.dart';

@UseRowClass(RespostaProva)
class RespostaProvaTable extends Table {
  TextColumn get codigoEOL => text()();

  IntColumn get questaoId => integer()();
  IntColumn get provaId => integer()();

  IntColumn get alternativaId => integer().nullable()();
  TextColumn get resposta => text().nullable()();

  IntColumn get tempoRespostaAluno => integer().nullable()();
  DateTimeColumn get dataHoraResposta => dateTime().withDefault(currentDateAndTime).nullable()();

  BoolColumn get sincronizado => boolean()();

  @override
  Set<Column> get primaryKey => {codigoEOL, provaId, questaoId};
}
