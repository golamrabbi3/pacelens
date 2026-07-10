// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $DeliveryResultsTable extends DeliveryResults
    with TableInfo<$DeliveryResultsTable, DeliveryResult> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DeliveryResultsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _videoUriMeta = const VerificationMeta(
    'videoUri',
  );
  @override
  late final GeneratedColumn<String> videoUri = GeneratedColumn<String>(
    'video_uri',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceFpsMeta = const VerificationMeta(
    'sourceFps',
  );
  @override
  late final GeneratedColumn<double> sourceFps = GeneratedColumn<double>(
    'source_fps',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _calibrationDistanceMetresMeta =
      const VerificationMeta('calibrationDistanceMetres');
  @override
  late final GeneratedColumn<double> calibrationDistanceMetres =
      GeneratedColumn<double>(
        'calibration_distance_metres',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _releaseSpeedKphMeta = const VerificationMeta(
    'releaseSpeedKph',
  );
  @override
  late final GeneratedColumn<double> releaseSpeedKph = GeneratedColumn<double>(
    'release_speed_kph',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _averageSpeedKphMeta = const VerificationMeta(
    'averageSpeedKph',
  );
  @override
  late final GeneratedColumn<double> averageSpeedKph = GeneratedColumn<double>(
    'average_speed_kph',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _confidenceMeta = const VerificationMeta(
    'confidence',
  );
  @override
  late final GeneratedColumn<String> confidence = GeneratedColumn<String>(
    'confidence',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _warningsJsonMeta = const VerificationMeta(
    'warningsJson',
  );
  @override
  late final GeneratedColumn<String> warningsJson = GeneratedColumn<String>(
    'warnings_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    videoUri,
    sourceFps,
    calibrationDistanceMetres,
    releaseSpeedKph,
    averageSpeedKph,
    confidence,
    warningsJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'delivery_results';
  @override
  VerificationContext validateIntegrity(
    Insertable<DeliveryResult> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('video_uri')) {
      context.handle(
        _videoUriMeta,
        videoUri.isAcceptableOrUnknown(data['video_uri']!, _videoUriMeta),
      );
    } else if (isInserting) {
      context.missing(_videoUriMeta);
    }
    if (data.containsKey('source_fps')) {
      context.handle(
        _sourceFpsMeta,
        sourceFps.isAcceptableOrUnknown(data['source_fps']!, _sourceFpsMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceFpsMeta);
    }
    if (data.containsKey('calibration_distance_metres')) {
      context.handle(
        _calibrationDistanceMetresMeta,
        calibrationDistanceMetres.isAcceptableOrUnknown(
          data['calibration_distance_metres']!,
          _calibrationDistanceMetresMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_calibrationDistanceMetresMeta);
    }
    if (data.containsKey('release_speed_kph')) {
      context.handle(
        _releaseSpeedKphMeta,
        releaseSpeedKph.isAcceptableOrUnknown(
          data['release_speed_kph']!,
          _releaseSpeedKphMeta,
        ),
      );
    }
    if (data.containsKey('average_speed_kph')) {
      context.handle(
        _averageSpeedKphMeta,
        averageSpeedKph.isAcceptableOrUnknown(
          data['average_speed_kph']!,
          _averageSpeedKphMeta,
        ),
      );
    }
    if (data.containsKey('confidence')) {
      context.handle(
        _confidenceMeta,
        confidence.isAcceptableOrUnknown(data['confidence']!, _confidenceMeta),
      );
    } else if (isInserting) {
      context.missing(_confidenceMeta);
    }
    if (data.containsKey('warnings_json')) {
      context.handle(
        _warningsJsonMeta,
        warningsJson.isAcceptableOrUnknown(
          data['warnings_json']!,
          _warningsJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_warningsJsonMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DeliveryResult map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DeliveryResult(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      videoUri: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}video_uri'],
      )!,
      sourceFps: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}source_fps'],
      )!,
      calibrationDistanceMetres: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}calibration_distance_metres'],
      )!,
      releaseSpeedKph: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}release_speed_kph'],
      ),
      averageSpeedKph: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}average_speed_kph'],
      ),
      confidence: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}confidence'],
      )!,
      warningsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}warnings_json'],
      )!,
    );
  }

  @override
  $DeliveryResultsTable createAlias(String alias) {
    return $DeliveryResultsTable(attachedDatabase, alias);
  }
}

