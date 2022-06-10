import 'package:appserap/database/app.database.dart';
import 'package:appserap/database/tables/alternativa.table.dart';
import 'package:drift/drift.dart';

part 'alternativa.dao.g.dart';

@DriftAccessor(tables: [AlternativasDb])
class AlternativaDao extends DatabaseAccessor<AppDatabase> with _$AlternativaDaoMixin {
  AlternativaDao(AppDatabase db) : super(db);

  Future inserir(AlternativaDb entity) {
    return into(alternativasDb).insert(entity);
  }

  Future inserirOuAtualizar(AlternativaDb entity) {
    return into(alternativasDb).insertOnConflictUpdate(entity);
  }

  Future remover(AlternativaDb entity) {
    return delete(alternativasDb).delete(entity);
  }

  Future<List<AlternativaDb>> obterPorProvaId(int provaId) {
    return (select(alternativasDb)..where((t) => t.provaId.equals(provaId))).get();
  }

  Future<List<AlternativaDb>> obterPorQuestaoId(int questaoId) {
    return (select(alternativasDb)..where((t) => t.questaoId.equals(questaoId))).get();
  }

  Future<List<AlternativaDb>> listarTodos() {
    return select(alternativasDb).get();
  }

  Future<List<AlternativaDb>> obterAlternativasPorProvaId(int provaId) {
    return (select(alternativasDb)..where((t) => t.provaId.equals(provaId))).get();
  }

  Future removerAlternativasPorProvaId(int id) {
    return transaction(() async {
      await customUpdate("delete from alternativas_db where prova_id = ?", variables: [Variable.withInt(id)]);
    });
  }
}
