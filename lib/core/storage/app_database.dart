import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../../domain/entities/delivery_result_record.dart';
import '../../domain/entities/speed_analysis_result.dart';

part 'app_database.g.dart';

class DeliveryResults extends Table {
  TextColumn get id => text()();
  DateTimeColumn get createdAt => dateTime()();
  TextColumn get videoUri => text()();
  RealColumn get sourceFps => real()();
  RealColumn get calibrationDistanceMetres => real()();
  RealColumn get releaseSpeedKph => real().nullable()();
  RealColumn get averageSpeedKph => real().nullable()();
  TextColumn get confidence => text()();
  TextColumn get warningsJson => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DriftDatabase(tables: [DeliveryResults])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'pacelens'));

  @override
  int get schemaVersion => 1;

  Future<void> saveResult(DeliveryResultRecord record) {
    return into(deliveryResults).insertOnConflictUpdate(
      DeliveryResultsCompanion.insert(
        id: record.id,
        createdAt: record.createdAt,
        videoUri: record.videoUri.toString(),
        sourceFps: record.sourceFps,
        calibrationDistanceMetres: record.calibrationDistanceMetres,
        releaseSpeedKph: Value(record.releaseSpeedKph),
        averageSpeedKph: Value(record.averageSpeedKph),
        confidence: record.confidence.name,
        warningsJson: jsonEncode(record.warnings),
      ),
    );
  }

  Stream<List<DeliveryResultRecord>> watchResults() {
    final query = select(deliveryResults)
      ..orderBy([(row) => OrderingTerm.desc(row.createdAt)]);
    return query.watch().map((rows) => rows.map(_toRecord).toList());
  }

  Future<List<DeliveryResultRecord>> allResults() async {
    final query = select(deliveryResults)
      ..orderBy([(row) => OrderingTerm.desc(row.createdAt)]);
    return (await query.get()).map(_toRecord).toList();
  }

  DeliveryResultRecord _toRecord(DeliveryResult row) {
    return DeliveryResultRecord(
      id: row.id,
      createdAt: row.createdAt,
      videoUri: Uri.parse(row.videoUri),
      sourceFps: row.sourceFps,
      calibrationDistanceMetres: row.calibrationDistanceMetres,
      releaseSpeedKph: row.releaseSpeedKph,
      averageSpeedKph: row.averageSpeedKph,
      confidence: AnalysisConfidence.values.firstWhere(
        (confidence) => confidence.name == row.confidence,
        orElse: () => AnalysisConfidence.failed,
      ),
      warnings: (jsonDecode(row.warningsJson) as List<dynamic>).cast<String>(),
    );
  }
}