class DeliveryResult extends DataClass implements Insertable<DeliveryResult> {
  final String id;
  final DateTime createdAt;
  final String videoUri;
  final double sourceFps;
  final double calibrationDistanceMetres;
  final double? releaseSpeedKph;
  final double? averageSpeedKph;
  final String confidence;
  final String warningsJson;
  const DeliveryResult({
    required this.id,
    required this.createdAt,
    required this.videoUri,
    required this.sourceFps,
    required this.calibrationDistanceMetres,
    this.releaseSpeedKph,
    this.averageSpeedKph,
    required this.confidence,
    required this.warningsJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['video_uri'] = Variable<String>(videoUri);
    map['source_fps'] = Variable<double>(sourceFps);
    map['calibration_distance_metres'] = Variable<double>(
      calibrationDistanceMetres,
    );
    if (!nullToAbsent || releaseSpeedKph != null) {
      map['release_speed_kph'] = Variable<double>(releaseSpeedKph);
    }
    if (!nullToAbsent || averageSpeedKph != null) {
      map['average_speed_kph'] = Variable<double>(averageSpeedKph);
    }
    map['confidence'] = Variable<String>(confidence);
    map['warnings_json'] = Variable<String>(warningsJson);
    return map;
  }

  DeliveryResultsCompanion toCompanion(bool nullToAbsent) {
    return DeliveryResultsCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      videoUri: Value(videoUri),
      sourceFps: Value(sourceFps),
      calibrationDistanceMetres: Value(calibrationDistanceMetres),
      releaseSpeedKph: releaseSpeedKph == null && nullToAbsent
          ? const Value.absent()
          : Value(releaseSpeedKph),
      averageSpeedKph: averageSpeedKph == null && nullToAbsent
          ? const Value.absent()
          : Value(averageSpeedKph),
      confidence: Value(confidence),
      warningsJson: Value(warningsJson),
    );
  }

