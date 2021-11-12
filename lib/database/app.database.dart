import 'package:appserap/enums/prova_status.enum.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

export 'core/shared.database.dart';

part 'app.database.g.dart';

@DataClassName("ProvaDb")
class ProvasDb extends Table {
  IntColumn get id => integer()();
  TextColumn get descricao => text().withLength(min: 1, max: 50)();
  DateTimeColumn get ultimaAtualizacao => dateTime().nullable()();
  IntColumn get downloadStatus => integer()();
  IntColumn get itensQuantidade => integer()();
  IntColumn get tempoAlerta => integer().nullable()();
  IntColumn get tempoExecucao => integer()();
  IntColumn get tempoExtra => integer()();
  IntColumn get status => integer()();
  DateTimeColumn get dataInicio => dateTime()();
  DateTimeColumn get dataFim => dateTime().nullable()();
  DateTimeColumn get dataInicioProvaAluno => dateTime().nullable()();
  DateTimeColumn get dataFimProvaAluno => dateTime().nullable()();

  TextColumn get senha => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName("QuestaoDb")
class QuestoesDb extends Table {
  IntColumn get id => integer()();
  TextColumn get titulo => text()();
  TextColumn get descricao => text()();
  IntColumn get ordem => integer()();
  IntColumn get tipo => integer()();
  DateTimeColumn get ultimaAtualizacao => dateTime().nullable()();
  IntColumn get provaId => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName("ContextoProvaDb")
class ContextosProvaDb extends Table {
  IntColumn get id => integer()();
  TextColumn get titulo => text().nullable()();
  TextColumn get texto => text().nullable()();
  TextColumn get imagemBase64 => text().nullable()();
  IntColumn get ordem => integer()();
  TextColumn get imagem => text().nullable()();
  IntColumn get posicionamento => integer().nullable()();
  IntColumn get provaId => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName("AlternativaDb")
class AlternativasDb extends Table {
  IntColumn get id => integer()();
  TextColumn get descricao => text()();
  IntColumn get ordem => integer()();
  TextColumn get numeracao => text()();
  DateTimeColumn get ultimaAtualizacao => dateTime().nullable()();
  IntColumn get provaId => integer()();
  IntColumn get questaoId => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName("ArquivoDb")
class ArquivosDb extends Table {
  IntColumn get id => integer()();
  TextColumn get caminho => text()();
  TextColumn get base64 => text()();
  DateTimeColumn get ultimaAtualizacao => dateTime().nullable()();
  IntColumn get provaId => integer()();
  IntColumn get questaoId => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [ProvasDb, QuestoesDb, AlternativasDb, ArquivosDb, ContextosProvaDb])
class AppDatabase extends _$AppDatabase {
  AppDatabase(QueryExecutor e) : super(e);

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(onCreate: (Migrator m) {
        return m.createAll();
      }, onUpgrade: (Migrator m, int from, int to) async {
        if (from == 2) {
          await m.addColumn(provasDb, provasDb.senha);
        }

        if (from == 3) {
          await m.createTable(contextosProvaDb);
        }
      }, beforeOpen: (openingDetails) async {
        if (kDebugMode /* or some other flag */) {
          final m = createMigrator();
          for (final table in allTables) {
            await m.deleteTable(table.actualTableName);
            await m.createTable(table);
          }
        }
      });

  Future limpar() {
    return transaction(() async {
      await customUpdate(
        "delete from alternativas_db; delete from questoes_db; delete from arquivos_db; delete from provas_db;",
      );
    });
  }

  Future limparPorProvaId(int provaId) {
    return transaction(() async {
      await customUpdate("""delete from alternativas_db where prova_id = ?; 
        delete from questoes_db where prova_id = ?; 
        delete from arquivos_db where prova_id = ?; 
        delete from provas_db where prova_id = ?; """, variables: [
        Variable.withInt(provaId),
      ]);
    });
  }

  //Provas
  Future inserirProva(ProvaDb provaDb) => into(provasDb).insert(provaDb);
  Future inserirOuAtualizarProva(ProvaDb provaDb) => into(provasDb).insertOnConflictUpdate(provaDb);
  Future removerProva(ProvaDb provaDb) => delete(provasDb).delete(provaDb);
  Future<ProvaDb?> obterProvaPorIdNull(int id) => (select(provasDb)..where((t) => t.id.equals(id))).getSingleOrNull();
  Future<ProvaDb> obterProvaPorId(int id) => (select(provasDb)..where((t) => t.id.equals(id))).getSingle();
  Future<List<ProvaDb>> obterProvas() => (select(provasDb)).get();