  factory DeliveryResult.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DeliveryResult(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      videoUri: serializer.fromJson<String>(json['videoUri']),
      sourceFps: serializer.fromJson<double>(json['sourceFps']),
      calibrationDistanceMetres: serializer.fromJson<double>(
        json['calibrationDistanceMetres'],
      ),
      releaseSpeedKph: serializer.fromJson<double?>(json['releaseSpeedKph']),
      averageSpeedKph: serializer.fromJson<double?>(json['averageSpeedKph']),
      confidence: serializer.fromJson<String>(json['confidence']),
      warningsJson: serializer.fromJson<String>(json['warningsJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'videoUri': serializer.toJson<String>(videoUri),
      'sourceFps': serializer.toJson<double>(sourceFps),
      'calibrationDistanceMetres': serializer.toJson<double>(
        calibrationDistanceMetres,
      ),
      'releaseSpeedKph': serializer.toJson<double?>(releaseSpeedKph),
      'averageSpeedKph': serializer.toJson<double?>(averageSpeedKph),
      'confidence': serializer.toJson<String>(confidence),
      'warningsJson': serializer.toJson<String>(warningsJson),
    };
  }

  DeliveryResult copyWith({
    String? id,
    DateTime? createdAt,
    String? videoUri,
    double? sourceFps,
    double? calibrationDistanceMetres,
    Value<double?> releaseSpeedKph = const Value.absent(),
    Value<double?> averageSpeedKph = const Value.absent(),
    String? confidence,
    String? warningsJson,
  }) => DeliveryResult(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    videoUri: videoUri ?? this.videoUri,
    sourceFps: sourceFps ?? this.sourceFps,
    calibrationDistanceMetres:
        calibrationDistanceMetres ?? this.calibrationDistanceMetres,
    releaseSpeedKph: releaseSpeedKph.present
        ? releaseSpeedKph.value
        : this.releaseSpeedKph,
    averageSpeedKph: averageSpeedKph.present
        ? averageSpeedKph.value
        : this.averageSpeedKph,
    confidence: confidence ?? this.confidence,
    warningsJson: warningsJson ?? this.warningsJson,
  );
  DeliveryResult copyWithCompanion(DeliveryResultsCompanion data) {
    return DeliveryResult(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      videoUri: data.videoUri.present ? data.videoUri.value : this.videoUri,
      sourceFps: data.sourceFps.present ? data.sourceFps.value : this.sourceFps,
      calibrationDistanceMetres: data.calibrationDistanceMetres.present
          ? data.calibrationDistanceMetres.value
          : this.calibrationDistanceMetres,
      releaseSpeedKph: data.releaseSpeedKph.present
          ? data.releaseSpeedKph.value
          : this.releaseSpeedKph,
      averageSpeedKph: data.averageSpeedKph.present
          ? data.averageSpeedKph.value
          : this.averageSpeedKph,
      confidence: data.confidence.present
          ? data.confidence.value
          : this.confidence,
      warningsJson: data.warningsJson.present
          ? data.warningsJson.value
          : this.warningsJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DeliveryResult(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('videoUri: $videoUri, ')
          ..write('sourceFps: $sourceFps, ')
          ..write('calibrationDistanceMetres: $calibrationDistanceMetres, ')
          ..write('releaseSpeedKph: $releaseSpeedKph, ')
          ..write('averageSpeedKph: $averageSpeedKph, ')
          ..write('confidence: $confidence, ')
          ..write('warningsJson: $warningsJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    videoUri,
    sourceFps,
    calibrationDistanceMetres,
    releaseSpeedKph,
    averageSpeedKph,
    confidence,
    warningsJson,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DeliveryResult &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.videoUri == this.videoUri &&
          other.sourceFps == this.sourceFps &&
          other.calibrationDistanceMetres == this.calibrationDistanceMetres &&
          other.releaseSpeedKph == this.releaseSpeedKph &&
          other.averageSpeedKph == this.averageSpeedKph &&
          other.confidence == this.confidence &&
          other.warningsJson == this.warningsJson);
}

class DeliveryResultsCompanion extends UpdateCompanion<DeliveryResult> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<String> videoUri;
  final Value<double> sourceFps;
  final Value<double> calibrationDistanceMetres;
  final Value<double?> releaseSpeedKph;
  final Value<double?> averageSpeedKph;
  final Value<String> confidence;
  final Value<String> warningsJson;
  final Value<int> rowid;
  const DeliveryResultsCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.videoUri = const Value.absent(),
    this.sourceFps = const Value.absent(),
    this.calibrationDistanceMetres = const Value.absent(),
    this.releaseSpeedKph = const Value.absent(),
    this.averageSpeedKph = const Value.absent(),
    this.confidence = const Value.absent(),
    this.warningsJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DeliveryResultsCompanion.insert({
    required String id,
    required DateTime createdAt,
    required String videoUri,
    required double sourceFps,
    required double calibrationDistanceMetres,
    this.releaseSpeedKph = const Value.absent(),
    this.averageSpeedKph = const Value.absent(),
    required String confidence,
    required String warningsJson,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt),
       videoUri = Value(videoUri),
       sourceFps = Value(sourceFps),
       calibrationDistanceMetres = Value(calibrationDistanceMetres),
       confidence = Value(confidence),
       warningsJson = Value(warningsJson);
  static Insertable<DeliveryResult> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<String>? videoUri,
    Expression<double>? sourceFps,
    Expression<double>? calibrationDistanceMetres,
    Expression<double>? releaseSpeedKph,
    Expression<double>? averageSpeedKph,
    Expression<String>? confidence,
    Expression<String>? warningsJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (videoUri != null) 'video_uri': videoUri,
      if (sourceFps != null) 'source_fps': sourceFps,
      if (calibrationDistanceMetres != null)
        'calibration_distance_metres': calibrationDistanceMetres,
      if (releaseSpeedKph != null) 'release_speed_kph': releaseSpeedKph,
      if (averageSpeedKph != null) 'average_speed_kph': averageSpeedKph,
      if (confidence != null) 'confidence': confidence,
      if (warningsJson != null) 'warnings_json': warningsJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DeliveryResultsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<String>? videoUri,
    Value<double>? sourceFps,
    Value<double>? calibrationDistanceMetres,
    Value<double?>? releaseSpeedKph,
    Value<double?>? averageSpeedKph,
    Value<String>? confidence,
    Value<String>? warningsJson,
    Value<int>? rowid,
  }) {
    return DeliveryResultsCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      videoUri: videoUri ?? this.videoUri,
      sourceFps: sourceFps ?? this.sourceFps,
      calibrationDistanceMetres:
          calibrationDistanceMetres ?? this.calibrationDistanceMetres,
      releaseSpeedKph: releaseSpeedKph ?? this.releaseSpeedKph,
      averageSpeedKph: averageSpeedKph ?? this.averageSpeedKph,
      confidence: confidence ?? this.confidence,
      warningsJson: warningsJson ?? this.warningsJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (videoUri.present) {
      map['video_uri'] = Variable<String>(videoUri.value);
    }
    if (sourceFps.present) {
      map['source_fps'] = Variable<double>(sourceFps.value);
    }
    if (calibrationDistanceMetres.present) {
      map['calibration_distance_metres'] = Variable<double>(
        calibrationDistanceMetres.value,
      );
    }
    if (releaseSpeedKph.present) {
      map['release_speed_kph'] = Variable<double>(releaseSpeedKph.value);
    }
    if (averageSpeedKph.present) {
      map['average_speed_kph'] = Variable<double>(averageSpeedKph.value);
    }
    if (confidence.present) {
      map['confidence'] = Variable<String>(confidence.value);
    }
    if (warningsJson.present) {
      map['warnings_json'] = Variable<String>(warningsJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DeliveryResultsCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('videoUri: $videoUri, ')
          ..write('sourceFps: $sourceFps, ')
          ..write('calibrationDistanceMetres: $calibrationDistanceMetres, ')
          ..write('releaseSpeedKph: $releaseSpeedKph, ')
          ..write('averageSpeedKph: $averageSpeedKph, ')
          ..write('confidence: $confidence, ')
          ..write('warningsJson: $warningsJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $DeliveryResultsTable deliveryResults = $DeliveryResultsTable(
    this,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [deliveryResults];
}

typedef $$DeliveryResultsTableCreateCompanionBuilder =
    DeliveryResultsCompanion Function({
      required String id,
      required DateTime createdAt,
      required String videoUri,
      required double sourceFps,
      required double calibrationDistanceMetres,
      Value<double?> releaseSpeedKph,
      Value<double?> averageSpeedKph,
      required String confidence,
      required String warningsJson,
      Value<int> rowid,
    });
typedef $$DeliveryResultsTableUpdateCompanionBuilder =
    DeliveryResultsCompanion Function({
      Value<String> id,
      Value<DateTime> createdAt,
      Value<String> videoUri,
      Value<double> sourceFps,
      Value<double> calibrationDistanceMetres,
      Value<double?> releaseSpeedKph,
      Value<double?> averageSpeedKph,
      Value<String> confidence,
      Value<String> warningsJson,
      Value<int> rowid,
    });

class $$DeliveryResultsTableFilterComposer
    extends Composer<_$AppDatabase, $DeliveryResultsTable> {
  $$DeliveryResultsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get videoUri => $composableBuilder(
    column: $table.videoUri,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get sourceFps => $composableBuilder(
    column: $table.sourceFps,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get calibrationDistanceMetres => $composableBuilder(
    column: $table.calibrationDistanceMetres,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get releaseSpeedKph => $composableBuilder(
    column: $table.releaseSpeedKph,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get averageSpeedKph => $composableBuilder(
    column: $table.averageSpeedKph,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get warningsJson => $composableBuilder(
    column: $table.warningsJson,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DeliveryResultsTableOrderingComposer
    extends Composer<_$AppDatabase, $DeliveryResultsTable> {
  $$DeliveryResultsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get videoUri => $composableBuilder(
    column: $table.videoUri,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get sourceFps => $composableBuilder(
    column: $table.sourceFps,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get calibrationDistanceMetres => $composableBuilder(
    column: $table.calibrationDistanceMetres,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get releaseSpeedKph => $composableBuilder(
    column: $table.releaseSpeedKph,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get averageSpeedKph => $composableBuilder(
    column: $table.averageSpeedKph,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get warningsJson => $composableBuilder(
    column: $table.warningsJson,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DeliveryResultsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DeliveryResultsTable> {
  $$DeliveryResultsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get videoUri =>
      $composableBuilder(column: $table.videoUri, builder: (column) => column);

  GeneratedColumn<double> get sourceFps =>
      $composableBuilder(column: $table.sourceFps, builder: (column) => column);

  GeneratedColumn<double> get calibrationDistanceMetres => $composableBuilder(
    column: $table.calibrationDistanceMetres,
    builder: (column) => column,
  );

  GeneratedColumn<double> get releaseSpeedKph => $composableBuilder(
    column: $table.releaseSpeedKph,
    builder: (column) => column,
  );

  GeneratedColumn<double> get averageSpeedKph => $composableBuilder(
    column: $table.averageSpeedKph,
    builder: (column) => column,
  );

  GeneratedColumn<String> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => column,
  );

  GeneratedColumn<String> get warningsJson => $composableBuilder(
    column: $table.warningsJson,
    builder: (column) => column,
  );
}

class $$DeliveryResultsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DeliveryResultsTable,
          DeliveryResult,
          $$DeliveryResultsTableFilterComposer,
          $$DeliveryResultsTableOrderingComposer,
          $$DeliveryResultsTableAnnotationComposer,
          $$DeliveryResultsTableCreateCompanionBuilder,
          $$DeliveryResultsTableUpdateCompanionBuilder,
          (
            DeliveryResult,
            BaseReferences<
              _$AppDatabase,
              $DeliveryResultsTable,
              DeliveryResult
            >,
          ),
          DeliveryResult,
          PrefetchHooks Function()
        > {
  $$DeliveryResultsTableTableManager(
    _$AppDatabase db,
    $DeliveryResultsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DeliveryResultsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DeliveryResultsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DeliveryResultsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String> videoUri = const Value.absent(),
                Value<double> sourceFps = const Value.absent(),
                Value<double> calibrationDistanceMetres = const Value.absent(),
                Value<double?> releaseSpeedKph = const Value.absent(),
                Value<double?> averageSpeedKph = const Value.absent(),
                Value<String> confidence = const Value.absent(),
                Value<String> warningsJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DeliveryResultsCompanion(
                id: id,
                createdAt: createdAt,
                videoUri: videoUri,
                sourceFps: sourceFps,
                calibrationDistanceMetres: calibrationDistanceMetres,
                releaseSpeedKph: releaseSpeedKph,
                averageSpeedKph: averageSpeedKph,
                confidence: confidence,
                warningsJson: warningsJson,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required DateTime createdAt,
                required String videoUri,
                required double sourceFps,
                required double calibrationDistanceMetres,
                Value<double?> releaseSpeedKph = const Value.absent(),
                Value<double?> averageSpeedKph = const Value.absent(),
                required String confidence,
                required String warningsJson,
                Value<int> rowid = const Value.absent(),
              }) => DeliveryResultsCompanion.insert(
                id: id,
                createdAt: createdAt,
                videoUri: videoUri,
                sourceFps: sourceFps,
                calibrationDistanceMetres: calibrationDistanceMetres,
                releaseSpeedKph: releaseSpeedKph,
                averageSpeedKph: averageSpeedKph,
                confidence: confidence,
                warningsJson: warningsJson,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DeliveryResultsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DeliveryResultsTable,
      DeliveryResult,
      $$DeliveryResultsTableFilterComposer,
      $$DeliveryResultsTableOrderingComposer,
      $$DeliveryResultsTableAnnotationComposer,
      $$DeliveryResultsTableCreateCompanionBuilder,
      $$DeliveryResultsTableUpdateCompanionBuilder,
      (
        DeliveryResult,
        BaseReferences<_$AppDatabase, $DeliveryResultsTable, DeliveryResult>,
      ),
      DeliveryResult,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$DeliveryResultsTableTableManager get deliveryResults =>
      $$DeliveryResultsTableTableManager(_db, _db.deliveryResults);
}