  Future<List<ProvaDb>> obterProvasPendentes() => (select(provasDb)
        ..where(
          (t) => t.status.equals(EnumProvaStatus.PENDENTE.index),
        ))
      .get();

  //Questoes
  Future inserirQuestao(QuestaoDb questaoDb) => into(questoesDb).insert(questaoDb);
  Future inserirOuAtualizarQuestao(QuestaoDb questaoDb) => into(questoesDb).insertOnConflictUpdate(questaoDb);
  Future removerQuestao(QuestaoDb questaoDb) => delete(questoesDb).delete(questaoDb);
  Selectable<QuestaoDb> obterQuestaoPorArquivoLegadoId(int arquivoLegadoId, int provaId) {
    return customSelect(
        'select * from questoes_db where (titulo like \'%$arquivoLegadoId%\'\n or descricao like \'%$arquivoLegadoId%\') and prova_id = $provaId',
        readsFrom: {
          questoesDb,
        }).map(questoesDb.mapFromRow);
  }

  Future<List<QuestaoDb>> obterQuestoesPorProvaId(int provaId) => (select(questoesDb)
        ..where((t) => t.provaId.equals(provaId))
        ..orderBy([(t) => OrderingTerm(expression: t.ordem)]))
      .get();
  Future removerQuestoesPorProvaId(int id) {
    return transaction(() async {
      await customUpdate("delete from questoes_db where prova_id = ?", variables: [Variable.withInt(id)]);
    });
  }

  //Alternativas
  Future inserirAlternativa(AlternativaDb alternativaDb) => into(alternativasDb).insert(alternativaDb);
  Future inserirOuAtualizarAlternativa(AlternativaDb alternativaDb) =>
      into(alternativasDb).insertOnConflictUpdate(alternativaDb);
  Future removerAlternativa(AlternativaDb alternativaDb) => delete(alternativasDb).delete(alternativaDb);
  Future<List<AlternativaDb>> obterAlternativasPorQuestaoId(int questaoId) =>
      (select(alternativasDb)..where((t) => t.questaoId.equals(questaoId))).get();
  Future<List<AlternativaDb>> obterAlternativasPorProvaId(int provaId) =>
      (select(alternativasDb)..where((t) => t.provaId.equals(provaId))).get();
  Future removerAlternativasPorProvaId(int id) {
    return transaction(() async {
      await customUpdate("delete from alternativas_db where prova_id = ?", variables: [Variable.withInt(id)]);
    });
  }

  //Arquivos
  Future inserirArquivo(ArquivoDb arquivoDb) => into(arquivosDb).insert(arquivoDb);
  Future inserirOuAtualizarArquivo(ArquivoDb arquivoDb) => into(arquivosDb).insertOnConflictUpdate(arquivoDb);
  Future removerArquivo(ArquivoDb arquivoDb) => delete(arquivosDb).delete(arquivoDb);
  Future<List<ArquivoDb>> obterArquivosPorQuestaoId(int questaoId) =>
      (select(arquivosDb)..where((t) => t.questaoId.equals(questaoId))).get();
  Future<List<ArquivoDb>> obterArquivosPorProvaId(int provaId) =>
      (select(arquivosDb)..where((t) => t.provaId.equals(provaId))).get();
  Future removerArquivosPorProvaId(int id) {
    return transaction(() async {
      await customUpdate("delete from arquivos_db where prova_id = ?", variables: [Variable.withInt(id)]);
    });
  }

  //Contexto Prova
  Future inserirContextoProva(ContextoProvaDb contextoProvaDb) => into(contextosProvaDb).insert(contextoProvaDb);
  Future inserirOuAtualizarContextoProva(ContextoProvaDb contextoProvaDb) =>
      into(contextosProvaDb).insertOnConflictUpdate(contextoProvaDb);
  Future removerContexto(ContextoProvaDb contextoProvaDb) => delete(contextosProvaDb).delete(contextoProvaDb);
  Future<List<ContextoProvaDb>> obterContextoPorProvaId(int provaId) =>
      (select(contextosProvaDb)..where((t) => t.provaId.equals(provaId))).get();
  Future removerContextoPorProvaId(int id) {
    return transaction(() async {
      await customUpdate("delete from arquivos_db where prova_id = ?", variables: [Variable.withInt(id)]);
    });
  }
}
